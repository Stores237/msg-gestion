import '../../api_client.dart';
import '../auth_repository.dart';

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._api);
  final ApiClient _api;

  @override
  Future<PhoneLookup> lookupPhone(String phone) async {
    try {
      final data = await _api.post('/auth/phone/', body: {'phone': phone}, authenticated: false) as Map<String, dynamic>;
      return PhoneLookup(phone: phone, firstName: data['first_name'] as String, hasPin: data['has_pin'] as bool);
    } on ApiException catch (e) {
      if (e.statusCode == 404) throw const UnknownMember();
      rethrow;
    }
  }

  @override
  Future<void> loginWithPin({required String phone, required String pin}) async {
    try {
      final data = await _api.post('/auth/login/', body: {'phone': phone, 'pin': pin}, authenticated: false) as Map<String, dynamic>;
      await _api.authSession.store(access: data['access'] as String, refresh: data['refresh'] as String);
    } on ApiException catch (e) {
      switch (e.statusCode) {
        case 401:
          throw WrongPin((e.json?['attempts_left'] as num?)?.toInt() ?? 0);
        case 423:
          throw AccountLocked((e.json?['minutes'] as num?)?.toInt() ?? 15);
        case 404:
          throw const UnknownMember();
        case 409:
          throw const NoPinSet();
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    final refresh = _api.authSession.refreshToken;
    try {
      if (refresh != null) await _api.post('/auth/logout/', body: {'refresh': refresh});
    } on Exception {
      // Signing out locally must work offline; the token expires on its own.
    } finally {
      await _api.authSession.clear();
    }
  }
}
