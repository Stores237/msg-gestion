import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/main.dart';
import 'package:msg_gestion/screens/login_phone_screen.dart';

import 'fakes.dart';
import 'helpers.dart';

Future<void> enterPhoneAndPin(WidgetTester tester, String pin) async {
  await tester.enterText(find.byKey(const Key('phone-field')), '677452108');
  await tester.tap(find.byKey(const Key('phone-continue')));
  await tester.pumpAndSettle();
  for (final d in pin.split('')) {
    await tester.tap(find.widgetWithText(InkWell, d));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a temporary PIN forces choosing a personal one, simple PINs refused',
    (tester) async {
      final f = await setUpApp(tester);
      f.auth.mustChange = true;
      await tester.pumpWidget(const MsgApp(home: LoginPhoneScreen()));
      await tester.pumpAndSettle();
      await enterPhoneAndPin(tester, '4821');
      expect(find.text('Choisissez votre code PIN'), findsOneWidget);
      expect(find.byTooltip('Retour'), findsNothing); // can't skip it

      await tester.enterText(find.byKey(const Key('pin-new')), '1234');
      await tester.enterText(find.byKey(const Key('pin-confirm')), '1234');
      await tester.tap(find.byKey(const Key('pin-save')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Code trop simple'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('pin-new')), '7391');
      await tester.enterText(find.byKey(const Key('pin-confirm')), '7390');
      await tester.tap(find.byKey(const Key('pin-save')));
      await tester.pumpAndSettle();
      expect(
        find.text('Les deux codes ne sont pas identiques.'),
        findsOneWidget,
      );

      await tester.enterText(find.byKey(const Key('pin-confirm')), '7391');
      await tester.tap(find.byKey(const Key('pin-save')));
      await tester.pumpAndSettle();
      expect(f.auth.changed, ['7391']);
      expect(find.byKey(const Key('tab-accueil')), findsOneWidget);
    },
  );

  testWidgets('forgot PIN without SMS tells the member to ask the secretary', (
    tester,
  ) async {
    await setUpApp(tester);
    await tester.pumpWidget(const MsgApp(home: LoginPhoneScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('phone-field')), '677452108');
    await tester.tap(find.byKey(const Key('phone-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('forgot-pin')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('forgot-submit')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Demandez au secrétaire général'),
      findsOneWidget,
    );
  });

  testWidgets('forgot PIN with SMS: code + new PIN logs the member in', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    f.auth.smsAvailable = true;
    await tester.pumpWidget(const MsgApp(home: LoginPhoneScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('phone-field')), '677452108');
    await tester.tap(find.byKey(const Key('phone-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('forgot-pin')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('forgot-submit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('forgot-code')), '123456');
    await tester.enterText(find.byKey(const Key('forgot-new')), '7391');
    await tester.enterText(find.byKey(const Key('forgot-confirm')), '7391');
    await tester.tap(find.byKey(const Key('forgot-submit')));
    await tester.pumpAndSettle();
    expect(f.auth.changed, ['7391']);
    expect(find.byKey(const Key('tab-accueil')), findsOneWidget);
  });

  testWidgets('the secretary resets a member PIN from the profile', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await pumpShell(
      tester,
      fakeMe(
        tabs: const ['accueil', 'membres'],
        permissions: const {
          'members.profile': ['view', 'change'],
        },
      ),
    );
    await tester.tap(find.byKey(const Key('tab-membres')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ewane Brice'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('reset-pin')));
    await tester.tap(find.byKey(const Key('reset-pin')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset-confirm')));
    await tester.pumpAndSettle();
    expect(f.members.resets, [1]);
    expect(find.textContaining('7391'), findsOneWidget);
  });

  testWidgets('a member without change rights sees no reset button', (
    tester,
  ) async {
    await setUpApp(tester);
    await pumpShell(
      tester,
      fakeMe(
        tabs: const ['accueil', 'membres'],
        permissions: const {
          'members.profile': ['view'],
        },
      ),
    );
    await tester.tap(find.byKey(const Key('tab-membres')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ewane Brice'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reset-pin')), findsNothing);
  });
}
