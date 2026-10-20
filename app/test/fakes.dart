import 'package:msg_gestion/data/repositories/auth_repository.dart';
import 'package:msg_gestion/data/repositories/profile_repository.dart';
import 'package:msg_gestion/models/me.dart';

Me fakeMe({String firstName = 'Ingrid', List<String> tabs = const ['accueil', 'calendrier', 'annonces'], List<Map<String, dynamic>>? roles}) => Me.fromJson({
      'id': 1,
      'first_name': firstName,
      'last_name': 'Fotso',
      'full_name': 'Fotso $firstName',
      'status': 'actif',
      'is_diaspora': false,
      'age': 34,
      'roles': roles ?? [{'slug': 'membre', 'name': 'Membre', 'kind': 'standard', 'starts_on': '2025-10-01', 'ends_on': null}],
      'permissions': <String, dynamic>{},
      'tabs': tabs,
    });

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.pin = '4821', this.firstName = 'Ingrid'});

  final String pin;
  final String firstName;
  int attemptsLeft = 3;
  int logouts = 0;

  @override
  Future<PhoneLookup> lookupPhone(String phone) async {
    if (phone.replaceAll(' ', '') != '677452108') {
      throw const UnknownMember();
    }
    return PhoneLookup(phone: phone, firstName: firstName, hasPin: true);
  }

  @override
  Future<void> loginWithPin({required String phone, required String pin}) async {
    if (pin == this.pin) return;
    attemptsLeft -= 1;
    if (attemptsLeft == 0) throw const AccountLocked(15);
    throw WrongPin(attemptsLeft);
  }

  @override
  Future<void> logout() async => logouts += 1;
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this.me);
  Me me;

  @override
  Future<Me> fetchMe() async => me;
}
