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

  /// New temporary PIN for a member (shown once to the secretary).
  Future<String> resetPin(int id);

  Future<String?> uploadPhoto(
    int id, {
    required List<int> bytes,
    required String filename,
  });

  /// (slug, name) of roles a bureau member may propose.
  Future<List<(String, String)>> requestableRoles();
  Future<void> requestRole(
    int id, {
    required String role,
    required String reason,
    required DateTime startsOn,
    DateTime? endsOn,
  });
}
