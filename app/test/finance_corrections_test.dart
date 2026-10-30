import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/models/finance.dart';

import 'downloads_test.dart' show openFinances;
import 'helpers.dart';

/// Finance corrections (owner, 2026-10-30): money in needs members, ticked
/// with "Tout cocher" (one line each); "Autre" needs a description; the
/// trésorier edits a line before validating; the commissaire finalises.
const _enters = {
  'members.profile': ['view'],
  'finances.cashbook': ['view', 'create', 'export'],
  'finances.solidarity': ['view', 'create', 'export'],
};
const _validates = {
  'members.profile': ['view'],
  'finances.cashbook': ['view', 'validate', 'export'],
};

void main() {
  testWidgets('money in: members required, Tout cocher, Autre described', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await openFinances(tester, _enters);
    await tester.tap(find.byKey(const Key('new-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quick-3000')));
    await tester.pump();

    // "Autre" without a description and without a member: both said.
    await tester.tap(find.byKey(const Key('e-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Autre').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('e-save')));
    await tester.tap(find.byKey(const Key('e-save')));
    await tester.pumpAndSettle();
    expect(find.text('Décrivez l’opération.'), findsOneWidget);
    expect(find.byKey(const Key('e-member-error')), findsOneWidget);
    expect(f.finances.created, isEmpty);

    await tester.enterText(
      find.byKey(const Key('e-label')),
      'Vente de calendriers',
    );
    await tester.ensureVisible(find.byKey(const Key('e-member')));
    await tester.tap(find.byKey(const Key('e-member')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('check-all')));
    await tester.pump();
    final everyone = f.members.members.length;
    await tester.tap(find.byKey(const Key('members-done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('e-per-member')), findsOneWidget);
    expect(find.textContaining('$everyone membres ×'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('e-save')));
    await tester.tap(find.byKey(const Key('e-save')));
    await tester.pumpAndSettle();
    final e = f.finances.created.single;
    expect(
      (e.category, e.label, e.amount),
      ('autre', 'Vente de calendriers', 3000),
    );
    expect(e.memberIds, hasLength(everyone));
    expect(e.toJson()['members'], hasLength(everyone));
  });

  testWidgets('the validator edits a line, then it is marked Modifié', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await openFinances(tester, _validates);
    await tester.tap(find.byKey(const Key('entry-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-entry')));
    await tester.pumpAndSettle();
    expect(find.text('Modifier l’opération'), findsOneWidget);
    // Prefilled with the line.
    expect(find.text('2500'), findsOneWidget);
    await tester.tap(find.byKey(const Key('quick-3000')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('e-save')));
    await tester.tap(find.byKey(const Key('e-save')));
    await tester.pumpAndSettle();
    final (id, changes) = f.finances.edits.single;
    expect((id, changes.amount), (1, 3000));
    expect(find.byKey(const Key('edited-1')), findsOneWidget);
    expect(find.textContaining('modifié par Moi'), findsOneWidget);
  });

  testWidgets('the commissaire finalises or sends back an edited line', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    f.finances.items = [
      FinanceEntry(
        id: 9,
        direction: 'in',
        amount: 3000,
        category: 'solidarite',
        label: 'Décès',
        memberName: 'Essomba Kévin',
        date: DateTime(2026, 10, 20),
        status: 'to_confirm',
        createdByName: 'Moi',
        createdAt: DateTime(2026, 10, 20, 9),
        validatedByName: 'Tchoumi A.',
        editedByName: 'Tchoumi A.',
      ),
      ...f.finances.items,
    ];
    await openFinances(tester, _enters);
    expect(find.byKey(const Key('to-confirm-9')), findsOneWidget);
    await tester.tap(find.byKey(const Key('entry-9')));
    await tester.pumpAndSettle();
    expect(find.text('Finaliser l’opération ?'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('send-back-reason')),
      'Reçu de 2 500',
    );
    await tester.tap(find.byKey(const Key('send-back')));
    await tester.pumpAndSettle();
    expect(f.finances.confirms.single, (9, false, 'Reçu de 2 500'));
    expect(find.text('Opération renvoyée au trésorier.'), findsOneWidget);
  });

  testWidgets('collection: Tout cocher ticks everyone who still owes', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await openFinances(tester, _enters);
    await tester.tap(find.text('Solidarité'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('collection-7')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('check-all')), findsOneWidget);
    await tester.tap(find.byKey(const Key('check-all')));
    await tester.pump();
    expect(find.textContaining('Enregistrer 2 paiements'), findsOneWidget);
    // Tapped again: everything unticked.
    await tester.tap(find.byKey(const Key('check-all')));
    await tester.pump();
    expect(find.textContaining('Enregistrer 2 paiements'), findsNothing);
    await tester.tap(find.byKey(const Key('check-all')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-payments')));
    await tester.pumpAndSettle();
    expect(f.finances.paid, {22: 833, 23: 834});
  });
}
