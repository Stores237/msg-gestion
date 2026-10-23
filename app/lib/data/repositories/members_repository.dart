import '../../models/access_request.dart';
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

  /// Asks the platform's partner to open an access for [member] with
  /// [role] (the group leader's side of the access process).
  Future<AccessRequestItem> requestAccess(
    NewMember member, {
    required String role,
    String note = '',
  });
  Future<List<AccessRequestItem>> accessRequests();

  /// The temporary PIN of an approved request, shown once.
  Future<AccessPin> revealAccessPin(int requestId);

  /// New temporary PIN for a member (shown once to the secretary).
  Future<String> resetPin(int id);

  Future<String?> uploadPhoto(
    int id, {
    required List<int> bytes,
    required String filename,
  });

  /// (slug, name) of roles a bureau member may propose.
  /// [daily]: the roles that can be asked for one day (rôle du jour).
  Future<List<(String, String)>> requestableRoles({bool daily = false});

  /// [daily]: a role of the day on [startsOn] (an active member with no role).
  Future<void> requestRole(
    int id, {
    required String role,
    required String reason,
    required DateTime startsOn,
    DateTime? endsOn,
    bool daily = false,
  });
}
