// Owner, 2026-10-26: Aide / À propos in Mon compte; the author's role on
// announcements and calendar events; a clear message when storage fails.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/data/api_client.dart';
import 'package:msg_gestion/data/repositories/profile_repository.dart';
import 'package:msg_gestion/widgets/errors.dart';

import 'fakes.dart';
import 'helpers.dart';

Future<void> openAccount(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('open-account')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('help rows, FAQ and privacy policy', (tester) async {
    await setUpApp(tester);
    await pumpShell(tester, fakeMe());
    await openAccount(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('about-terms')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    for (final k in [
      'help-faq',
      'help-call',
      'help-whatsapp',
      'help-contact',
      'about-privacy',
    ]) {
      expect(find.byKey(Key(k)), findsOneWidget, reason: k);
    }
    // No website filled in by the partner: the row says so.
    expect(
      find.descendant(
        of: find.byKey(const Key('about-website')),
        matching: find.text('Pas encore disponible'),
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byKey(const Key('about-privacy')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('about-privacy')));
    await tester.pumpAndSettle();
    expect(find.text('Vos données restent dans le groupe.'), findsOneWidget);
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('help-faq')),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const Key('help-faq')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('help-faq')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('J’ai oublié mon code PIN.'));
    await tester.pumpAndSettle();
    expect(find.textContaining('code provisoire'), findsOneWidget);
  });

  testWidgets('nothing filled in yet: every contact row is greyed', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    f.profile.platformInfo = const PlatformInfo();
    await pumpShell(tester, fakeMe());
    await openAccount(tester);
    expect(find.text('Pas encore disponible'), findsNWidgets(6));
  });

  testWidgets('the author’s role shows on announcements and events', (
    tester,
  ) async {
    await setUpApp(tester);
    await pumpShell(
      tester,
      fakeMe(tabs: const ['accueil', 'calendrier', 'annonces']),
    );
    await tester.tap(find.byKey(const Key('tab-annonces')));
    await tester.pumpAndSettle();
    expect(find.text('Formateur'), findsWidgets);
    expect(find.byKey(const Key('author-role')), findsWidgets);
    await tester.tap(find.byKey(const Key('tab-calendrier')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('seg-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assise hebdomadaire'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('event-author')), findsOneWidget);
    expect(find.text('Commissaire aux comptes'), findsOneWidget);
  });

  testWidgets('storage failure: a clear message', (tester) async {
    await setUpApp(tester);
    await pumpShell(tester, fakeMe());
    final ctx = tester.element(find.byKey(const Key('home-header')));
    final msg = describeError(
      ctx,
      ApiException(503, '{"detail": "x", "code": "storage_unavailable"}'),
    );
    expect(msg, contains('stockage est indisponible'));
  });
}
