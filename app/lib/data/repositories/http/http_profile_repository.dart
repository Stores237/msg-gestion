import '../../../models/me.dart';
import '../../api_client.dart';
import '../profile_repository.dart';

class HttpProfileRepository implements ProfileRepository {
  HttpProfileRepository(this._api);
  final ApiClient _api;

  @override
  Future<Me> fetchMe() async =>
      Me.fromJson(await _api.get('/me/') as Map<String, dynamic>);

  @override
  Future<String?> uploadMyPhoto({
    required List<int> bytes,
    required String filename,
  }) async =>
      ((await _api.postFile(
                '/me/photo/',
                field: 'photo',
                bytes: bytes,
                filename: filename,
              ))
              as Map<String, dynamic>)['photo']
          as String?;

  @override
  Future<void> removeMyPhoto() async => _api.delete('/me/photo/');

  @override
  Future<GroupInfo> updateGroup({String? name, String? shortName}) async =>
      GroupInfo.fromJson(
        await _api.patch(
              '/group/',
              body: {'name': ?name, 'short_name': ?shortName},
            )
            as Map<String, dynamic>,
      );

  @override
  Future<GroupInfo> uploadGroupLogo({
    required List<int> bytes,
    required String filename,
  }) async => GroupInfo.fromJson(
    await _api.postFile(
          '/group/logo/',
          field: 'logo',
          bytes: bytes,
          filename: filename,
        )
        as Map<String, dynamic>,
  );

  @override
  Future<GroupInfo> removeGroupLogo() async => GroupInfo.fromJson(
    await _api.delete('/group/logo/') as Map<String, dynamic>,
  );

  @override
  Future<PlatformInfo> platform() async => PlatformInfo.fromJson(
    await _api.get('/platform/') as Map<String, dynamic>,
  );

  @override
  Future<AppSettings> settings() async {
    final j = await _api.get('/settings/') as Map<String, dynamic>;
    final types = ((j['activity_types'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    return AppSettings(
      quickAmounts: List<int>.from(j['quick_amounts'] as List),
      fees: (j['fees'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as int),
      ),
      activityTypes: [
        for (final a in types) (a['slug'] as String, a['name'] as String),
      ],
      // Older servers don't send the switches: keep the defaults.
      scopedTypes: types.isEmpty || !types.first.containsKey('has_scope')
          ? AppSettings.defaultScopedTypes
          : {
              for (final a in types)
                if (a['has_scope'] == true) a['slug'] as String,
            },
      typesWithoutChef: types.isEmpty || !types.first.containsKey('needs_chef')
          ? AppSettings.defaultTypesWithoutChef
          : {
              for (final a in types)
                if (a['needs_chef'] == false) a['slug'] as String,
            },
      dressCodes: [
        for (final d in (j['dress_codes'] as List?) ?? const [])
          (d['slug'] as String, d['name'] as String),
      ],
      eventMinutes: (j['event_minutes'] as int?) ?? 120,
      remindBeforeHours: (j['remind_before_hours'] as int?) ?? 2,
      reportHours: (j['report_hours'] as int?) ?? 24,
      contactPhone: (j['contact_phone'] as String?) ?? '',
      contactEmail: (j['contact_email'] as String?) ?? '',
      website: (j['website'] as String?) ?? '',
      rulesText: (j['rules_text'] as String?) ?? '',
    );
  }

  static List<FaqItem> _faq(Object? rows) => [
    for (final r in (rows as List?) ?? const [])
      (r['question'] as String, r['answer'] as String),
  ];

  @override
  Future<FaqData> faq() async {
    final j = await _api.get('/faq/') as Map<String, dynamic>;
    return FaqData(common: _faq(j['common']), group: _faq(j['group']));
  }

  @override
  Future<List<FaqSuggestion>> myFaqSuggestions() async => [
    for (final s in await _api.get('/faq/suggestions/') as List)
      FaqSuggestion(
        id: s['id'] as int,
        question: s['question'] as String,
        status: s['status'] as String,
        note: (s['note'] as String?) ?? '',
      ),
  ];

  @override
  Future<void> suggestFaq({required String question, String answer = ''}) =>
      _api.post(
        '/faq/suggestions/',
        body: {'question': question, 'answer': answer},
      );

  @override
  Future<void> setReminders({bool? eve, bool? twoHours}) => _api.patch(
    '/me/preferences/',
    body: {'remind_eve': ?eve, 'remind_2h': ?twoHours},
  );

  @override
  Future<BureauHome> bureauHome() async {
    final j = await _api.get('/home/bureau/') as Map<String, dynamic>;
    return BureauHome(
      membersActive: j['members_active'] as int?,
      toValidate: j['to_validate'] as int?,
      toConfirm: j['to_confirm'] as int?,
      collections: [
        for (final c in (j['collections'] as List?) ?? const [])
          (
            c['id'] as int,
            c['title'] as String,
            c['paid_full'] as int,
            c['members'] as int,
          ),
      ],
      unfilled: [
        for (final u in (j['unfilled'] as List?) ?? const [])
          (
            u['title'] as String,
            DateTime.parse(u['starts_at'] as String).toLocal(),
            u['missing'] as int,
          ),
      ],
    );
  }
}
