import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The group the app works in. MSG serves several groups and one account
/// can belong to more than one; every request names the chosen group in
/// the `X-Group` header (the server falls back to the member's first group
/// when none is chosen yet).
class GroupController extends ChangeNotifier {
  static GroupController instance = GroupController();

  @visibleForTesting
  static void debugSetInstance(GroupController c) => instance = c;

  static const _key = 'msg_group';

  int? _id;
  int? get id => _id;

  Future<void> load() async {
    try {
      _id = (await SharedPreferences.getInstance()).getInt(_key);
    } catch (_) {
      // Preferences unavailable: the server picks the first group.
    }
  }

  Future<void> select(int? id) async {
    if (id == _id) return;
    _id = id;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (id == null) {
        await prefs.remove(_key);
      } else {
        await prefs.setInt(_key, id);
      }
    } catch (_) {}
  }
}
