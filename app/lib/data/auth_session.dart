import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'token_storage.dart';

/// Holds the JWT pair. The server rotates the refresh token on every use
/// and blacklists the old one, so a new pair is always stored as a whole.
class AuthSession extends ChangeNotifier {
  AuthSession({TokenStorage? storage})
    : _storage = storage ?? const SecureTokenStorage();

  static AuthSession instance = AuthSession();

  @visibleForTesting
  static void debugSetInstance(AuthSession session) => instance = session;

  final TokenStorage _storage;

  static const _accessKey = 'msg_access_token';
  static const _refreshKey = 'msg_refresh_token';

  String? accessToken;
  String? refreshToken;

  bool get isLoggedIn => refreshToken != null;

  Future<void>? _inFlightRefresh;
  bool _lastRefreshOk = false;

  Future<void> bootstrap() async {
    accessToken = await _storage.read(_accessKey);
    refreshToken = await _storage.read(_refreshKey);
    notifyListeners();
  }

  Future<void> store({required String access, required String refresh}) async {
    accessToken = access;
    refreshToken = refresh;
    await _storage.write(_accessKey, access);
    await _storage.write(_refreshKey, refresh);
    notifyListeners();
  }

  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    await _storage.delete(_accessKey);
    await _storage.delete(_refreshKey);
    notifyListeners();
  }

  /// Several requests can hit a 401 at once after the access token
  /// expires. They must share one refresh: with rotation + blacklisting, a
  /// second refresh using the same (now blacklisted) token would fail and
  /// log the member out.
  Future<bool> refreshAccessToken(ApiClient client) async {
    final pending = _inFlightRefresh;
    if (pending != null) {
      await pending;
      return _lastRefreshOk;
    }
    final completer = _doRefresh(client);
    _inFlightRefresh = completer;
    try {
      await completer;
      return _lastRefreshOk;
    } finally {
      _inFlightRefresh = null;
    }
  }

  Future<void> _doRefresh(ApiClient client) async {
    final token = refreshToken;
    if (token == null) {
      _lastRefreshOk = false;
      return;
    }
    try {
      final data = await client.refresh(token);
      await store(
        access: data['access'] as String,
        refresh: data['refresh'] as String,
      );
      _lastRefreshOk = true;
    } on ApiException {
      // Refresh token expired or blacklisted: a real sign-out.
      await clear();
      _lastRefreshOk = false;
    } on NetworkException {
      // Offline is not a sign-out; keep the tokens and let the caller fail.
      _lastRefreshOk = false;
    }
  }
}
