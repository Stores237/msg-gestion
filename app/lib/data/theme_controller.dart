import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's main colour. Each group has one (back-office → Paramètres);
/// a member can pick their own in the app, which wins on this phone.
class ThemeController extends ChangeNotifier {
  static ThemeController instance = ThemeController();

  @visibleForTesting
  static void debugSetInstance(ThemeController c) => instance = c;

  static const fallback = Color(0xFF2E7D46);

  /// Offered in the app (same list as the back-office, white text readable
  /// on each).
  static const palette = [
    Color(0xFF2E7D46),
    Color(0xFF00695C),
    Color(0xFF1E5AA8),
    Color(0xFF23395B),
    Color(0xFF5B3FA0),
    Color(0xFF8E1B3A),
    Color(0xFFB3261E),
    Color(0xFF7A4E1D),
    Color(0xFF8A6514),
  ];

  static const _key = 'msg_color';

  Color? _group;
  Color? _mine;

  Color? get groupColor => _group;

  /// null = the group's colour.
  Color? get myColor => _mine;
  Color get seed => _mine ?? _group ?? fallback;

  /// "#2E7D46" → Color; null when absent or malformed.
  static Color? parse(String? hex) {
    final m = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(hex ?? '');
    return m == null ? null : Color(0xFF000000 | int.parse(m[1]!, radix: 16));
  }

  Future<void> load() async {
    try {
      final v = (await SharedPreferences.getInstance()).getInt(_key);
      if (v != null) _mine = Color(v);
    } catch (_) {
      // Preferences unavailable: the group's colour.
    }
  }

  void setGroupColor(Color? c) {
    if (c == _group) return;
    _group = c;
    notifyListeners();
  }

  Future<void> choose(Color? c) async {
    _mine = c;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (c == null) {
        await prefs.remove(_key);
      } else {
        await prefs.setInt(_key, c.toARGB32());
      }
    } catch (_) {}
  }
}
