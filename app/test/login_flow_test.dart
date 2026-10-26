import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/data/locale_controller.dart';
import 'package:msg_gestion/data/repository_locator.dart';
import 'package:msg_gestion/main.dart';
import 'package:msg_gestion/screens/login_phone_screen.dart';

import 'fakes.dart';
import 'helpers.dart';

void main() {
  late FakeAuthRepository auth;

  setUp(() {
    // A fresh, unsaved choice per test: follow the (test) phone language.
    LocaleController.debugSetInstance(LocaleController());
  });

  Future<void> pumpLogin(
    WidgetTester tester, {
    List<String> tabs = const ['accueil', 'calendrier', 'annonces'],
  }) async {
    final fakes = await setUpApp(tester, me: fakeMe(tabs: tabs));
    auth = fakes.auth;
    await tester.pumpWidget(const MsgApp(home: LoginPhoneScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> enterPhone(WidgetTester tester, String phone) async {
    await tester.enterText(find.byKey(const Key('phone-field')), phone);
    await tester.tap(find.byKey(const Key('phone-continue')));
    await tester.pumpAndSettle();
  }

  Future<void> typePin(WidgetTester tester, String pin) async {
    for (final d in pin.split('')) {
      await tester.tap(find.widgetWithText(InkWell, d));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('unknown number shows the server message, stays on the screen', (
    tester,
  ) async {
    await pumpLogin(tester);
    await enterPhone(tester, '699 99 99 99');
    expect(
      find.textContaining('Ce numéro n’est pas enregistré.'),
      findsOneWidget,
    );
    expect(find.text('Votre code PIN'), findsNothing);
  });

  testWidgets('implausible number is rejected before any request', (
    tester,
  ) async {
    await pumpLogin(tester);
    await enterPhone(tester, '12');
    expect(find.textContaining('Format : 6 XX XX XX XX, ou'), findsOneWidget);
  });

  testWidgets('known number greets the member by first name', (tester) async {
    await pumpLogin(tester);
    await enterPhone(tester, '6 77 45 21 08');
    expect(find.text('Bonjour Ingrid, entrez vos 4 chiffres.'), findsOneWidget);
  });

  testWidgets(
    'wrong PIN shows attempts left, then the lock disables the keypad',
    (tester) async {
      await pumpLogin(tester);
      await enterPhone(tester, '677452108');
      await typePin(tester, '0000');
      expect(
        find.text('Code incorrect. Il vous reste 2 essais.'),
        findsOneWidget,
      );
      await typePin(tester, '0000');
      expect(
        find.text('Code incorrect. Il vous reste 1 essai.'),
        findsOneWidget,
      );
      await typePin(tester, '0000');
      expect(find.textContaining('Compte bloqué'), findsOneWidget);
      // Keypad disabled: tapping the right PIN does nothing now.
      await typePin(tester, '4821');
      expect(find.textContaining('Compte bloqué'), findsOneWidget);
      expect(find.byKey(const Key('tab-accueil')), findsNothing);
    },
  );

  testWidgets('member logs in and sees only the three member tabs', (
    tester,
  ) async {
    await pumpLogin(tester);
    await enterPhone(tester, '677452108');
    await typePin(tester, '4821');
    expect(find.text('Ingrid'), findsOneWidget); // Accueil's greeting
    // The lock screen will check this PIN when the app reopens.
    final session = RepositoryLocator.instance.authSession;
    expect(await session.checkPin('4821'), isNull);
    expect(await session.checkPin('1234'), 4);
    expect(find.byKey(const Key('tab-accueil')), findsOneWidget);
    expect(find.byKey(const Key('tab-calendrier')), findsOneWidget);
    expect(find.byKey(const Key('tab-annonces')), findsOneWidget);
    expect(find.byKey(const Key('tab-finances')), findsNothing);
    expect(find.byKey(const Key('tab-membres')), findsNothing);
  });

  testWidgets('treasurer gets all five tabs from the server', (tester) async {
    await pumpLogin(
      tester,
      tabs: const ['accueil', 'membres', 'finances', 'calendrier', 'annonces'],
    );
    await enterPhone(tester, '677452108');
    await typePin(tester, '4821');
    for (final t in [
      'accueil',
      'membres',
      'finances',
      'calendrier',
      'annonces',
    ]) {
      expect(find.byKey(Key('tab-$t')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('tab-finances')));
    await tester.pumpAndSettle();
    expect(find.text('SOLDE DE LA CAISSE'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tab-membres')));
    await tester.pumpAndSettle();
    expect(find.text('Ewane Brice'), findsOneWidget);
  });

  testWidgets('logout returns to the phone screen', (tester) async {
    await pumpLogin(tester);
    await enterPhone(tester, '677452108');
    await typePin(tester, '4821');
    await tester.tap(find.byKey(const Key('open-account')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('logout')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('logout')));
    await tester.pumpAndSettle();
    expect(auth.logouts, 1);
    expect(find.text('Bienvenue'), findsOneWidget);
  });

  testWidgets('the in-app switch changes the language on the spot', (
    tester,
  ) async {
    await pumpLogin(tester);
    expect(find.text('Bienvenue'), findsOneWidget);
    await tester.tap(find.byKey(const Key('lang-en')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome'), findsOneWidget);
    await enterPhone(tester, '677452108');
    await typePin(tester, '0000');
    expect(find.text('Wrong PIN. 2 attempts left.'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lang-fr')));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenue'), findsOneWidget);
  });

  testWidgets('an English phone gets the English strings', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const MsgApp(home: LoginPhoneScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Welcome'), findsOneWidget);
  });

  testWidgets('any other language falls back to French', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const MsgApp(home: LoginPhoneScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenue'), findsOneWidget);
  });
}
