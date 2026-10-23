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
        find.text('En congé'),
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

  testWidgets('formateur: designates the chef de groupe among the guards', (
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
    expect(find.text('Désigner le chef de groupe'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chef-4')));
    await tester.pumpAndSettle();
    expect(f.planning.calls, contains('chef:5:4'));
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
    expect(find.text('Désigner le chef de groupe'), findsNothing);
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
}
