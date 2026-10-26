import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:msg_gestion/data/api_client.dart';
import 'package:msg_gestion/data/auth_session.dart';
import 'package:msg_gestion/data/repositories/auth_repository.dart';
import 'package:msg_gestion/data/repositories/http/http_auth_repository.dart';
import 'package:msg_gestion/data/token_storage.dart';
import 'package:msg_gestion/models/me.dart';

HttpAuthRepository repoReturning(
  int status,
  Map<String, dynamic> body, {
  AuthSession? session,
}) {
  final client = MockClient(
    (req) async => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    ),
  );
  return HttpAuthRepository(
    ApiClient(
      authSession: session ?? AuthSession(storage: InMemoryTokenStorage()),
      httpClient: client,
      baseUrl: 'http://x/api',
    ),
  );
}

void main() {
  test(
    '401 becomes WrongPin with the server message and attempts left',
    () async {
      final repo = repoReturning(401, {
        'detail': 'Code incorrect. Il vous reste 2 essais.',
        'attempts_left': 2,
      });
      await expectLater(
        repo.loginWithPin(phone: '677452108', pin: '0000', acceptedTerms: 1),
        throwsA(
          isA<WrongPin>().having((e) => e.attemptsLeft, 'attemptsLeft', 2),
        ),
      );
    },
  );

  test('423 becomes AccountLocked, 404 UnknownMember, 409 NoPinSet', () async {
    await expectLater(
      repoReturning(423, {
        'detail': 'bloqué',
        'code': 'locked',
        'minutes': 12,
      }).loginWithPin(phone: 'x', pin: '1', acceptedTerms: 1),
      throwsA(isA<AccountLocked>().having((e) => e.minutes, 'minutes', 12)),
    );
    await expectLater(
      repoReturning(404, {
        'detail': 'inconnu',
      }).loginWithPin(phone: 'x', pin: '1', acceptedTerms: 1),
      throwsA(isA<UnknownMember>()),
    );
    await expectLater(
      repoReturning(409, {
        'detail': 'pas de PIN',
      }).loginWithPin(phone: 'x', pin: '1', acceptedTerms: 1),
      throwsA(isA<NoPinSet>()),
    );
  });

  test('403 backoffice_only becomes BackofficeOnly (super admin)', () async {
    await expectLater(
      repoReturning(403, {
        'detail': 'back-office',
        'code': 'backoffice_only',
      }).loginWithPin(phone: 'x', pin: '1', acceptedTerms: 1),
      throwsA(isA<BackofficeOnly>()),
    );
  });

  test('428 becomes TermsRequired; the box and its version are sent', () async {
    await expectLater(
      repoReturning(428, {
        'detail': 'conditions',
        'code': 'terms_required',
        'terms_version': 2,
      }).loginWithPin(phone: 'x', pin: '1', acceptedTerms: 1),
      throwsA(isA<TermsRequired>()),
    );
    Map<String, dynamic>? sent;
    final repo = HttpAuthRepository(
      ApiClient(
        authSession: AuthSession(storage: InMemoryTokenStorage()),
        baseUrl: 'http://x/api',
        httpClient: MockClient((req) async {
          sent = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({'access': 'a', 'refresh': 'r'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );
    await repo.loginWithPin(phone: 'x', pin: '1234', acceptedTerms: 3);
    expect(sent?['accept_terms'], true);
    expect(sent?['terms_version'], 3);
  });

  test('success stores both tokens', () async {
    final session = AuthSession(storage: InMemoryTokenStorage());
    await repoReturning(
      200,
      {'access': 'a', 'refresh': 'r'},
      session: session,
    ).loginWithPin(phone: 'x', pin: '1234', acceptedTerms: 1);
    expect(session.accessToken, 'a');
    expect(session.refreshToken, 'r');
  });

  test(
    'logout clears the session even when the server is unreachable',
    () async {
      final session = AuthSession(storage: InMemoryTokenStorage());
      await session.store(access: 'a', refresh: 'r');
      final client = MockClient(
        (req) async => throw http.ClientException('offline'),
      );
      await HttpAuthRepository(
        ApiClient(
          authSession: session,
          httpClient: client,
          baseUrl: 'http://x/api',
        ),
      ).logout();
      expect(session.isLoggedIn, isFalse);
    },
  );

  test('Me skips tab names this app version does not know', () {
    final me = Me.fromJson({
      'id': 1,
      'first_name': 'K',
      'last_name': 'E',
      'full_name': 'E K',
      'status': 'actif',
      'is_diaspora': false,
      'age': 15,
      'roles': [],
      'permissions': {
        'calendar.events': ['view'],
      },
      'tabs': ['accueil', 'discipline', 'annonces'],
    });
    expect(me.tabs, [AppTab.accueil, AppTab.annonces]);
    expect(me.can('calendar.events', 'view'), isTrue);
    expect(me.can('finances.cashbook', 'view'), isFalse);
  });
}
