import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Masquer le solde" (owner, 2026-11-02): the eye on Finances hides the
/// balance on this phone, on Finances and on Accueil, until shown again.
class BalancePrivacy {
  BalancePrivacy._();

  static const _key = 'huddle_hide_balance';
  static final hidden = ValueNotifier<bool>(false);

  static Future<void> load() async {
    try {
      hidden.value =
          (await SharedPreferences.getInstance()).getBool(_key) ?? false;
    } catch (_) {
      // Preferences unavailable: shown.
    }
  }

  static Future<void> toggle() async {
    hidden.value = !hidden.value;
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, hidden.value);
    } catch (_) {}
  }
}
