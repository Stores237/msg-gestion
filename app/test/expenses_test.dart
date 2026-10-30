import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/screens/expenses/expenses_screen.dart';

import 'fakes.dart';
import 'helpers.dart';

/// Expense requests (owner, 2026-10-30): any member asks from Accueil; the
/// lead approves; the commissaire; the trésorier pays with the proof.
Future<void> _openFromHome(WidgetTester tester) async {
  await pumpShell(tester, fakeMe(tabs: const ['accueil']));
  await tester.scrollUntilVisible(
    find.byKey(const Key('home-expenses')),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.byKey(const Key('home-expenses')));
  await tester.pumpAndSettle();
}

Future<void> _openDetail(WidgetTester tester, int id) async {
  await pumpShell(tester, fakeMe(tabs: const ['accueil']));
  final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
  nav.push(
    MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expenseId: id)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a member asks from Accueil, tagging a coordinator', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await _openFromHome(tester);
    expect(find.text('Demandes de dépense'), findsOneWidget);
    expect(find.byKey(const Key('expense-31')), findsOneWidget);
    expect(find.text('CHEZ LE RESPONSABLE'), findsOneWidget);

    await tester.tap(find.byKey(const Key('new-expense')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exp-send')));
    await tester.pumpAndSettle();
    expect(find.text('Choisissez le domaine.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exp-domain')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Formation').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Approuvée d’abord par : Formateur'), findsOne);
    await tester.enterText(find.byKey(const Key('exp-title')), 'Papier');
    await tester.enterText(find.byKey(const Key('exp-amount')), '5000');
    await tester.tap(find.byKey(const Key('exp-tag')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pick-many-4')));
    await tester.tap(find.byKey(const Key('members-done')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('exp-send')));
    await tester.tap(find.byKey(const Key('exp-send')));
    await tester.pumpAndSettle();
    expect(f.finances.expenseCalls, contains('new:Papier:5000:4:null'));
    // The new request opens.
    expect(find.text('Demande de dépense'), findsOneWidget);
  });

  testWidgets('the lead approves; refusing asks a reason', (tester) async {
    final f = await setUpApp(tester);
    f.finances.expenseActions = const ['decide'];
    await _openDetail(tester, 31);
    await tester.tap(find.byKey(const Key('exp-refuse')));
    await tester.pumpAndSettle();
    // No reason: the dialog stays.
    await tester.tap(find.byKey(const Key('exp-reason-ok')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exp-reason')), findsOneWidget);
    await tester.tap(find.text('Annuler').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('exp-approve')));
    await tester.pumpAndSettle();
    expect(f.finances.expenseCalls.last, 'decide:31:true:');
    expect(find.text('CHEZ LE COMMISSAIRE'), findsOneWidget);
    expect(find.byKey(const Key('exp-approve')), findsNothing);
  });

  testWidgets('pay: at most the approved amount, the proof required', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    f.finances.expenseActions = const ['pay'];
    await _openDetail(tester, 31);
    await tester.tap(find.byKey(const Key('exp-pay')));
    await tester.pumpAndSettle();
    expect(find.text('Montant approuvé : 5 000 FCFA'), findsNothing);
    await tester.enterText(find.byKey(const Key('pay-amount')), '6000');
    await tester.tap(find.byKey(const Key('pay-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pay-error')), findsOneWidget);
    expect(find.textContaining('Le montant payé va de 1 à'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('pay-amount')), '4800');
    await tester.tap(find.byKey(const Key('pay-save')));
    await tester.pumpAndSettle();
    expect(find.text('Joignez la capture de la transaction.'), findsOneWidget);
    expect(f.finances.expenseCalls.where((c) => c.startsWith('pay')), isEmpty);
  });

  testWidgets('cancel with a reason, then ask again; the thread', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await _openDetail(tester, 31);
    await tester.enterText(find.byKey(const Key('exp-message')), 'Devis ?');
    await tester.tap(find.byKey(const Key('exp-send-message')));
    await tester.pumpAndSettle();
    expect(f.finances.expenseCalls.last, 'message:31:Devis ?');
    expect(find.text('Devis ?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exp-cancel')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('exp-reason')), '4 800');
    await tester.tap(find.byKey(const Key('exp-reason-ok')));
    await tester.pumpAndSettle();
    expect(find.text('ANNULÉE'), findsOneWidget);
    await tester.tap(find.byKey(const Key('exp-resubmit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exp-replaces')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('exp-amount')), '4800');
    await tester.ensureVisible(find.byKey(const Key('exp-send')));
    await tester.tap(find.byKey(const Key('exp-send')));
    await tester.pumpAndSettle();
    expect(f.finances.expenseCalls.last, startsWith('new:'));
    expect(f.finances.expenseCalls.last, endsWith(':4800::31'));
  });

  testWidgets('steps: done up to where it waits', (tester) async {
    final f = await setUpApp(tester);
    f.finances.expenseActions = const ['decide'];
    await _openDetail(tester, 31);
    await tester.tap(find.byKey(const Key('exp-approve')));
    await tester.pumpAndSettle();
    Icon icon(int i) => tester.widget<Icon>(
      find.descendant(
        of: find.byKey(Key('exp-step-$i')),
        matching: find.byType(Icon),
      ),
    );
    // With the commissaire: request and lead done, commissaire current.
    expect(icon(1).icon, Icons.check_circle);
    expect(icon(2).icon, Icons.radio_button_checked);
    expect(icon(3).icon, Icons.radio_button_unchecked);
  });
}
