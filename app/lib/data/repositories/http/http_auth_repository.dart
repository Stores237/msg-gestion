import '../../api_client.dart';
import '../auth_repository.dart';

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._api);
  final ApiClient _api;

  @override
  Future<PhoneLookup> lookupPhone(String phone) async {
    try {
      final data =
          await _api.post(
                '/auth/phone/',
                body: {'phone': phone},
                authenticated: false,
              )
              as Map<String, dynamic>;
      return PhoneLookup(
        phone: phone,
        firstName: data['first_name'] as String,
        hasPin: data['has_pin'] as bool,
        termsVersion: (data['terms_version'] as num?)?.toInt() ?? 1,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) throw const UnknownMember();
      rethrow;
    }
  }

  @override
  Future<TermsInfo> terms() async {
    final data = await _api.get('/auth/terms/') as Map<String, dynamic>;
    return TermsInfo(
      version: (data['terms_version'] as num).toInt(),
      termsText: data['terms_text'] as String? ?? '',
      privacyText: data['privacy_text'] as String? ?? '',
    );
  }

  @override
  Future<bool> loginWithPin({
    required String phone,
    required String pin,
    required int acceptedTerms,
  }) async {
    try {
      final data =
          await _api.post(
                '/auth/login/',
                body: {
                  'phone': phone,
                  'pin': pin,
                  'accept_terms': true,
                  'terms_version': acceptedTerms,
                },
                authenticated: false,
              )
              as Map<String, dynamic>;
      await _api.authSession.store(
        access: data['access'] as String,
        refresh: data['refresh'] as String,
      );
      return data['pin_must_change'] == true;
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
        case 403 when e.code == 'backoffice_only':
          throw const BackofficeOnly();
        case 428:
          throw const TermsRequired();
      }
      rethrow;
    }
  }

  @override
  Future<void> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    try {
      await _api.post(
        '/auth/pin/change/',
        body: {'current_pin': currentPin, 'new_pin': newPin},
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw WrongPin((e.json?['attempts_left'] as num?)?.toInt() ?? 0);
      }
      if (e.statusCode == 423) {
        throw AccountLocked((e.json?['minutes'] as num?)?.toInt() ?? 15);
      }
      rethrow;
    }
  }

  @override
  Future<void> setFinanceCode({
    required String pin,
    required String code,
  }) async {
    try {
      await _api.post('/auth/finance-code/', body: {'pin': pin, 'code': code});
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw WrongPin((e.json?['attempts_left'] as num?)?.toInt() ?? 0);
      }
      if (e.statusCode == 423) {
        throw AccountLocked((e.json?['minutes'] as num?)?.toInt() ?? 15);
      }
      rethrow;
    }
  }

  @override
  Future<void> switchFinanceCode({required bool on, String code = ''}) async {
    try {
      await _api.post(
        '/auth/finance-code/switch/',
        body: {'on': on, 'code': code},
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw WrongFinanceCode(
          (e.json?['attempts_left'] as num?)?.toInt() ?? 0,
        );
      }
      if (e.statusCode == 423) {
        throw AccountLocked((e.json?['minutes'] as num?)?.toInt() ?? 15);
      }
      rethrow;
    }
  }

  @override
  Future<void> checkFinanceCode(String code) async {
    try {
      await _api.post('/auth/finance-code/check/', body: {'code': code});
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw WrongFinanceCode(
          (e.json?['attempts_left'] as num?)?.toInt() ?? 0,
        );
      }
      if (e.statusCode == 423) {
        throw AccountLocked((e.json?['minutes'] as num?)?.toInt() ?? 15);
      }
      rethrow;
    }
  }

  @override
  Future<void> forgotPin(String phone) async {
    try {
      await _api.post(
        '/auth/pin/forgot/',
        body: {'phone': phone},
        authenticated: false,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) throw const UnknownMember();
      rethrow;
    }
  }

  @override
  Future<void> forgotPinConfirm({
    required String phone,
    required String code,
    required String newPin,
    required int acceptedTerms,
  }) async {
    final data =
        await _api.post(
              '/auth/pin/forgot/confirm/',
              body: {
                'phone': phone,
                'code': code,
                'new_pin': newPin,
                'accept_terms': true,
                'terms_version': acceptedTerms,
              },
              authenticated: false,
            )
            as Map<String, dynamic>;
    await _api.authSession.store(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
    );
  }

  @override
  Future<void> logout() async {
    final refresh = _api.authSession.refreshToken;
    try {
      if (refresh != null) {
        await _api.post('/auth/logout/', body: {'refresh': refresh});
      }
    } on Exception {
      // Signing out locally must work offline; the token expires on its own.
    } finally {
      await _api.authSession.clear();
    }
  }
}
