import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
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
  static const _pinKey = 'msg_pin_check';
  static const _failsKey = 'msg_unlock_fails';
  static const _bioKey = 'msg_biometric';

  /// Wrong PINs on the lock screen before the session is closed.
  static const maxUnlockFails = 5;

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
    await _storage.delete(_pinKey);
    await _storage.delete(_failsKey);
    await _storage.delete(_bioKey);
    notifyListeners();
  }

  // --- App lock (owner, 2026-10-23: the PIN is asked when the app reopens) --
  //
  // The PIN itself is never stored: a salted, stretched hash of it is kept in
  // the phone's secure storage when the member signs in or changes it, so the
  // lock works offline. The server still checks the PIN at sign-in.

  static String _hash(String salt, String pin) {
    List<int> h = utf8.encode('$salt:$pin');
    for (var i = 0; i < 20000; i++) {
      h = sha256.convert([...h, ...utf8.encode(salt)]).bytes;
    }
    return base64Encode(h);
  }

  Future<void> rememberPin(String pin) async {
    final r = Random.secure();
    final salt = base64Encode(List.generate(16, (_) => r.nextInt(256)));
    await _storage.write(_pinKey, '$salt\$${_hash(salt, pin)}');
    await _storage.delete(_failsKey);
  }

  /// False when signed in before the lock existed: sign in again once.
  Future<bool> get canUnlock async => (await _storage.read(_pinKey)) != null;

  /// Null when right; otherwise the attempts left (0 = session closed).
  Future<int?> checkPin(String pin) async {
    final stored = (await _storage.read(_pinKey))?.split(r'$');
    if (stored == null || stored.length != 2) return 0;
    if (_hash(stored[0], pin) == stored[1]) {
      await _storage.delete(_failsKey);
      return null;
    }
    final fails = int.parse(await _storage.read(_failsKey) ?? '0') + 1;
    if (fails >= maxUnlockFails) {
      await clear();
      return 0;
    }
    await _storage.write(_failsKey, '$fails');
    return maxUnlockFails - fails;
  }

  Future<bool> get biometricEnabled async =>
      (await _storage.read(_bioKey)) == '1';

  Future<void> setBiometric(bool on) =>
      on ? _storage.write(_bioKey, '1') : _storage.delete(_bioKey);

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
