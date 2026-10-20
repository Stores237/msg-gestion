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
  Future<AppSettings> settings() async {
    final j = await _api.get('/settings/') as Map<String, dynamic>;
    return AppSettings(
      quickAmounts: List<int>.from(j['quick_amounts'] as List),
      fees: (j['fees'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as int),
      ),
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
