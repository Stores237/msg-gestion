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
  Future<PlatformInfo> platform() async => PlatformInfo.fromJson(
    await _api.get('/platform/') as Map<String, dynamic>,
  );

  @override
  Future<AppSettings> settings() async {
    final j = await _api.get('/settings/') as Map<String, dynamic>;
    return AppSettings(
      quickAmounts: List<int>.from(j['quick_amounts'] as List),
      fees: (j['fees'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as int),
      ),
      activityTypes: [
        for (final a in (j['activity_types'] as List?) ?? const [])
          (a['slug'] as String, a['name'] as String),
      ],
      dressCodes: [
        for (final d in (j['dress_codes'] as List?) ?? const [])
          (d['slug'] as String, d['name'] as String),
      ],
    );
  }

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
