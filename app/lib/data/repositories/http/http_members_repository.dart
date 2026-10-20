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
  Future<MemberDetail> create(NewMember member) async => MemberDetail.fromJson(
    await _api.post('/members/', body: member.toJson()) as Map<String, dynamic>,
  );

  @override
  Future<String> resetPin(int id) async =>
      (await _api.post('/members/$id/reset-pin/')
              as Map<String, dynamic>)['temporary_pin']
          as String;
}
