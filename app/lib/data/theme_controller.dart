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
  static const _key2 = 'msg_color2';

  Color? _group;
  Color? _group2;
  Color? _mine;
  Color? _mine2;

  Color? get groupColor => _group;
  Color? get groupColor2 => _group2;

  /// null = the group's colour.
  Color? get myColor => _mine;

  /// The member's second colour (gradient); only with [myColor].
  Color? get myColor2 => _mine2;
  Color get seed => _mine ?? _group ?? fallback;

  /// The gradient's second colour, or null for a plain colour.
  Color? get seed2 => _mine != null ? _mine2 : _group2;

  /// "#2E7D46" → Color; null when absent or malformed.
  static Color? parse(String? hex) {
    final m = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(hex ?? '');
    return m == null ? null : Color(0xFF000000 | int.parse(m[1]!, radix: 16));
  }

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getInt(_key);
      if (v != null) _mine = Color(v);
      final v2 = p.getInt(_key2);
      if (v2 != null && _mine != null) _mine2 = Color(v2);
    } catch (_) {
      // Preferences unavailable: the group's colour.
    }
  }

  void setGroupColor(Color? c, [Color? c2]) {
    if (c == _group && c2 == _group2) return;
    _group = c;
    _group2 = c2;
    notifyListeners();
  }

  /// The member's colour; null goes back to the group's (gradient too).
  /// The second colour is kept unless [second] is given.
  Future<void> choose(Color? c, {Color? second, bool plain = false}) async {
    _mine = c;
    if (c == null || plain) {
      _mine2 = null;
    } else if (second != null) {
      _mine2 = second;
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (c == null) {
        await prefs.remove(_key);
      } else {
        await prefs.setInt(_key, c.toARGB32());
      }
      if (_mine2 == null) {
        await prefs.remove(_key2);
      } else {
        await prefs.setInt(_key2, _mine2!.toARGB32());
      }
    } catch (_) {}
  }
}
