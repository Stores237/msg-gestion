import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huddle/data/group_controller.dart';
import 'package:huddle/main.dart';
import 'package:huddle/screens/group_screens.dart';
import 'package:huddle/screens/splash_screen.dart';
import 'package:huddle/widgets/group_logo.dart';
import 'package:huddle/widgets/huddle_logo.dart';

import 'fakes.dart';
import 'helpers.dart';

/// Huddle (owner, 2026-11-02): the app is Huddle, like Slack; each group
/// shows its own name and logo inside, and is picked after signing in.
const _two = [
  {
    'id': 1,
    'name': 'Mouvement Garde Suisse',
    'initials': 'MSG',
    'color': '#2E7D46',
  },
  {
    'id': 2,
    'name': 'Chorale Sainte-Cécile',
    'initials': 'CSC',
    'logo': 'https://x/csc.png',
  },
];

void main() {
  testWidgets('several groups and none chosen: pick one, remembered', (
    tester,
  ) async {
    final f = await setUpApp(tester, me: fakeMe(groups: _two));
    await tester.pumpWidget(
      MsgApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                chooseGroupIfNeeded(Navigator.of(context), f.profile.me),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group-pick')), findsOneWidget);
    expect(find.byType(HuddleMark), findsOneWidget);
    // Initials for a group without a logo; the logo image for the other.
    expect(find.byKey(const Key('group-initials-1')), findsOneWidget);
    expect(find.text('MSG'), findsOneWidget);
    await tester.tap(find.byKey(const Key('pick-group-2')));
    await tester.pumpAndSettle();
    expect(GroupController.instance.id, 2);
  });

  testWidgets('one group: straight in, and it is remembered', (tester) async {
    final f = await setUpApp(tester);
    await tester.pumpWidget(
      MsgApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                chooseGroupIfNeeded(Navigator.of(context), f.profile.me),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group-pick')), findsNothing);
    expect(GroupController.instance.id, 1);
  });

  testWidgets('Accueil shows the group: logo (or sigle) and name', (
    tester,
  ) async {
    await setUpApp(tester);
    await pumpShell(tester, fakeMe());
    expect(find.byKey(const Key('home-group-name')), findsOneWidget);
    expect(find.text('Mouvement Garde Suisse'), findsWidgets);
    expect(find.byType(GroupLogo), findsWidgets);
    // A plain member in one group: nothing to switch, nothing to edit.
    expect(find.byKey(const Key('switch-group')), findsNothing);
  });

  testWidgets('the président renames the group and sets its sigle', (
    tester,
  ) async {
    final me = fakeMe(
      permissions: const {
        'calendar.events': ['view'],
        'announcements.posts': ['view'],
        'group.profile': ['change'],
      },
    );
    final f = await setUpApp(tester, me: me);
    await pumpShell(tester, me);
    await tester.tap(find.byKey(const Key('switch-group')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-group')));
    await tester.pumpAndSettle();
    expect(find.text('Nom et logo du groupe'), findsWidgets);
    await tester.enterText(find.byKey(const Key('group-name')), ' ');
    await tester.tap(find.byKey(const Key('group-save')));
    await tester.pumpAndSettle();
    expect(find.text('Le nom du groupe est obligatoire.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('group-name')), 'Garde Suisse');
    await tester.enterText(find.byKey(const Key('group-short')), 'GSY');
    await tester.tap(find.byKey(const Key('group-save')));
    await tester.pumpAndSettle();
    expect(f.profile.groupCalls, ['update:Garde Suisse:GSY']);
  });

  testWidgets('the opening screen is Huddle, not a group', (tester) async {
    await setUpApp(tester);
    await tester.pumpWidget(const MsgApp(home: SplashScreen()));
    await tester.pump();
    expect(find.byType(HuddleMark), findsOneWidget);
    expect(find.text('huddle'), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
