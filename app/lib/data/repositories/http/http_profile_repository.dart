import '../../../models/me.dart';
import '../../api_client.dart';
import '../profile_repository.dart';

class HttpProfileRepository implements ProfileRepository {
  HttpProfileRepository(this._api);
  final ApiClient _api;

  @override
  Future<Me> fetchMe() async =>
      Me.fromJson(await _api.get('/me/') as Map<String, dynamic>);
}
