import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'helpers.dart';

const _secretary = {
  'members.profile': ['view', 'create'],
  'members.minor_contacts': ['view'],
  'calendar.events': ['view', 'create'],
  'calendar.attendance': ['view', 'change'],
  'announcements.posts': ['view', 'create', 'change'],
};

void main() {
  group('Members', () {
    testWidgets('list, status filter, bureau and a restricted profile', (
      tester,
    ) async {
      await setUpApp(tester);
      await pumpShell(
        tester,
        fakeMe(tabs: const ['accueil', 'membres'], permissions: _secretary),
      );
      await tester.tap(find.byKey(const Key('tab-membres')));
      await tester.pumpAndSettle();
      expect(find.text('Tous 4'), findsOneWidget);
      expect(find.text('Ewane Brice'), findsOneWidget);
      expect(
        find.text('EN CONGÉ'),
        findsOneWidget,
      ); // status chip, never colour alone

      await tester.ensureVisible(find.text('En congé 1'));
      await tester.tap(find.text('En congé 1'));
      await tester.pumpAndSettle();
      expect(find.text('Mbella Grâce'), findsOneWidget);
      expect(find.text('Ewane Brice'), findsNothing);

      await tester.ensureVisible(find.text('Tous 4'));
      await tester.tap(find.text('Tous 4'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Essomba Kévin'));
      await tester.tap(find.text('Essomba Kévin'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('contacts des membres mineurs'),
        findsOneWidget,
      );
      expect(
        find.textContaining('historique des contributions'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Retour'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bureau-row')));
      await tester.pumpAndSettle();
      expect(find.text('Président'), findsOneWidget);
    });

    testWidgets(
      'a minor needs a parent phone; the temporary PIN is shown once',
      (tester) async {
        final f = await setUpApp(tester);
        await pumpShell(
          tester,
          fakeMe(tabs: const ['accueil', 'membres'], permissions: _secretary),
        );
        await tester.tap(find.byKey(const Key('tab-membres')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('add-member')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('f-last')), 'Ndjock');
        await tester.enterText(find.byKey(const Key('f-first')), 'Patrick');
        await tester.enterText(find.byKey(const Key('f-phone')), '674583902');
        await tester.tap(find.byKey(const Key('f-birth')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).last, '03/03/2011');
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('f-parent-phone')), findsOneWidget);

        await tester.tap(find.byKey(const Key('save-member')));
        await tester.pumpAndSettle();
        expect(
          find.text('Ce champ est obligatoire pour un mineur.'),
          findsOneWidget,
        );
        expect(f.members.created, isEmpty);

        await tester.enterText(
          find.byKey(const Key('f-parent-phone')),
          '699120044',
        );
        await tester.tap(find.byKey(const Key('save-member')));
        await tester.pumpAndSettle();
        expect(f.members.created.single.parentPhone, '699120044');
        expect(find.textContaining('4821'), findsOneWidget);
      },
    );

    testWidgets('a plain member gets no add button', (tester) async {
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
      expect(find.byKey(const Key('add-member')), findsNothing);
    });
  });

  group('Calendar', () {
    testWidgets('agenda → detail → report an absence', (tester) async {
      final f = await setUpApp(tester);
      await pumpShell(tester, fakeMe(tabs: const ['accueil', 'calendrier']));
      await tester.tap(find.byKey(const Key('tab-calendrier')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('seg-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assise hebdomadaire'));
      await tester.pumpAndSettle();
      expect(find.text('Tenue intérieure'), findsOneWidget);
      expect(
        find.byKey(const Key('roll-call')),
        findsNothing,
      ); // members don't take the roll call
      await tester.tap(find.byKey(const Key('warn-absence')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('absence-reason')), 'Examen');
      await tester.tap(find.byKey(const Key('send-absence')));
      await tester.pumpAndSettle();
      expect(f.events.excused, [1]);
      expect(find.text('EXCUSÉ'), findsOneWidget);
    });

    testWidgets('a censor takes the roll call and saves it in one go', (
      tester,
    ) async {
      final f = await setUpApp(tester);
      await pumpShell(
        tester,
        fakeMe(tabs: const ['accueil', 'calendrier'], permissions: _secretary),
      );
      await tester.tap(find.byKey(const Key('tab-calendrier')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('seg-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assise hebdomadaire'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('roll-call')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('att-10-present')));
      await tester.tap(find.byKey(const Key('att-11-excuse')));
      await tester.pump();
      expect(find.text('2 modifications non enregistrées'), findsOneWidget);
      await tester.tap(find.byKey(const Key('save-attendance')));
      await tester.pumpAndSettle();
      expect(f.events.saved, {10: 'present', 11: 'excuse'});
    });
  });

  group('Announcements', () {
    testWidgets('unread dot clears after opening; badge on the tab', (
      tester,
    ) async {
      final f = await setUpApp(tester);
      await pumpShell(tester, fakeMe(tabs: const ['accueil', 'annonces']));
      await tester.tap(find.byKey(const Key('tab-annonces')));
      await tester.pumpAndSettle();
      expect(find.text('Non lues 1'), findsOneWidget);
      expect(find.text('Programme.pdf'), findsOneWidget);
      expect(find.text('PDF · 240 Ko'), findsOneWidget);
      await tester.tap(find.text('Répétition des chants'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Retour'));
      await tester.pumpAndSettle();
      expect(f.announcements.read, [1]);
      expect(find.text('Non lues 0'), findsOneWidget);
      expect(find.byKey(const Key('compose')), findsNothing);
    });

    testWidgets('a convocation must be linked to an event', (tester) async {
      final f = await setUpApp(tester);
      await pumpShell(
        tester,
        fakeMe(tabs: const ['accueil', 'annonces'], permissions: _secretary),
      );
      await tester.tap(find.byKey(const Key('tab-annonces')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('compose')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('seg-1')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('a-title')),
        'Assemblée générale',
      );
      await tester.tap(find.byKey(const Key('a-send')));
      await tester.pumpAndSettle();
      expect(
        find.text('Une convocation doit être liée à un événement.'),
        findsOneWidget,
      );
      expect(f.announcements.sent, isEmpty);
      await tester.tap(find.byKey(const Key('a-event')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pick-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('a-send')));
      await tester.pumpAndSettle();
      expect(f.announcements.sent, ['convocation:Assemblée générale:1']);
    });
  });

  testWidgets('home shows the next meeting and the latest announcement', (
    tester,
  ) async {
    await setUpApp(tester);
    await pumpShell(
      tester,
      fakeMe(tabs: const ['accueil', 'calendrier', 'annonces']),
    );
    expect(find.text('PROCHAIN RENDEZ-VOUS'), findsOneWidget);
    expect(find.text('Assise hebdomadaire'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Répétition des chants'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Répétition des chants'), findsOneWidget);
  });
}
