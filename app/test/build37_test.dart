import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huddle/main.dart';
import 'package:huddle/data/balance_privacy.dart';
import 'package:huddle/data/repositories/profile_repository.dart';
import 'package:huddle/models/member.dart';
import 'package:huddle/models/planning.dart';
import 'package:huddle/screens/help_screens.dart';
import 'package:huddle/screens/login_phone_screen.dart';
import 'package:huddle/widgets/money.dart';

import 'fakes.dart';
import 'helpers.dart';

/// Build 37 (owner, 2026-11-02).
void main() {
  tearDown(() {
    BalancePrivacy.hidden.value = false;
    Currency.code = 'FCFA';
  });

  testWidgets('the eye hides the balance on Finances and Accueil', (
    tester,
  ) async {
    await setUpApp(tester);
    await pumpShell(
      tester,
      fakeMe(
        tabs: const ['accueil', 'finances'],
        permissions: const {
          'finances.cashbook': ['view'],
        },
      ),
    );
    await tester.tap(find.byKey(const Key('tab-finances')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('balance')), findsOneWidget);
    await tester.tap(find.byKey(const Key('toggle-balance')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('balance')), findsNothing);
    expect(find.byKey(const Key('balance-hidden')), findsOneWidget);
    expect(BalancePrivacy.hidden.value, isTrue);
    await tester.tap(find.byKey(const Key('toggle-balance')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('balance')), findsOneWidget);
  });

  testWidgets('the group currency is on every amount', (tester) async {
    await setUpApp(tester);
    await pumpShell(
      tester,
      fakeMe(
        tabs: const ['accueil', 'finances'],
        permissions: const {
          'finances.cashbook': ['view'],
        },
        groups: const [
          {'id': 1, 'name': 'Chorale', 'currency': 'EUR'},
        ],
      ),
    );
    expect(Currency.code, 'EUR');
    expect(fcfa(1500), endsWith('EUR'));
  });

  testWidgets('a cash-book notice opens Finances', (tester) async {
    final f = await setUpApp(tester);
    f.notifications.extra.add(
      AppNotification(
        id: 9,
        kind: 'payment',
        title: 'Opération à approuver',
        body: 'Papier · 4 000 FCFA',
        target: const {'type': 'cashbook'},
        createdAt: DateTime.now(),
        unread: true,
      ),
    );
    await pumpShell(
      tester,
      fakeMe(
        tabs: const ['accueil', 'finances'],
        permissions: const {
          'finances.cashbook': ['view'],
        },
      ),
    );
    await tester.tap(find.byKey(const Key('bell')).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notif-9')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('balance')), findsOneWidget);
  });

  testWidgets('FAQ: the group, then common; members propose a question', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    f.profile.faqData = const FaqData(
      group: [('Où est la répétition ?', 'À la salle paroissiale.')],
      common: [('Qui voit mes paiements ?', 'Le trésorier et vous.')],
    );
    await tester.pumpWidget(const MsgApp(home: FaqScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('faq-group')), findsOneWidget);
    expect(find.text('Où est la répétition ?'), findsOneWidget);
    expect(find.text('Qui voit mes paiements ?'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('faq-suggest')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('faq-suggest')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('faq-send')));
    await tester.pumpAndSettle();
    expect(find.text('Écrivez la question.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('faq-question')),
      'Comment changer de poste ?',
    );
    await tester.enterText(
      find.byKey(const Key('faq-answer')),
      'Demandez au formateur.',
    );
    await tester.tap(find.byKey(const Key('faq-send')));
    await tester.pumpAndSettle();
    expect(f.profile.suggested, [
      ('Comment changer de poste ?', 'Demandez au formateur.'),
    ]);
    await tester.scrollUntilVisible(
      find.byKey(const Key('faq-mine-1')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('EN LECTURE'), findsOneWidget);
  });

  testWidgets('forgot PIN with the back-office recovery code', (tester) async {
    final f = await setUpApp(tester);
    await tester.pumpWidget(const MsgApp(home: LoginPhoneScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('phone-field')), '677452108');
    await tester.tap(find.byKey(const Key('terms-checkbox')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('phone-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('forgot-pin')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('forgot-recovery')));
    await tester.pumpAndSettle();
    expect(find.text('Code de récupération (8 chiffres)'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('forgot-code')), '12345678');
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('forgot-new')),
        matching: find.byType(TextFormField),
      ),
      '7391',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('forgot-confirm')),
        matching: find.byType(TextFormField),
      ),
      '7391',
    );
    await tester.tap(find.byKey(const Key('forgot-submit')));
    await tester.pumpAndSettle();
    expect(f.auth.changed, ['7391']);
  });

  testWidgets('members on probation and inactive are marked', (tester) async {
    final f = await setUpApp(tester);
    f.members.members
      ..[0] = const MemberSummary(
        id: 1,
        lastName: 'Ewane',
        firstName: 'Brice',
        fullName: 'Ewane Brice',
        status: 'actif',
        isDiaspora: false,
        city: '',
        age: 30,
        isMinor: false,
        joinedYear: 2026,
        roles: [],
        onProbation: true,
      )
      ..[2] = const MemberSummary(
        id: 3,
        lastName: 'Ateba',
        firstName: 'Sandrine',
        fullName: 'Ateba Sandrine',
        status: 'actif',
        isDiaspora: false,
        city: '',
        age: 30,
        isMinor: false,
        joinedYear: 2019,
        roles: [],
        inactive: true,
      );
    await pumpShell(
      tester,
      fakeMe(
        tabs: const ['accueil', 'membres'],
        permissions: const {
          'members.profile': ['view'],
        },
      ),
    );
    await tester.tap(find.byKey(const Key('tab-membres')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('probation-1')), findsOneWidget);
    expect(find.byKey(const Key('inactive-3')), findsOneWidget);
    expect(find.text('À L’ESSAI'), findsOneWidget);
    expect(find.text('INACTIF'), findsOneWidget);
  });

  testWidgets('a finance PDF for a chosen period', (tester) async {
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
    expect(
      find.text('Tout l’historique, jusqu’à aujourd’hui.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('period-month')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('period-text'))).data,
      startsWith('Du '),
    );
    await tester.tap(find.byKey(const Key('confirm-download')));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    String day(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    expect(f.finances.exports, [
      'cashbook:${day(DateTime(now.year, now.month))}_${day(now)}',
    ]);
  });
}
