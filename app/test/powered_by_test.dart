import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/main.dart';
import 'package:msg_gestion/screens/account_screen.dart';
import 'package:msg_gestion/screens/login_phone_screen.dart';

import 'fakes.dart';
import 'helpers.dart';

/// The developer's signature and the version (owner, 2026-10-28).
void main() {
  testWidgets('login and Mon compte show Propulsé par STORES and the version', (
    tester,
  ) async {
    await setUpApp(tester);
    await tester.pumpWidget(const MsgApp(home: LoginPhoneScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('app-version')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Propulsé par'), findsOneWidget);
    expect(find.text('STORES'), findsOneWidget);
    expect(find.text('Version 0.1.0 (18)'), findsOneWidget);

    await tester.pumpWidget(MsgApp(home: AccountScreen(me: fakeMe())));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('app-version')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Version 0.1.0 (18)'), findsOneWidget);
  });
}
