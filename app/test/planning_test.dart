import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'helpers.dart';

const _formateur = {
  'members.profile': ['view'],
  'calendar.events': ['view'],
  'calendar.attendance': ['view', 'change'],
  'calendar.planning': ['view', 'create', 'change'],
  'announcements.posts': ['view'],
};

final _vertical = find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;

Future<void> openThirdView(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('tab-calendrier')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('seg-2')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('member: Mes services → confirm, then swap with a colleague', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await pumpShell(tester, fakeMe(tabs: const ['accueil', 'calendrier']));
    expect(find.text('MON PROCHAIN SERVICE'), findsOneWidget); // on Accueil too
    await openThirdView(tester);
    expect(find.text('Mes services'), findsOneWidget);
    expect(find.text('Première centrale · Pariso'), findsOneWidget);
    expect(find.text('Chef : Din Yannick'), findsOneWidget);
    expect(find.byKey(const Key('you-are-chef')), findsOneWidget);
    await tester.tap(find.byKey(const Key('swap-1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('swap-reason')), 'Examen');
    await tester.tap(find.byKey(const Key('swap-to-30')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('swap-send')));
    await tester.pumpAndSettle();
    expect(f.planning.calls, contains('swap:1:30:Examen'));
    await tester.tap(find.byKey(const Key('confirm-1')));
    await tester.pumpAndSettle();
    expect(f.planning.calls, contains('confirm:1'));
    expect(find.text('CONFIRMÉ'), findsOneWidget);
  });

  testWidgets(
    'formateur: grid with alerts, assign a free slot with double-service warning, publish',
    (tester) async {
      final f = await setUpApp(tester);
      f.planning.doubleOnce = true;
      await pumpShell(
        tester,
        fakeMe(tabs: const ['accueil', 'calendrier'], permissions: _formateur),
      );
      await openThirdView(tester);
      expect(find.textContaining('2 alertes'), findsOneWidget);
      expect(
        find.textContaining('Essomba K. a deux services le même jour'),
        findsOneWidget,
      );
      expect(find.text('Grand-messe · 1/4'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('cell-5-premiere_centrale-yapoma-0')),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('En congé jusqu’au'),
        findsOneWidget,
      ); // on leave: locked, no assign button
      expect(find.byKey(const Key('assign-31')), findsNothing);
      await tester.tap(find.byKey(const Key('assign-30')));
      await tester.pumpAndSettle();
      expect(
        find.text('Bilong S. a déjà un service ce jour-là.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('force-assign')));
      await tester.pumpAndSettle();
      expect(
        f.planning.calls,
        contains('slot:premiere_centrale:yapoma:30:true'),
      );

      await tester.tap(find.byKey(const Key('publish')));
      await tester.pumpAndSettle();
      expect(find.text('Planning publié · 4 gardes notifiés.'), findsOneWidget);
    },
  );

  testWidgets('formateur: plan an event size and assign a whole group', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await pumpShell(
      tester,
      fakeMe(tabs: const ['accueil', 'calendrier'], permissions: _formateur),
    );
    await openThirdView(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('unplanned-60')),
      200,
      scrollable: _vertical,
    );
    await tester.ensureVisible(find.byKey(const Key('unplanned-60')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unplanned-60')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('size-6')));
    await tester.pumpAndSettle();
    expect(f.planning.calls, contains('size:60:6'));
    await tester.scrollUntilVisible(
      find.byKey(const Key('group-btn-5')),
      -200,
      scrollable: _vertical,
    );
    await tester.ensureVisible(find.byKey(const Key('group-btn-5')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group-btn-5')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group-1')));
    await tester.pumpAndSettle();
    expect(f.planning.calls, contains('group:5:1'));
  });

  testWidgets('formateur: changes the chef de groupe (any active member)', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await pumpShell(
      tester,
      fakeMe(tabs: const ['accueil', 'calendrier'], permissions: _formateur),
    );
    await openThirdView(tester);
    await tester.tap(find.byKey(const Key('chef-btn-5')));
    await tester.pumpAndSettle();
    // The member picker, active members only (the chef belongs to the
    // event, owner 2026-10-27): the one on leave isn't offered.
    expect(find.byKey(const Key('pick-member-2')), findsNothing);
    await tester.tap(find.byKey(const Key('pick-member-3')));
    await tester.pumpAndSettle();
    expect(f.planning.calls, contains('chef:5:3'));
  });

  testWidgets('member without lineup rights cannot change the chef', (
    tester,
  ) async {
    await setUpApp(tester);
    await pumpShell(
      tester,
      fakeMe(
        tabs: const ['accueil', 'calendrier'],
        permissions: const {
          'calendar.events': ['view'],
          'calendar.planning': ['view'],
        },
      ),
    );
    await openThirdView(tester);
    await tester.tap(find.byKey(const Key('chef-btn-5')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pick-member-3')), findsNothing);
  });

  testWidgets(
    'requests: accept a swap for me, fill an absence with a replacement',
    (tester) async {
      final f = await setUpApp(tester);
      await pumpShell(
        tester,
        fakeMe(tabs: const ['accueil', 'calendrier'], permissions: _formateur),
      );
      await openThirdView(tester);
      await tester.tap(find.byKey(const Key('open-requests')));
      await tester.pumpAndSettle();
      expect(find.text('Essomba K. vous propose son service'), findsOneWidget);
      await tester.tap(find.byKey(const Key('accept-7')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('approve-8')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('repl-30')));
      await tester.pumpAndSettle();
      expect(
        f.planning.calls,
        containsAll(['answer:7:true', 'decide:8:true:30']),
      );
    },
  );

  testWidgets('albs: steps, advance, fairness', (tester) async {
    final f = await setUpApp(tester);
    await pumpShell(
      tester,
      fakeMe(tabs: const ['accueil', 'calendrier'], permissions: _formateur),
    );
    await openThirdView(tester);
    await tester.tap(find.byKey(const Key('open-albs')));
    await tester.pumpAndSettle();
    expect(find.text('Marquer « lavées »'), findsOneWidget);
    expect(find.text('ÉQUITÉ · LAVAGES SUR 12 MOIS'), findsOneWidget);
    await tester.tap(find.byKey(const Key('alb-advance')));
    await tester.pumpAndSettle();
    expect(f.planning.calls, contains('alb:1'));
    expect(find.text('Marquer « rendues »'), findsOneWidget);
  });

  testWidgets('notifications: bell dot, grouped list, read all', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await pumpShell(tester, fakeMe());
    expect(find.byKey(const Key('bell-dot')), findsOneWidget);
    await tester.tap(find.byKey(const Key('bell')));
    await tester.pumpAndSettle();
    expect(find.text('AUJOURD’HUI'), findsOneWidget);
    expect(find.text('CETTE SEMAINE'), findsOneWidget);
    await tester.tap(find.byKey(const Key('read-all')));
    await tester.pumpAndSettle();
    expect(f.notifications.allRead, isTrue);
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bell-dot')), findsNothing);
  });

  // --- Design features added 2026-10-27 -------------------------------------------

  testWidgets('formateur: hold a name and drag it to a free cell', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await pumpShell(
      tester,
      fakeMe(tabs: const ['accueil', 'calendrier'], permissions: _formateur),
    );
    await openThirdView(tester);
    expect(find.byKey(const Key('drag-hint')), findsOneWidget);
    final from = find.byKey(const Key('cell-5-premiere_centrale-pariso-0'));
    final to = find.byKey(const Key('cell-5-deuxieme_centrale-pariso-0'));
    await tester.ensureVisible(from);
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(tester.getCenter(from));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveTo(tester.getCenter(to));
    await tester.pump();
    expect(find.text('Déposer ici'), findsOneWidget); // the target lights up
    await gesture.up();
    await tester.pumpAndSettle();
    expect(f.planning.calls, contains('move:1:5:deuxieme_centrale:pariso'));
  });

  testWidgets('formateur: leave end date, group sheet, Brouillon', (
    tester,
  ) async {
    await setUpApp(tester);
    await pumpShell(
      tester,
      fakeMe(tabs: const ['accueil', 'calendrier'], permissions: _formateur),
    );
    await openThirdView(tester);
    await tester.tap(find.byKey(const Key('group-btn-5')));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 en congé'), findsOneWidget);
    expect(find.textContaining('Grand-messe · 4 postes'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10)); // close the sheet
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('keep-draft')));
    await tester.pump();
    expect(
      find.text(
        'Brouillon : personne n’est notifié tant que vous ne publiez pas.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('member: the swap sheet says who validates; a chef reaches '
      'the requests', (tester) async {
    await setUpApp(tester);
    await pumpShell(tester, fakeMe(tabs: const ['accueil', 'calendrier']));
    await openThirdView(tester);
    expect(find.byKey(const Key('chef-requests')), findsOneWidget);
    await tester.tap(find.byKey(const Key('swap-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('swap-validation')), findsOneWidget);
    expect(find.textContaining('ce mois'), findsWidgets);
  });
}
