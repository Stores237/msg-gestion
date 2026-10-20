/// Result of step 1 of the login: the number belongs to a member.
class PhoneLookup {
  const PhoneLookup({required this.phone, required this.firstName, required this.hasPin});
  final String phone;
  final String firstName;
  final bool hasPin;
}

/// Why a PIN was refused, with the server's own message.
sealed class PinFailure implements Exception {
  const PinFailure(this.message);
  final String message;
}

class WrongPin extends PinFailure {
  const WrongPin(super.message, this.attemptsLeft);
  final int attemptsLeft;
}

class AccountLocked extends PinFailure {
  const AccountLocked(super.message);
}

class UnknownMember extends PinFailure {
  const UnknownMember(super.message);
}

class NoPinSet extends PinFailure {
  const NoPinSet(super.message);
}

abstract class AuthRepository {
  /// Throws [UnknownMember] when the number isn't a member's.
  Future<PhoneLookup> lookupPhone(String phone);

  /// Stores the tokens in the session on success; throws a [PinFailure].
  Future<void> loginWithPin({required String phone, required String pin});

  Future<void> logout();
}
