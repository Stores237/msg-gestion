import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/models/me.dart';
import 'package:msg_gestion/screens/finances/finance_gate.dart';
import 'package:msg_gestion/widgets/pin_pad.dart';

import 'fakes.dart';
import 'helpers.dart';

/// Finance code (owner, 2026-10-30): when the group requires it, Finances
/// opens only after a second code, chosen with the PIN.
const _perms = {
  'finances.cashbook': ['view', 'create', 'validate', 'export'],
};

Me _me({bool required = true, bool set = false}) {
  final base = fakeMe(tabs: const ['accueil', 'finances'], permissions: _perms);
  return Me(
    id: base.id,
    firstName: base.firstName,
    lastName: base.lastName,
    fullName: base.fullName,
    status: base.status,
    isDiaspora: base.isDiaspora,
    age: base.age,
    roles: base.roles,
    permissions: base.permissions,
    tabs: base.tabs,
    group: GroupInfo(id: 1, name: 'MSG', financeCodeRequired: required),
    financeCodeSet: set,
  );
}

Future<void> _openFinances(WidgetTester tester, Me me) async {
  FinanceGate.lock();
  await pumpShell(tester, me);
  await tester.tap(find.byKey(const Key('tab-finances')));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String code) async {
  for (final d in code.split('')) {
    await tester.tap(
      find.descendant(of: find.byType(PinKeypad), matching: find.text(d)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('not required: Finances opens straight away', (tester) async {
    await setUpApp(tester);
    await _openFinances(tester, _me(required: false));
    expect(find.byKey(const Key('finance-gate')), findsNothing);
    expect(find.byKey(const Key('balance')), findsOneWidget);
  });

  testWidgets('first time: choose the code with the PIN, then it opens', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await _openFinances(tester, _me());
    expect(find.byKey(const Key('finance-code-choose')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('fc-pin')), '4821');
    await tester.enterText(find.byKey(const Key('fc-code')), '7395');
    await tester.enterText(find.byKey(const Key('fc-again')), '7396');
    await tester.tap(find.byKey(const Key('fc-save')));
    await tester.pumpAndSettle();
    expect(find.text('Les deux codes ne correspondent pas.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('fc-again')), '7395');
    await tester.tap(find.byKey(const Key('fc-save')));
    await tester.pumpAndSettle();
    expect(f.auth.financeCode, '7395');
    expect(find.byKey(const Key('balance')), findsOneWidget);
  });

  testWidgets('code asked; a wrong one is refused, the right one opens', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    f.auth.financeCode = '7395';
    await _openFinances(tester, _me(set: true));
    expect(find.byKey(const Key('finance-gate')), findsOneWidget);
    expect(find.byKey(const Key('balance')), findsNothing);
    await _type(tester, '1357');
    expect(find.textContaining('Code finances incorrect'), findsOneWidget);
    await _type(tester, '7395');
    expect(find.byKey(const Key('balance')), findsOneWidget);
    // Open for a while: back on the tab, no code.
    await tester.tap(find.byKey(const Key('tab-accueil')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab-finances')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('finance-gate')), findsNothing);
    expect(f.auth.financeChecks, 2);
  });

  testWidgets('Accueil hides the balance until the code is given', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    f.auth.financeCode = '7395';
    FinanceGate.lock();
    await pumpShell(tester, _me(set: true));
    expect(find.text('Solde de la caisse'), findsNothing);
    await tester.tap(find.byKey(const Key('tab-finances')));
    await tester.pumpAndSettle();
    await _type(tester, '7395');
    await tester.tap(find.byKey(const Key('tab-accueil')));
    await tester.pumpAndSettle();
    expect(find.text('Solde de la caisse'), findsOneWidget);
  });
}
