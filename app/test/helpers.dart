import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msg_gestion/data/data_settings.dart';
import 'package:msg_gestion/data/file_store.dart';
import 'package:msg_gestion/data/auth_session.dart';
import 'package:msg_gestion/data/group_controller.dart';
import 'package:msg_gestion/data/theme_controller.dart';
import 'package:msg_gestion/data/locale_controller.dart';
import 'package:msg_gestion/data/offline.dart';
import 'package:msg_gestion/data/repository_locator.dart';
import 'package:msg_gestion/data/token_storage.dart';
import 'package:msg_gestion/main.dart';
import 'package:msg_gestion/models/me.dart';
import 'package:msg_gestion/screens/shell_screen.dart';

import 'fakes.dart';

class Fakes {
  Fakes(Me me) : profile = FakeProfileRepository(me);
  final FakeProfileRepository profile;
  final auth = FakeAuthRepository();
  final members = FakeMembersRepository();
  final events = FakeEventsRepository();
  final announcements = FakeAnnouncementsRepository();
  final finances = FakeFinancesRepository();
  final planning = FakePlanningRepository();
  final notifications = FakeNotificationsRepository();
  final files = FakeFiles();
}

/// French phone, fresh language choice, fake repositories, date symbols.
Future<Fakes> setUpApp(WidgetTester tester, {Me? me}) async {
  await initializeDateFormatting();
  tester.platformDispatcher.localesTestValue = const [Locale('fr', 'CM')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  LocaleController.debugSetInstance(LocaleController());
  SharedPreferences.setMockInitialValues({});
  DataSettings.debugSetInstance(DataSettings());
  PackageInfo.setMockInitialValues(
    appName: 'MSG',
    packageName: 'cm.msg.gestion',
    version: '0.1.0',
    buildNumber: '18',
    buildSignature: '',
  );
  GroupController.debugSetInstance(GroupController());
  ThemeController.debugSetInstance(ThemeController());
  OfflineState.debugSetInstance(OfflineState(storage: MemoryOfflineStorage()));
  final f = Fakes(me ?? fakeMe());
  FileStore.debugSetInstance(f.files.store);
  RepositoryLocator.debugSetInstance(
    RepositoryLocator(
      authSession: AuthSession(storage: InMemoryTokenStorage()),
      auth: f.auth,
      profile: f.profile,
      members: f.members,
      events: f.events,
      announcements: f.announcements,
      finances: f.finances,
      planning: f.planning,
      notifications: f.notifications,
    ),
  );
  return f;
}

Future<void> pumpShell(WidgetTester tester, Me me) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MsgApp(home: ShellScreen(me: me)));
  await tester.pumpAndSettle();
}

/// The phone's side of downloads: what was saved to its folders or opened.
class FakeFilePlatform implements FilePlatform {
  final saved = <String>[];
  final opened = <String>[];
  bool canSave = true;
  bool canOpen = true;

  @override
  Future<bool> saveToPhone(String path, String name, String mime) async {
    if (canSave) saved.add(name);
    return canSave;
  }

  @override
  Future<bool> open(String path, String mime) async {
    if (canOpen) opened.add(path);
    return canOpen;
  }
}

/// Photos and files in memory, from a server that can be switched off.
class FakeFiles {
  bool online = true;
  final fetched = <Uri>[];
  final platform = FakeFilePlatform();
  final backend = MemoryFileBackend();
  late final store = FileStore(
    backend: backend,
    platform: platform,
    fetch: (url) async {
      if (!online) throw const FileUnavailable('no network');
      fetched.add(url);
      return Uint8List.fromList(utf8.encode('file ${url.path}'));
    },
  );
}
