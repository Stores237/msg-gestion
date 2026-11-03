import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huddle/data/repositories/profile_repository.dart';
import 'package:huddle/main.dart';
import 'package:huddle/models/me.dart';
import 'package:huddle/screens/network_screen.dart';

import 'fakes.dart';
import 'helpers.dart';

/// Build 39 (owner, 2026-11-03): networks of groups — a parish group joins
/// its zone with the zone's code, leaves with a reason; an umbrella group
/// invites; members only look.
void main() {
  testWidgets('the président joins the zone with its code, then leaves', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    f.profile.networkInfo = const NetworkInfo(
      networkName: 'MGS Cameroun',
      levels: ['Paroisse', 'Zone paroissiale'],
      levelName: 'Paroisse',
      canManage: true,
    );
    await tester.pumpWidget(const MsgApp(home: NetworkScreen()));
    await tester.pumpAndSettle();
    expect(
      find.text('Réseau MGS Cameroun · votre groupe : Paroisse.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('network-join')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('join-code')), 'abc');
    await tester.tap(find.byKey(const Key('join-check')));
    await tester.pumpAndSettle();
    expect(find.text('Le code a 8 caractères, ex. ABCD-EFGH.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('join-code')), 'zzzz-zzzz');
    await tester.tap(find.byKey(const Key('join-check')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Code d’invitation inconnu. Vérifiez-le auprès du groupe qui vous invite.',
      ),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const Key('join-code')), 'abcd-efgh');
    await tester.tap(find.byKey(const Key('join-check')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('join-ask')), findsOneWidget);
    expect(find.text('Rattacher votre groupe à Zone Nord ?'), findsOneWidget);
    expect(find.text('Lui-même rattaché à Diocèse de Douala'), findsOneWidget);
    await tester.tap(find.byKey(const Key('join-confirm')));
    await tester.pumpAndSettle();
    expect(f.profile.joined, ['abcdefgh']);
    expect(find.byKey(const Key('network-parent-7')), findsOneWidget);

    await tester.tap(find.byKey(const Key('network-leave')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('leave-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Indiquez le motif.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('leave-reason')),
      'Nouvelle zone',
    );
    await tester.tap(find.byKey(const Key('leave-confirm')));
    await tester.pumpAndSettle();
    expect(f.profile.left, ['Nouvelle zone']);
    expect(find.byKey(const Key('network-parent-7')), findsNothing);
  });

  testWidgets('an umbrella group invites and cancels a code', (tester) async {
    final f = await setUpApp(tester);
    f.profile.networkInfo = const NetworkInfo(
      networkName: 'MGS Cameroun',
      levels: ['Paroisse', 'Zone paroissiale'],
      levelName: 'Zone paroissiale',
      canManage: true,
      canInvite: true,
      children: [
        NetworkGroup(
          group: GroupInfo(id: 3, name: 'GS Yapoma', initials: 'GSY'),
          levelName: 'Paroisse',
        ),
      ],
    );
    await tester.pumpWidget(const MsgApp(home: NetworkScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('network-child-3')), findsOneWidget);
    expect(find.text('1 GROUPE RATTACHÉ'), findsOneWidget);
    await tester.tap(find.byKey(const Key('network-invite')));
    await tester.pumpAndSettle();
    expect(find.text('WXYZ-2345'), findsWidgets);
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('revoke-WXYZ-2345')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('revoke-WXYZ-2345')));
    await tester.pumpAndSettle();
    expect(f.profile.revoked, ['WXYZ-2345']);
  });

  testWidgets('members look; the group sheet opens Réseau', (tester) async {
    final f = await setUpApp(tester);
    f.profile.networkInfo = const NetworkInfo(
      networkName: 'MGS Cameroun',
      levelName: 'Paroisse',
      parents: [FakeProfileRepository.zone],
    );
    await pumpShell(
      tester,
      fakeMe(
        tabs: const ['accueil'],
        groups: const [
          {
            'id': 1,
            'name': 'GS Yapoma',
            'level_name': 'Paroisse',
            'parent': 'Zone Nord',
          },
        ],
      ),
    );
    await tester.tap(find.byKey(const Key('home-group-name')).first);
    await tester.pumpAndSettle();
    expect(find.text('Paroisse · Zone Nord'), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-network')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('network-parent-7')), findsOneWidget);
    expect(find.byKey(const Key('network-join')), findsNothing);
    expect(find.byKey(const Key('network-leave')), findsNothing);
    expect(find.byKey(const Key('network-invite')), findsNothing);
  });
}
