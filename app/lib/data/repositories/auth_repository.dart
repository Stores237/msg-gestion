/// Result of step 1 of the login: the number belongs to a member.
class PhoneLookup {
  const PhoneLookup({required this.phone, required this.firstName, required this.hasPin});
  final String phone;
  final String firstName;
  final bool hasPin;
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

abstract class AuthRepository {
  /// Throws [UnknownMember] when the number isn't a member's.
  Future<PhoneLookup> lookupPhone(String phone);

  /// Stores the tokens in the session on success; throws a [PinFailure].
  Future<void> loginWithPin({required String phone, required String pin});

  Future<void> logout();
}
