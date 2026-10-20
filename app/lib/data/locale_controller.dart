import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app is bilingual (French / English). The member picks the language
/// in the app; until they do, it follows the phone (French unless the
/// phone is in English). The choice is also sent to the server as
/// Accept-Language.
class LocaleController extends ChangeNotifier {
  LocaleController({Locale? initial}) : _locale = initial;

  static LocaleController instance = LocaleController();

  @visibleForTesting
  static void debugSetInstance(LocaleController c) => instance = c;

  static const supported = ['fr', 'en'];
  static const _key = 'msg_language';

  Locale? _locale;

  /// null = follow the phone.
  Locale? get locale => _locale;

  /// What is actually on screen right now.
  String get languageCode {
    final chosen = _locale?.languageCode;
    if (chosen != null) return chosen;
    final device = PlatformDispatcher.instance.locale.languageCode;
    return supported.contains(device) ? device : 'fr';
  }

  Future<void> load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_key);
      if (saved != null && supported.contains(saved)) {
        _locale = Locale(saved);
        notifyListeners();
      }
    } catch (_) {
      // Preferences unavailable: keep following the phone.
    }
  }

  Future<void> setLanguage(String code) async {
    if (!supported.contains(code)) return;
    _locale = Locale(code);
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setString(_key, code);
    } catch (_) {}
  }
}
