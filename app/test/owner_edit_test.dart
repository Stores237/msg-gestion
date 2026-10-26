// Owner, 2026-10-26: whoever posts an announcement or an event can edit
// and delete it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'helpers.dart';

const _poster = {
  'calendar.events': ['view', 'create'],
  'announcements.posts': ['view', 'create'],
};

void main() {
  testWidgets('my announcement: edit it, then delete it', (tester) async {
    final f = await setUpApp(tester);
    await pumpShell(
      tester,
      fakeMe(tabs: const ['accueil', 'annonces'], permissions: _poster),
    );
    await tester.tap(find.byKey(const Key('tab-annonces')));
    await tester.pumpAndSettle();
    // Someone else's: no edit / delete.
    await tester.tap(find.text('Répétition des chants'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('owner-edit')), findsNothing);
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('compose')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('a-title')), 'Collecte');
    await tester.tap(find.byKey(const Key('a-send')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Collecte'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('owner-edit')));
    await tester.pumpAndSettle();
    expect(find.text('Modifier l’annonce'), findsOneWidget);
    expect(find.byKey(const Key('a-pin')), findsNothing);
    // The "Publié." notice from the first post would cover the button.
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .clearSnackBars();
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('a-title')), 'Collecte samedi');
    await tester.tap(find.byKey(const Key('a-send')));
    await tester.pumpAndSettle();
    expect(f.announcements.updated.single, endsWith(':Collecte samedi'));
    expect(find.text('Collecte samedi'), findsOneWidget);

    await tester.tap(find.byKey(const Key('owner-delete')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Supprimer « Collecte samedi »'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('owner-delete-confirm')));
    await tester.pumpAndSettle();
    expect(f.announcements.deleted, hasLength(1));
    expect(find.text('Collecte samedi'), findsNothing); // back on the list
  });

  testWidgets('my event: edit it, then delete it', (tester) async {
    final f = await setUpApp(tester);
    f.events.owner = true;
    await pumpShell(
      tester,
      fakeMe(tabs: const ['accueil', 'calendrier'], permissions: _poster),
    );
    await tester.tap(find.byKey(const Key('tab-calendrier')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('seg-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assise hebdomadaire'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('owner-edit')));
    await tester.tap(find.byKey(const Key('owner-edit')));
    await tester.pumpAndSettle();
    expect(find.text('Modifier l’événement'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('f-title')), 'Assise déplacée');
    await tester.scrollUntilVisible(
      find.byKey(const Key('save-event')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('save-event')));
    await tester.pumpAndSettle();
    expect(f.events.updated.single, startsWith('1:Assise déplacée'));

    await tester.ensureVisible(find.byKey(const Key('owner-delete')));
    await tester.tap(find.byKey(const Key('owner-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('owner-delete-confirm')));
    await tester.pumpAndSettle();
    expect(f.events.deleted, [1]);
  });

  testWidgets('not mine and no right: no edit / delete on the event', (
    tester,
  ) async {
    await setUpApp(tester);
    await pumpShell(tester, fakeMe(tabs: const ['accueil', 'calendrier']));
    await tester.tap(find.byKey(const Key('tab-calendrier')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('seg-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assise hebdomadaire'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('owner-edit')), findsNothing);
    expect(find.byKey(const Key('owner-delete')), findsNothing);
  });
}
