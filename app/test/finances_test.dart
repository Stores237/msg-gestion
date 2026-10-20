import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'helpers.dart';

const _treasurer = {
  'members.profile': ['view'],
  'finances.cashbook': ['view', 'create', 'change', 'export'],
  'finances.solidarity': ['view', 'create', 'change', 'export'],
  'finances.report': ['view', 'export'],
};
const _auditor = {
  'members.profile': ['view'],
  'finances.cashbook': ['view', 'validate', 'export'],
  'finances.solidarity': ['view', 'validate'],
  'finances.report': ['view', 'validate', 'export'],
};

Future<void> openFinances(
  WidgetTester tester,
  Map<String, dynamic> perms,
) async {
  await pumpShell(
    tester,
    fakeMe(tabs: const ['accueil', 'finances'], permissions: perms),
  );
  await tester.tap(find.byKey(const Key('tab-finances')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'treasurer: balance, cash book trail, new entry with a quick amount',
    (tester) async {
      final f = await setUpApp(tester);
      await openFinances(tester, _treasurer);
      expect(find.textContaining('186', findRichText: true), findsWidgets);
      expect(find.textContaining('Saisi par Fotso I.'), findsWidgets);
      expect(find.textContaining('Validé par Tchoumi A.'), findsOneWidget);
      expect(find.text('À VALIDER'), findsOneWidget);

      await tester.tap(find.byKey(const Key('new-entry')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('e-save')));
      await tester.pumpAndSettle();
      expect(find.text('Indiquez un montant.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('quick-3000')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('e-member')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pick-member-4')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('e-save')));
      await tester.pumpAndSettle();
      final e = f.finances.created.single;
      expect(
        (e.direction, e.amount, e.category, e.memberId),
        ('in', 3000, 'solidarite', 4),
      );
      expect(
        e.clientUuid,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    },
  );

  testWidgets(
    'treasurer cannot validate; auditor validates with confirmation',
    (tester) async {
      await setUpApp(tester);
      await openFinances(tester, _treasurer);
      await tester.tap(find.byKey(const Key('entry-1')));
      await tester.pumpAndSettle();
      expect(find.text('Valider cette opération ?'), findsNothing);
    },
  );

  testWidgets('auditor validates an entry', (tester) async {
    final f = await setUpApp(tester);
    await openFinances(tester, _auditor);
    expect(find.byKey(const Key('new-entry')), findsNothing);
    await tester.tap(find.byKey(const Key('entry-1')));
    await tester.pumpAndSettle();
    expect(find.text('Valider cette opération ?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('validate-confirm')));
    await tester.pumpAndSettle();
    expect(f.finances.validated, [1]);
  });

  testWidgets('solidarity: tick members, save their next instalment', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await openFinances(tester, _treasurer);
    await tester.tap(find.text('Solidarité'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('collection-7')));
    await tester.pumpAndSettle();
    expect(find.text('1 sur 3 ont tout payé'), findsOneWidget);
    expect(
      find.text('Ateba Sandrine'),
      findsNothing,
    ); // "À payer" filter hides those who paid
    await tester.tap(find.byKey(const Key('pay-22')));
    await tester.tap(find.byKey(const Key('pay-23')));
    await tester.pump();
    expect(
      find.textContaining('Enregistrer 2 paiements · 1 667'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('save-payments')));
    await tester.pumpAndSettle();
    expect(f.finances.paid, {22: 833, 23: 834});
  });

  testWidgets('report: validation blocked while entries are pending', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await openFinances(tester, _auditor);
    await tester.tap(find.text('Rapport'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('validate-report')),
      200,
    );
    expect(
      find.textContaining('3 opérations restent à vérifier'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('validate-report')))
          .onPressed,
      isNull,
    );
    f.finances.reportPending = 0;
    await tester.scrollUntilVisible(find.byTooltip('Trimestre suivant'), -200);
    await tester.tap(find.byTooltip('Trimestre suivant'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byTooltip('Trimestre précédent'),
      -200,
    );
    await tester.tap(find.byTooltip('Trimestre précédent'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('validate-report')),
      200,
    );
    await tester.ensureVisible(find.byKey(const Key('validate-report')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('validate-report')));
    await tester.pumpAndSettle();
    expect(f.finances.reportValidated, isTrue);
  });

  testWidgets('every member sees what they owe on Accueil', (tester) async {
    await setUpApp(tester);
    await pumpShell(tester, fakeMe());
    expect(find.text('MES CONTRIBUTIONS'), findsOneWidget);
    expect(find.text('Décès · famille Nkotto'), findsOneWidget);
    expect(find.text('Amende · Retard à l’assise'), findsOneWidget);
    expect(find.text('À PAYER'), findsNWidgets(2));
  });
}
