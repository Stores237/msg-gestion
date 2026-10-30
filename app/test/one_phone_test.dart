import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:msg_gestion/data/api_client.dart';
import 'package:msg_gestion/data/auth_session.dart';
import 'package:msg_gestion/data/offline.dart';
import 'package:msg_gestion/data/repository_locator.dart';
import 'package:msg_gestion/data/token_storage.dart';
import 'package:msg_gestion/screens/login_phone_screen.dart';

import 'fakes.dart';
import 'helpers.dart';

/// One phone at a time (owner, 2026-10-30): when the account is opened on
/// another phone, this one is signed out and says why.
void main() {
  const otherDevice =
      '{"code":"other_device","detail":"Votre compte a été ouvert sur un autre téléphone"}';

  test('the server ending the session is remembered as other_device', () async {
    final client = MockClient(
      (req) async => http.Response.bytes(utf8.encode(otherDevice), 401),
    );
    final session = AuthSession(storage: InMemoryTokenStorage());
    await session.store(access: 'a1', refresh: 'r1');
    final api = ApiClient(
      authSession: session,
      httpClient: client,
      baseUrl: 'http://x/api',
    );
    await expectLater(api.get('/me/'), throwsA(isA<ApiException>()));
    expect(session.isLoggedIn, isFalse);
    expect(session.endedBy, 'other_device');
    // Signing in again starts afresh.
    await session.store(access: 'a2', refresh: 'r2');
    expect(session.endedBy, isNull);
  });

  test(
    'an ordinary expired session is not reported as another phone',
    () async {
      final client = MockClient(
        (req) async => http.Response('{"code":"token_not_valid"}', 401),
      );
      final session = AuthSession(storage: InMemoryTokenStorage());
      await session.store(access: 'a1', refresh: 'r1');
      final api = ApiClient(
        authSession: session,
        httpClient: client,
        baseUrl: 'http://x/api',
      );
      await expectLater(api.get('/me/'), throwsA(isA<ApiException>()));
      expect(session.endedBy, isNull);
    },
  );

  testWidgets('the app leaves for the login screen, erases, and says why', (
    tester,
  ) async {
    await setUpApp(tester);
    final session = RepositoryLocator.instance.authSession;
    await session.store(access: 'a1', refresh: 'r1');
    await OfflineState.instance.remember('/announcements/', {'x': 1});
    await pumpShell(tester, fakeMe());

    session.endedBy = 'other_device';
    await session.clear();
    await tester.pumpAndSettle();

    expect(find.byType(LoginPhoneScreen), findsOneWidget);
    expect(find.byKey(const Key('signed-out-notice')), findsOneWidget);
    expect(
      find.textContaining('ouvert sur un autre téléphone'),
      findsOneWidget,
    );
    expect(OfflineState.instance.has('/announcements/'), isFalse);
    expect(jsonEncode(OfflineState.instance.outbox), '[]');
  });
}
