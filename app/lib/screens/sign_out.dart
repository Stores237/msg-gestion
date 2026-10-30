import 'package:flutter/material.dart';

import '../data/current_user.dart';
import '../data/group_controller.dart';
import '../data/offline.dart';
import 'login_phone_screen.dart';

/// Back to the login screen leaving nothing of this member on the phone:
/// after "Se déconnecter", and when the account was opened on another
/// phone ([notice] says so on the login screen).
Future<void> leaveSession(NavigatorState nav, {String? notice}) async {
  await OfflineState.instance.forget();
  await GroupController.instance.select(null);
  currentUser.value = null;
  if (!nav.mounted) return;
  nav.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => LoginPhoneScreen(notice: notice)),
    (_) => false,
  );
}
