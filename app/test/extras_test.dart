import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/data/repositories/profile_repository.dart';
import 'package:msg_gestion/data/repository_locator.dart';

import 'fakes.dart';
import 'helpers.dart';

final _vertical = find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;

void main() {
  testWidgets('event detail: reminder switches save the preference', (
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
    await tester.scrollUntilVisible(
      find.byKey(const Key('remind-2h')),
      100,
      scrollable: _vertical,
    );
    await tester.tap(find.byKey(const Key('remind-2h')));
    await tester.pumpAndSettle();
    final profile = RepositoryLocator.instance.profile as FakeProfileRepository;
    expect(profile.reminders, ['eve=null 2h=true']);
  });

  testWidgets('profile: attendance summary and propose a role', (tester) async {
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
    expect(find.byKey(const Key('call')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('propose-role')),
      100,
      scrollable: _vertical,
    );
    await tester.tap(find.byKey(const Key('propose-role')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('propose-role-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Censeur du jour').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('propose-reason')),
      'Grande veillée',
    );
    await tester.tap(find.byKey(const Key('propose-send')));
    await tester.pumpAndSettle();
    expect(f.members.roleRequests, ['1:censeur-du-jour:Grande veillée']);
    expect(find.text('Demande envoyée au super admin.'), findsOneWidget);
  });

  testWidgets('finances: export the cash book as PDF', (tester) async {
    final f = await setUpApp(tester);
    await pumpShell(
      tester,
      fakeMe(
        tabs: const ['accueil', 'finances'],
        permissions: const {
          'finances.cashbook': ['view', 'export'],
        },
      ),
    );
    await tester.tap(find.byKey(const Key('tab-finances')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('export-cashbook')));
    await tester.pumpAndSettle();
    expect(f.finances.exports, ['cashbook']);
  });

  testWidgets('profile: one member\'s financial statement', (tester) async {
    final f = await setUpApp(tester);
    await pumpShell(
      tester,
      fakeMe(
        tabs: const ['accueil', 'membres'],
        permissions: const {
          'members.profile': ['view'],
          'finances.cashbook': ['view', 'export'],
        },
      ),
    );
    await tester.tap(find.byKey(const Key('tab-membres')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ewane Brice'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('member-statement')),
      100,
      scrollable: _vertical,
    );
    await tester.tap(find.byKey(const Key('member-statement')));
    await tester.pumpAndSettle();
    expect(f.finances.exports.single, startsWith('statement:'));
  });

  testWidgets('finances: download the members\' balance statement', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await pumpShell(
      tester,
      fakeMe(
        tabs: const ['accueil', 'finances'],
        permissions: const {
          'finances.cashbook': ['view', 'export'],
        },
      ),
    );
    await tester.tap(find.byKey(const Key('tab-finances')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('new-entry')), findsNothing);
    await tester.tap(find.byKey(const Key('export-statement')));
    await tester.pumpAndSettle();
    expect(f.finances.exports, ['statement']);
  });

  testWidgets('Accueil: À suivre for the bureau', (tester) async {
    await setUpApp(tester);
    (RepositoryLocator.instance.profile as FakeProfileRepository).bureau =
        BureauHome(
          membersActive: 41,
          toValidate: 3,
          collections: const [(7, 'Décès · famille Nkotto', 27, 41)],
          unfilled: [('Grand-messe', DateTime(2026, 10, 25, 9), 2)],
        );
    await pumpShell(tester, fakeMe());
    expect(find.text('À SUIVRE'), findsOneWidget);
    expect(find.text('3 opérations à valider'), findsOneWidget);
    expect(find.text('2 postes non pourvus · Grand-messe'), findsOneWidget);
    expect(find.text('27 sur 41 ont tout payé'), findsOneWidget);
  });
}
