import '../../models/me.dart';

abstract class ProfileRepository {
  Future<Me> fetchMe();
}
