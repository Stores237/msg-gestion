/// Result of step 1 of the login: the number belongs to a member.
class PhoneLookup {
  const PhoneLookup({
    required this.phone,
    required this.firstName,
    required this.hasPin,
    this.termsVersion = 1,
  });
  final String phone;
  final String firstName;
  final bool hasPin;

  /// The conditions version the login checkbox accepts.
  final int termsVersion;
}

/// The conditions shown before login (the checkbox links to them).
class TermsInfo {
  const TermsInfo({
    required this.version,
    required this.termsText,
    this.privacyText = '',
  });
  final int version;
  final String termsText;
  final String privacyText;
}

/// Why a login was refused. Carries numbers, not sentences: screens word
/// it in the member's language (see widgets/errors.dart).
sealed class PinFailure implements Exception {
  const PinFailure();
}

class WrongPin extends PinFailure {
  const WrongPin(this.attemptsLeft);
  final int attemptsLeft;
}

class AccountLocked extends PinFailure {
  const AccountLocked(this.minutes);
  final int minutes;
}

class UnknownMember extends PinFailure {
  const UnknownMember();
}

class NoPinSet extends PinFailure {
  const NoPinSet();
}

/// A super admin account: it works only in the web back-office.
class BackofficeOnly extends PinFailure {
  const BackofficeOnly();
}

/// The conditions changed (or weren't accepted): tick the box again.
class TermsRequired extends PinFailure {
  const TermsRequired();
}

abstract class AuthRepository {
  /// Throws [UnknownMember] when the number isn't a member's.
  Future<PhoneLookup> lookupPhone(String phone);

  /// The conditions of use and privacy texts, readable before login.
  Future<TermsInfo> terms();

  /// Stores the tokens in the session on success; throws a [PinFailure].
  /// Returns true when the PIN was temporary and must be changed now.
  /// [acceptedTerms] is the conditions version the member ticked.
  Future<bool> loginWithPin({
    required String phone,
    required String pin,
    required int acceptedTerms,
  });

  /// Throws [WrongPin]/[AccountLocked] for a wrong current PIN, or an
  /// ApiException with code `pin_too_simple`.
  Future<void> changePin({required String currentPin, required String newPin});

  /// Texts a code; ApiException code `sms_unavailable` until Twilio exists.
  Future<void> forgotPin(String phone);

  /// Sets the new PIN and logs in. ApiException code `bad_code`.
  Future<void> forgotPinConfirm({
    required String phone,
    required String code,
    required String newPin,
    required int acceptedTerms,
  });

  Future<void> logout();
}
