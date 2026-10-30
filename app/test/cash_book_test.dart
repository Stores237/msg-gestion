import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/models/finance.dart';

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
    final f = await setUpApp(tester);
    f.finances.readOnly();
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

  testWidgets('long press picks lines; validate them at once', (tester) async {
    final f = await setUpApp(tester);
    f.finances.items = [
      ...f.finances.items,
      FinanceEntry(
        id: 3,
        direction: 'in',
        amount: 500,
        category: 'inscription',
        label: 'Inscription',
        memberId: 5,
        memberName: 'Mbella Grâce',
        date: DateTime(2026, 10, 19),
        status: 'pending',
        createdByName: 'Fotso I.',
        createdAt: DateTime(2026, 10, 19, 11),
        canApprove: true,
        canEdit: true,
      ),
    ];
    await openFinances(tester, {
      ..._validates,
      'finances.cashbook': ['view', 'create', 'validate', 'export'],
    });
    await tester.tap(find.byKey(const Key('group-by-day')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('long-press-hint')), findsOneWidget);
    expect(find.byKey(const Key('new-entry')), findsOneWidget);

    await tester.longPress(find.byKey(const Key('entry-1')));
    await tester.pumpAndSettle();
    expect(find.text('1 sélectionnée'), findsOneWidget);
    // Picking hides the "+ Opération" button and the line buttons.
    expect(find.byKey(const Key('new-entry')), findsNothing);
    expect(find.byKey(const Key('validate-3')), findsNothing);
    // A validated line can't be picked.
    expect(find.byKey(const Key('pick-2')), findsNothing);

    await tester.tap(find.byKey(const Key('pick-all')));
    await tester.pumpAndSettle();
    expect(find.text('2 sélectionnées'), findsOneWidget);
    await tester.tap(find.byKey(const Key('entry-3')));
    await tester.pumpAndSettle();
    expect(find.text('1 sélectionnée'), findsOneWidget);
    await tester.tap(find.byKey(const Key('entry-3')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('validate-selected')));
    await tester.pumpAndSettle();
    expect(find.text('Valider 2 opérations ?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('validate-many-confirm')));
    await tester.pumpAndSettle();
    expect(f.finances.validated..sort(), [1, 3]);
    expect(find.text('2 opérations validées.'), findsOneWidget);
    expect(find.byKey(const Key('validate-selected')), findsNothing);
    expect(find.byKey(const Key('new-entry')), findsOneWidget);
  });

  testWidgets('picking can be cancelled', (tester) async {
    await setUpApp(tester);
    await openFinances(tester, _validates);
    await tester.longPress(find.byKey(const Key('entry-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pick-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('pick-cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pick-1')), findsNothing);
    expect(find.byKey(const Key('validate-1')), findsOneWidget);
  });
}
