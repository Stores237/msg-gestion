import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/main.dart';
import 'package:msg_gestion/screens/login_phone_screen.dart';

import 'helpers.dart';

/// Conditions of use checkbox at login (owner, 2026-10-26).
void main() {
  Future<void> typePin(WidgetTester tester, String pin) async {
    for (final d in pin.split('')) {
      await tester.tap(find.widgetWithText(InkWell, d));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('Continue asks for the box; the version shown is sent', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    f.auth.termsVersion = 3;
    await tester.pumpWidget(const MsgApp(home: LoginPhoneScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('phone-field')), '677452108');
    await tester.tap(find.byKey(const Key('phone-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Cochez la case pour continuer.'), findsOneWidget);
    expect(find.text('Votre code PIN'), findsNothing);
    // The whole line ticks the box, not only the small square.
    await tester.tap(
      find.byKey(const Key('terms-accept')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(find.byKey(const Key('terms-missing')), findsNothing);
    await tester.tap(find.byKey(const Key('phone-continue')));
    await tester.pumpAndSettle();
    await typePin(tester, '4821');
    expect(f.auth.acceptedTerms, [3]);
  });

  testWidgets('the link opens the conditions written by the partner', (
    tester,
  ) async {
    await setUpApp(tester);
    await tester.pumpWidget(const MsgApp(home: LoginPhoneScreen()));
    await tester.pumpAndSettle();
    await tester.tapOnText(
      find.textRange.ofSubstring('conditions d’utilisation'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Conditions d’utilisation de test.'), findsOneWidget);
  });

  testWidgets('conditions changed since the box was ticked: say so', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await tester.pumpWidget(const MsgApp(home: LoginPhoneScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('phone-field')), '677452108');
    await tester.tap(find.byKey(const Key('terms-checkbox')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('phone-continue')));
    await tester.pumpAndSettle();
    f.auth.termsVersion = 2; // the partner published a new text meanwhile
    await typePin(tester, '4821');
    expect(
      find.textContaining('Les conditions d’utilisation ont changé'),
      findsOneWidget,
    );
    expect(f.auth.acceptedTerms, isEmpty);
  });
}
