import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'downloads_test.dart' show openFinances;
import 'helpers.dart';

/// Cash book (owner, 2026-10-30): the trésorier's Modifier and Valider are
/// on each line waiting for him; lines are grouped by day, type, status or
/// member; a line shows its member and amount on one line, the category
/// below, without repeating it.
const _validates = {
  'members.profile': ['view'],
  'finances.cashbook': ['view', 'validate', 'export'],
};
const _views = {
  'finances.cashbook': ['view'],
};

void main() {
  testWidgets('the trésorier edits straight from the line', (tester) async {
    final f = await setUpApp(tester);
    await openFinances(tester, _validates);
    expect(find.byKey(const Key('edit-1')), findsOneWidget);
    expect(find.byKey(const Key('validate-1')), findsOneWidget);
    // Validated: nothing to do.
    expect(find.byKey(const Key('edit-2')), findsNothing);
    await tester.tap(find.byKey(const Key('edit-1')));
    await tester.pumpAndSettle();
    expect(find.text('Modifier l’opération'), findsOneWidget);
    await tester.tap(find.byKey(const Key('quick-3000')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('e-save')));
    await tester.tap(find.byKey(const Key('e-save')));
    await tester.pumpAndSettle();
    expect(f.finances.edits.single.$2.amount, 3000);
  });

  testWidgets('a member sees no actions; the line says who, then what', (
    tester,
  ) async {
    await setUpApp(tester);
    await openFinances(tester, _views);
    expect(find.byKey(const Key('edit-1')), findsNothing);
    expect(find.byKey(const Key('validate-1')), findsNothing);
    expect(find.text('Essomba Kévin'), findsOneWidget);
    expect(
      find.text('Contributions de solidarité · Décès · Nkotto'),
      findsOneWidget,
    );
  });

  testWidgets('grouped by day, type, status, member; a group folds', (
    tester,
  ) async {
    await setUpApp(tester);
    await openFinances(tester, _views);
    await tester.ensureVisible(find.byKey(const Key('group-by-day')));
    await tester.tap(find.byKey(const Key('group-by-day')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group-day-2026-10-19')), findsOneWidget);
    expect(find.byKey(const Key('group-day-2026-10-17')), findsOneWidget);
    expect(find.text('Lundi 19 octobre 2026'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('group-by-type')));

    await tester.tap(find.byKey(const Key('group-by-type')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group-type-solidarite')), findsOneWidget);
    expect(find.byKey(const Key('group-type-depense')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('group-by-status')));

    await tester.tap(find.byKey(const Key('group-by-status')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group-status-pending')), findsOneWidget);
    expect(find.byKey(const Key('group-status-validated')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('group-by-member')));

    await tester.tap(find.byKey(const Key('group-by-member')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group-member-4')), findsOneWidget);
    expect(find.byKey(const Key('group-member-0')), findsOneWidget);
    expect(find.text('Sans membre'), findsOneWidget);

    await tester.tap(find.byKey(const Key('group-member-4')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('entry-1')), findsNothing);
    expect(find.byKey(const Key('entry-2')), findsOneWidget);
    await tester.tap(find.byKey(const Key('group-member-4')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('entry-1')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('group-by-day')));
    await tester.tap(find.byKey(const Key('group-by-day')));
    await tester.pumpAndSettle();
  });
}
