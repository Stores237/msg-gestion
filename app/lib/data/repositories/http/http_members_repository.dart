import '../../../models/access_request.dart';
import '../../../models/member.dart';
import '../../api_client.dart';
import '../members_repository.dart';

class HttpMembersRepository implements MembersRepository {
  HttpMembersRepository(this._api);
  final ApiClient _api;

  @override
  Future<MemberPage> list({
    String query = '',
    String? status,
    bool diaspora = false,
  }) async {
    final data =
        await _api.get(
              '/members/',
              query: {
                if (query.isNotEmpty) 'q': query,
                'status': ?status,
                if (diaspora) 'diaspora': '1',
              },
            )
            as Map<String, dynamic>;
    return MemberPage(
      counts: MemberCounts.fromJson(data['counts'] as Map<String, dynamic>),
      members: [
        for (final m in data['results'] as List)
          MemberSummary.fromJson(m as Map<String, dynamic>),
      ],
    );
  }

  @override
  Future<MemberDetail> get(int id) async => MemberDetail.fromJson(
    await _api.get('/members/$id/') as Map<String, dynamic>,
  );

  @override
  Future<List<BureauEntry>> bureau() async => [
    for (final e in await _api.get('/members/bureau/') as List)
      BureauEntry.fromJson(e as Map<String, dynamic>),
  ];

  @override
  Future<AccessRequestItem> requestAccess(
    NewMember member, {
    required String role,
    String note = '',
  }) async => AccessRequestItem.fromJson(
    await _api.post(
          '/members/access-requests/',
          body: {...member.toJson(), 'role': role, 'note': note},
        )
        as Map<String, dynamic>,
  );

  @override
  Future<List<AccessRequestItem>> accessRequests() async => [
    for (final r in await _api.get('/members/access-requests/') as List)
      AccessRequestItem.fromJson(r as Map<String, dynamic>),
  ];

  @override
  Future<AccessPin> revealAccessPin(int requestId) async => AccessPin.fromJson(
    await _api.post('/members/access-requests/$requestId/pin/')
        as Map<String, dynamic>,
  );

  @override
  Future<String> resetPin(int id) async =>
      (await _api.post('/members/$id/reset-pin/')
              as Map<String, dynamic>)['temporary_pin']
          as String;

  @override
  Future<String?> uploadPhoto(
    int id, {
    required List<int> bytes,
    required String filename,
  }) async =>
      ((await _api.postFile(
                '/members/$id/photo/',
                field: 'photo',
                bytes: bytes,
                filename: filename,
              ))
              as Map<String, dynamic>)['photo']
          as String?;

  @override
  Future<List<(String, String)>> requestableRoles() async => [
    for (final r in await _api.get('/members/requestable-roles/') as List)
      (r['slug'] as String, r['name'] as String),
  ];

  @override
  Future<void> requestRole(
    int id, {
    required String role,
    required String reason,
    required DateTime startsOn,
    DateTime? endsOn,
  }) {
    String day(DateTime d) => d.toIso8601String().substring(0, 10);
    return _api.post(
      '/members/$id/role-requests/',
      body: {
        'role': role,
        'reason': reason,
        'starts_on': day(startsOn),
        if (endsOn != null) 'ends_on': day(endsOn),
      },
    );
  }
}
