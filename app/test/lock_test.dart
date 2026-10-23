// The PIN is asked when the app reopens, and after a while in the
// background; fingerprint / face when the member turned it on
// (owner, 2026-10-23).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/data/biometrics.dart';
import 'package:msg_gestion/data/repository_locator.dart';
import 'package:msg_gestion/main.dart';
import 'package:msg_gestion/screens/lock_screen.dart';
import 'package:msg_gestion/screens/login_phone_screen.dart';
import 'package:msg_gestion/screens/shell_screen.dart';

import 'fakes.dart';
import 'helpers.dart';

class FakeBiometrics extends Biometrics {
  FakeBiometrics({this.has = true, this.passes = true});
  final bool has;
  bool passes;
  int prompts = 0;

  @override
  Future<bool> available() async => has;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return passes;
  }
}

Future<void> typePin(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.widgetWithText(InkWell, d));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// A phone with a saved session (and the PIN remembered unless [pin] is
/// null), opened from cold.
Future<void> reopen(WidgetTester tester, {String? pin = '4821'}) async {
  await setUpApp(tester);
  final session = RepositoryLocator.instance.authSession;
  await session.store(access: 'a', refresh: 'r');
  if (pin != null) await session.rememberPin(pin);
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MsgApp());
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => Biometrics.debugSetInstance(FakeBiometrics(has: false)));

  testWidgets(
    'reopening asks the PIN; a wrong one counts, the right one opens',
    (tester) async {
      await reopen(tester);
      expect(find.byKey(const Key('lock-screen')), findsOneWidget);
      expect(find.byType(ShellScreen), findsNothing);
      await typePin(tester, '1111');
      expect(find.text('Code incorrect. Encore 4 essai(s).'), findsOneWidget);
      await typePin(tester, '4821');
      expect(find.byType(ShellScreen), findsOneWidget);
      expect(find.byKey(const Key('lock-screen')), findsNothing);
    },
  );

  testWidgets('five wrong PINs close the session', (tester) async {
    await reopen(tester);
    for (var i = 0; i < 5; i++) {
      await typePin(tester, '0000');
    }
    expect(find.byType(LoginPhoneScreen), findsOneWidget);
    expect(find.textContaining('Trop d’essais'), findsOneWidget);
    expect(RepositoryLocator.instance.authSession.isLoggedIn, isFalse);
  });

  testWidgets('a session from before the lock: sign in once more', (
    tester,
  ) async {
    await reopen(tester, pin: null);
    expect(find.byType(LoginPhoneScreen), findsOneWidget);
    expect(find.textContaining('reconnectez-vous une fois'), findsOneWidget);
    expect(RepositoryLocator.instance.authSession.isLoggedIn, isFalse);
  });

  testWidgets('fingerprint turned on: one touch opens the app', (tester) async {
    final bio = FakeBiometrics();
    Biometrics.debugSetInstance(bio);
    await setUpApp(tester);
    final session = RepositoryLocator.instance.authSession;
    await session.store(access: 'a', refresh: 'r');
    await session.rememberPin('4821');
    await session.setBiometric(true);
    Biometrics.debugSetInstance(bio); // setUpApp doesn't touch it, but be sure
    await tester.pumpWidget(const MsgApp());
    await tester.pumpAndSettle();
    expect(bio.prompts, 1);
    expect(find.byType(ShellScreen), findsOneWidget);
  });

  testWidgets('fingerprint refused: the PIN still works, the key retries', (
    tester,
  ) async {
    final bio = FakeBiometrics(passes: false);
    Biometrics.debugSetInstance(bio);
    await setUpApp(tester);
    final session = RepositoryLocator.instance.authSession;
    await session.store(access: 'a', refresh: 'r');
    await session.rememberPin('4821');
    await session.setBiometric(true);
    await tester.pumpWidget(const MsgApp());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lock-screen')), findsOneWidget);
    bio.passes = true;
    await tester.tap(find.byKey(const Key('key-fingerprint')));
    await tester.pumpAndSettle();
    expect(bio.prompts, 2);
    expect(find.byType(ShellScreen), findsOneWidget);
  });

  testWidgets('back from the background after the delay: locked again', (
    tester,
  ) async {
    LockScreen.lockAfter = Duration.zero;
    addTearDown(() => LockScreen.lockAfter = const Duration(minutes: 2));
    await reopen(tester);
    await typePin(tester, '4821');
    expect(find.byType(ShellScreen), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lock-screen')), findsOneWidget);
    await typePin(tester, '4821');
    expect(find.byKey(const Key('lock-screen')), findsNothing);
    expect(find.byType(ShellScreen), findsOneWidget);
  });

  testWidgets('Mon compte: turning the fingerprint on asks for it once', (
    tester,
  ) async {
    final bio = FakeBiometrics();
    Biometrics.debugSetInstance(bio);
    await setUpApp(tester);
    await pumpShell(tester, fakeMe());
    await tester.tap(find.byKey(const Key('open-account')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('biometric-switch')));
    await tester.tap(find.byKey(const Key('biometric-switch')));
    await tester.pumpAndSettle();
    expect(bio.prompts, 1);
    expect(
      await RepositoryLocator.instance.authSession.biometricEnabled,
      isTrue,
    );
  });
}
