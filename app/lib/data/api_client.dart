import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_session.dart';
import 'group_controller.dart';
import 'locale_controller.dart';
import 'offline.dart';

/// Set at build time, never at runtime:
/// `flutter build apk --dart-define=API_BASE_URL=https://msg-staging.onrender.com/api`
/// The default reaches a local `runserver` from the Android emulator.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api',
);

const Duration _requestTimeout = Duration(seconds: 30);

/// Non-2xx response. [detail] is the server's own French message when it
/// sent one (DRF's `{"detail": ...}`), ready to show as-is.
class ApiException implements Exception {
  ApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  Map<String, dynamic>? get json {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  String? get detail => json?['detail'] as String?;

  /// Stable error code (e.g. `wrong_pin`) the app words in the chosen language.
  String? get code => json?['code'] as String?;

  @override
  String toString() => 'ApiException($statusCode): $body';
}

/// No response at all (offline, DNS, timeout) — distinct from an HTTP error
/// so screens can say "check your network" instead of "server error".
class NetworkException implements Exception {
  NetworkException(this.cause);
  final Object cause;

  @override
  String toString() => 'NetworkException($cause)';
}

class ApiClient {
  ApiClient({
    required this.authSession,
    http.Client? httpClient,
    String? baseUrl,
  }) : _client = httpClient ?? http.Client(),
       baseUrl = baseUrl ?? apiBaseUrl;

  final AuthSession authSession;
  final http.Client _client;
  final String baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) => Uri.parse(
    '$baseUrl$path',
  ).replace(queryParameters: query?.isEmpty ?? true ? null : query);

  /// GET with the offline cache: a success is remembered; without network
  /// the last remembered answer is returned and the app shows "Hors ligne".
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = _uri(path, query);
    // Per group: one group's cached answers never show in another.
    final key =
        'g${GroupController.instance.id ?? 0}:'
        '${uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path}';
    final offline = OfflineState.instance;
    try {
      final data = await _send('GET', uri);
      await offline.remember(key, data);
      _flushSoon();
      return data;
    } on NetworkException {
      if (offline.has(key)) {
        offline.markOffline();
        return offline.recall(key);
      }
      rethrow;
    }
  }

  /// A write that may wait for the network (idempotent operations only).
  /// Without network it is queued and [QueuedOffline] is thrown.
  Future<dynamic> sendOrQueue(
    String method,
    String path, {
    Object? body,
    required String kind,
  }) async {
    try {
      final data = await _send(method, _uri(path), body: body);
      _flushSoon();
      return data;
    } on NetworkException {
      final item = OutboxItem(
        method: method,
        path: path,
        body: body,
        kind: kind,
        groupId: GroupController.instance.id,
      );
      await OfflineState.instance.enqueue(item);
      throw QueuedOffline(item);
    }
  }

  /// Send whatever waited for the network.
  Future<void> flushOutbox() => OfflineState.instance.flush(
    (item) => _send(
      item.method,
      _uri(item.path),
      body: item.body,
      groupId: item.groupId,
    ),
    isNetworkError: (e) => e is NetworkException,
  );

  void _flushSoon() {
    if (OfflineState.instance.pending > 0) unawaited(flushOutbox());
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => _send('POST', _uri(path), body: body, authenticated: authenticated);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', _uri(path), body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', _uri(path), body: body);

  Future<dynamic> delete(String path) => _send('DELETE', _uri(path));

  /// Multipart upload of one file field (attachments), with optional text
  /// [fields]. Retries once after a token refresh, like every other call.
  Future<dynamic> postFile(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
    Map<String, String> fields = const {},
    bool isRetry = false,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..fields.addAll(fields)
      ..files.add(
        http.MultipartFile.fromBytes(field, bytes, filename: filename),
      );
    final access = authSession.accessToken;
    if (access != null) request.headers['Authorization'] = 'Bearer $access';
    request.headers['Accept-Language'] = LocaleController.instance.languageCode;
    final group = GroupController.instance.id;
    if (group != null) request.headers['X-Group'] = '$group';
    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 120)),
      );
    } on SocketException catch (e) {
      throw NetworkException(e);
    } on TimeoutException catch (e) {
      throw NetworkException(e);
    } on http.ClientException catch (e) {
      throw NetworkException(e);
    }
    if (response.statusCode == 401 &&
        !isRetry &&
        authSession.refreshToken != null &&
        await authSession.refreshAccessToken(this)) {
      return postFile(
        path,
        field: field,
        bytes: bytes,
        filename: filename,
        fields: fields,
        isRetry: true,
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isEmpty
          ? null
          : jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw ApiException(response.statusCode, utf8.decode(response.bodyBytes));
  }

  Future<dynamic> _send(
    String method,
    Uri uri, {
    Object? body,
    bool authenticated = true,
    bool isRetry = false,
    int? groupId,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': LocaleController.instance.languageCode,
    };
    final group = groupId ?? GroupController.instance.id;
    if (group != null) headers['X-Group'] = '$group';
    final access = authenticated ? authSession.accessToken : null;
    if (access != null) headers['Authorization'] = 'Bearer $access';

    final http.Response response;
    try {
      response = await _request(method, uri, headers, body);
    } on SocketException catch (e) {
      throw NetworkException(e);
    } on TimeoutException catch (e) {
      throw NetworkException(e);
    } on http.ClientException catch (e) {
      throw NetworkException(e);
    }

    if (response.statusCode == 401 &&
        authenticated &&
        !isRetry &&
        authSession.refreshToken != null) {
      if (await authSession.refreshAccessToken(this)) {
        return _send(
          method,
          uri,
          body: body,
          authenticated: authenticated,
          isRetry: true,
          groupId: groupId,
        );
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw ApiException(response.statusCode, utf8.decode(response.bodyBytes));
  }

  Future<http.Response> _request(
    String method,
    Uri uri,
    Map<String, String> headers,
    Object? body,
  ) {
    final encoded = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET':
        return _client.get(uri, headers: headers).timeout(_requestTimeout);
      case 'POST':
        return _client
            .post(uri, headers: headers, body: encoded)
            .timeout(_requestTimeout);
      case 'PUT':
        return _client
            .put(uri, headers: headers, body: encoded)
            .timeout(_requestTimeout);
      case 'PATCH':
        return _client
            .patch(uri, headers: headers, body: encoded)
            .timeout(_requestTimeout);
      case 'DELETE':
        return _client.delete(uri, headers: headers).timeout(_requestTimeout);
      default:
        throw ArgumentError('Unsupported method: $method');
    }
  }

  /// Raw refresh call used by [AuthSession]; never retried or re-authenticated.
  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    final result = await _send(
      'POST',
      _uri('/auth/refresh/'),
      body: {'refresh': refreshToken},
      authenticated: false,
    );
    return result as Map<String, dynamic>;
  }
}
