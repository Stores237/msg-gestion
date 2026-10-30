import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/models/planning.dart';

import 'fakes.dart';
import 'helpers.dart';
import 'planning_test.dart' show openThirdView;

/// Planning, owner 2026-10-30: published lineups go below the drafts and can
/// be reused; a lineup whose date has passed can't be published.
const _formateur = {
  'calendar.events': ['view'],
  'calendar.planning': ['view', 'create', 'change'],
};

Future<void> _scrollTo(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(
    find.byKey(key),
    200,
    scrollable: find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first,
  );
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('published lineup goes below the drafts and is reused', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await pumpShell(
      tester,
      fakeMe(tabs: const ['accueil', 'calendrier'], permissions: _formateur),
    );
    await openThirdView(tester);
    expect(find.byKey(const Key('published-section')), findsNothing);
    expect(find.byKey(const Key('reuse-5')), findsNothing);

    await tester.tap(find.byKey(const Key('publish')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('published-section')), findsOneWidget);
    expect(find.text('Publié'), findsOneWidget); // the bottom bar

    await _scrollTo(tester, const Key('reuse-5'));
    await tester.tap(find.byKey(const Key('reuse-5')));
    await tester.pumpAndSettle();
    expect(find.text('Réutiliser ce planning pour…'), findsOneWidget);
    await tester.tap(find.byKey(const Key('reuse-target-70')));
    await tester.pumpAndSettle();
    expect(f.planning.calls, contains('reuse:5:70'));
    expect(
      find.textContaining('Planning repris pour Messe du dimanche'),
      findsOneWidget,
    );
    expect(find.textContaining('Mbella G.'), findsOneWidget);
  });

  testWidgets('a draft whose date has passed is flagged and not published', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    f.planning.extra = [
      PlannedService(
        id: 6,
        eventId: 51,
        title: 'Messe de la veille',
        startsAt: yesterday,
        size: 2,
        published: false,
        past: true,
        slots: const [
          Slot('premiere_centrale', 'pariso', 0),
          Slot('premiere_centrale', 'yapoma', 0),
        ],
        assignments: const [],
      ),
    ];
    await pumpShell(
      tester,
      fakeMe(tabs: const ['accueil', 'calendrier'], permissions: _formateur),
    );
    await openThirdView(tester);
    expect(find.byKey(const Key('past-drafts-notice')), findsOneWidget);
    expect(find.byKey(const Key('past-6')), findsOneWidget);
    // The upcoming draft can still be published…
    await tester.tap(find.byKey(const Key('publish')));
    await tester.pumpAndSettle();
    // …then only the past one is left: nothing to publish, and why.
    expect(find.byKey(const Key('publish')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('nothing-to-publish')),
        matching: find.text('Date passée'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('drafts-section')), findsOneWidget);
    await _scrollTo(tester, const Key('published-section'));
  });
}
