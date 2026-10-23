import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Fingerprint / face unlock through the phone's own prompt (local_auth).
/// Tests swap [instance] for a fake; no phone hardware there.
class Biometrics {
  static Biometrics instance = Biometrics();

  @visibleForTesting
  static void debugSetInstance(Biometrics b) => instance = b;

  final _auth = LocalAuthentication();

  /// The phone has a fingerprint or face enrolled.
  Future<bool> available() async {
    try {
      return await _auth.canCheckBiometrics &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// True when the member passed; false when cancelled or refused.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
