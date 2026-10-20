import '../../models/member.dart';

abstract class MembersRepository {
  /// [status]: actif | conge | classe ; [diaspora] filters diaspora members.
  Future<MemberPage> list({
    String query = '',
    String? status,
    bool diaspora = false,
  });
  Future<MemberDetail> get(int id);
  Future<List<BureauEntry>> bureau();

  /// Returns the new member, with [MemberDetail.temporaryPin] set.
  Future<MemberDetail> create(NewMember member);
}
