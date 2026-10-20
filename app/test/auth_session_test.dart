import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:msg_gestion/data/api_client.dart';
import 'package:msg_gestion/data/auth_session.dart';
import 'package:msg_gestion/data/token_storage.dart';

void main() {
  test('concurrent 401s share a single refresh call', () async {
    // The server blacklists a refresh token on first use, so a second
    // refresh with the same token would fail and sign the member out.
    // The delay forces both requests to hit 401 while the refresh is still
    // in flight — without it they could serialize and pass by luck.
    var refreshCalls = 0;
    final client = MockClient((req) async {
      if (req.url.path.endsWith('/auth/refresh/')) {
        refreshCalls += 1;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (jsonDecode(req.body)['refresh'] != 'r1') {
          return http.Response('{"detail":"blacklisted"}', 401);
        }
        return http.Response(
          jsonEncode({'access': 'a2', 'refresh': 'r2'}),
          200,
        );
      }
      if (req.headers['Authorization'] == 'Bearer a2') {
        return http.Response('{"ok":true}', 200);
      }
      return http.Response('{"detail":"expired"}', 401);
    });
    final session = AuthSession(storage: InMemoryTokenStorage());
    await session.store(access: 'a1', refresh: 'r1');
    final api = ApiClient(
      authSession: session,
      httpClient: client,
      baseUrl: 'http://x/api',
    );

    final results = await Future.wait([api.get('/me/'), api.get('/other/')]);

    expect(results, everyElement({'ok': true}));
    expect(refreshCalls, 1);
    expect(session.refreshToken, 'r2');
  });

  test('a rejected refresh signs out; going offline does not', () async {
    var offline = true;
    final client = MockClient((req) async {
      if (req.url.path.endsWith('/auth/refresh/')) {
        if (offline) throw http.ClientException('no route to host');
        return http.Response('{"detail":"blacklisted"}', 401);
      }
      return http.Response('{"detail":"expired"}', 401);
    });
    final session = AuthSession(storage: InMemoryTokenStorage());
    await session.store(access: 'a1', refresh: 'r1');
    final api = ApiClient(
      authSession: session,
      httpClient: client,
      baseUrl: 'http://x/api',
    );

    await expectLater(api.get('/me/'), throwsA(isA<ApiException>()));
    expect(session.isLoggedIn, isTrue, reason: 'offline must keep the session');

    offline = false;
    await expectLater(api.get('/me/'), throwsA(isA<ApiException>()));
    expect(session.isLoggedIn, isFalse);
  });

  test(
    'no response at all is a NetworkException, not a server error',
    () async {
      final client = MockClient(
        (req) async => throw http.ClientException('offline'),
      );
      final api = ApiClient(
        authSession: AuthSession(storage: InMemoryTokenStorage()),
        httpClient: client,
        baseUrl: 'http://x/api',
      );
      await expectLater(api.get('/me/'), throwsA(isA<NetworkException>()));
    },
  );
}
