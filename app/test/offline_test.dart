import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:msg_gestion/data/api_client.dart';
import 'package:msg_gestion/data/auth_session.dart';
import 'package:msg_gestion/data/offline.dart';
import 'package:msg_gestion/data/repositories/http/http_finances_repository.dart';
import 'package:msg_gestion/data/repository_locator.dart';
import 'package:msg_gestion/data/token_storage.dart';
import 'package:msg_gestion/main.dart';
import 'package:msg_gestion/models/finance.dart';
import 'package:msg_gestion/screens/shell_screen.dart';

import 'fakes.dart';
import 'helpers.dart';

http.Response _json(Object body, int status) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// A server that can be switched off, recording what it received.
class FlakyServer {
  bool up = true;
  final received = <String>[];
  final entries = <Map<String, dynamic>>[];

  late final client = MockClient((req) async {
    if (!up) throw http.ClientException('no network');
    received.add('${req.method} ${req.url.path}');
    final path = req.url.path;
    if (path.endsWith('/finances/entries/') && req.method == 'POST') {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final existing = entries.where(
        (e) => e['client_uuid'] == body['client_uuid'],
      );
      if (existing.isNotEmpty) {
        return _json((existing.first), 200);
      }
      final e = {
        ...body,
        'id': entries.length + 1,
        'status': 'pending',
        'created_by_name': 'Fotso I.',
        'created_at': DateTime.now().toIso8601String(),
        'validated_by_name': null,
        'validated_at': null,
        'member_name': null,
      };
      entries.add(e);
      return _json((e), 201);
    }
    if (path.endsWith('/finances/entries/')) {
      return _json((entries), 200);
    }
    if (path.endsWith('/finances/summary/')) {
      return http.Response(
        jsonEncode({
          'balance': 0,
          'balance_with_pending': 0,
          'pending': entries.length,
          'validated_until': null,
        }),
        200,
      );
    }
    if (path.endsWith('/bad/')) return _json({'detail': 'non'}, 400);
    return _json({}, 200);
  });
}

void main() {
  late FlakyServer server;
  late ApiClient api;

  setUp(() {
    server = FlakyServer();
    OfflineState.debugSetInstance(
      OfflineState(storage: MemoryOfflineStorage()),
    );
    api = ApiClient(
      authSession: AuthSession(storage: InMemoryTokenStorage()),
      httpClient: server.client,
      baseUrl: 'http://x/api',
    );
  });

  test('reads fall back to the last answer when offline', () async {
    await api.get('/finances/summary/');
    server.up = false;
    final cached = await api.get('/finances/summary/') as Map<String, dynamic>;
    expect(cached['balance'], 0);
    expect(OfflineState.instance.online, isFalse);
    await expectLater(
      api.get('/never/seen/'),
      throwsA(isA<NetworkException>()),
    );
  });

  test('offline entry is queued, shown locally, sent once when back', () async {
    final repo = HttpFinancesRepository(api);
    server.up = false;
    final entry = NewEntry(
      direction: 'in',
      amount: 2500,
      category: 'solidarite',
      label: 'Décès',
      date: DateTime(2026, 10, 20),
    );
    final local = await repo.createEntry(entry);
    expect(local.local, isTrue);
    expect(OfflineState.instance.pending, 1);
    // The cash book (cached empty earlier? no: nothing cached) — once online:
    server.up = true;
    await api.flushOutbox();
    expect(OfflineState.instance.pending, 0);
    expect(server.entries.single['client_uuid'], entry.clientUuid);
    // A retried send of the same entry is not recorded twice.
    await repo.createEntry(entry);
    expect(server.entries, hasLength(1));
  });

  test('the outbox survives a restart', () async {
    final storage = MemoryOfflineStorage();
    OfflineState.debugSetInstance(OfflineState(storage: storage));
    server.up = false;
    await expectLater(
      api.sendOrQueue(
        'POST',
        '/events/3/excuse/',
        body: {'reason': 'x'},
        kind: 'excuse',
      ),
      throwsA(isA<QueuedOffline>()),
    );
    final reborn = OfflineState(storage: storage);
    await reborn.load();
    expect(reborn.pending, 1);
    expect(reborn.outbox.single.path, '/events/3/excuse/');
  });

  test(
    'a refused queued write is dropped and reported, the rest continues',
    () async {
      server.up = false;
      await expectLater(
        api.sendOrQueue('POST', '/bad/', kind: 'read'),
        throwsA(isA<QueuedOffline>()),
      );
      await expectLater(
        api.sendOrQueue('POST', '/events/3/excuse/', kind: 'excuse'),
        throwsA(isA<QueuedOffline>()),
      );
      server.up = true;
      await api.flushOutbox();
      expect(OfflineState.instance.pending, 0);
      expect(OfflineState.instance.lastError, isNotNull);
      expect(server.received, ['POST /api/bad/', 'POST /api/events/3/excuse/']);
    },
  );

  testWidgets(
    'offline: banner with pending count and "Pas encore envoyé" row',
    (tester) async {
      await setUpApp(tester);
      final offline = OfflineState(storage: MemoryOfflineStorage());
      OfflineState.debugSetInstance(offline);
      final session = AuthSession(storage: InMemoryTokenStorage());
      final client = ApiClient(
        authSession: session,
        httpClient: server.client,
        baseUrl: 'http://x/api',
      );
      final f = Fakes();
      RepositoryLocator.debugSetInstance(
        RepositoryLocator(
          authSession: session,
          apiClient: client,
          auth: f.auth,
          members: f.members,
          events: f.events,
          announcements: f.announcements,
          planning: f.planning,
          notifications: f.notifications,
        ),
      );
      // Seen once online, so the screen has something to show offline.
      await client.get('/finances/entries/');
      await client.get('/finances/summary/');
      server.up = false;
      await RepositoryLocator.instance.finances.createEntry(
        NewEntry(
          direction: 'in',
          amount: 500,
          category: 'amende',
          label: 'Retard',
          date: DateTime(2026, 10, 20),
        ),
      );
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MsgApp(
          home: ShellScreen(
            me: fakeMe(
              tabs: const ['accueil', 'finances'],
              permissions: const {
                'finances.cashbook': ['view', 'create'],
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab-finances')));
      await tester.pumpAndSettle();
      expect(
        find.text('Hors ligne · 1 saisie en attente d’envoi'),
        findsOneWidget,
      );
      expect(find.text('Pas encore envoyé'), findsOneWidget);
      expect(
        find.textContaining('Hors ligne · dernière synchronisation'),
        findsOneWidget,
      );
    },
  );
}
