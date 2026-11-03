import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huddle/data/repositories/profile_repository.dart';
import 'package:huddle/main.dart';
import 'package:huddle/models/me.dart';
import 'package:huddle/data/current_user.dart';
import 'package:huddle/models/announcement.dart';
import 'package:huddle/models/event.dart';
import 'package:huddle/screens/announcements/announcement_detail_screen.dart';
import 'package:huddle/screens/announcements/compose_screen.dart';
import 'package:huddle/screens/calendar/event_detail_screen.dart';
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

  // Build 40: what each group shares.
  testWidgets('the président chooses what the zone may see', (tester) async {
    final f = await setUpApp(tester);
    f.profile.networkInfo = const NetworkInfo(
      networkName: 'MGS Cameroun',
      levelName: 'Paroisse',
      parents: [FakeProfileRepository.zone],
      canManage: true,
      sharing: {'members': 'none', 'finances': 'none'},
    );
    await tester.pumpWidget(const MsgApp(home: NetworkScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Ne partage rien'), findsOneWidget);
    await tester.tap(find.byKey(const Key('network-sharing')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('share-members-detail')));
    await tester.tap(find.byKey(const Key('share-finances-summary')));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('sharing-save')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('sharing-save')));
    await tester.pumpAndSettle();
    expect(f.profile.savedSharing.single['members'], 'detail');
    expect(f.profile.savedSharing.single['finances'], 'summary');
    expect(f.profile.savedSharing.single['calendar'], 'none');
  });

  testWidgets('the zone opens a parish: what it shares, as its role allows', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    f.profile.networkInfo = const NetworkInfo(
      networkName: 'MGS Cameroun',
      levelName: 'Zone paroissiale',
      totals: (groups: 2, sharingMembers: 1, members: 42),
      children: [
        NetworkGroup(
          group: GroupInfo(id: 3, name: 'GS Yapoma', initials: 'GSY'),
          levelName: 'Paroisse',
          shares: ['members', 'finances'],
        ),
      ],
    );
    f.profile.shared = const SharedGroup(
      group: GroupInfo(id: 3, name: 'GS Yapoma', initials: 'GSY'),
      levelName: 'Paroisse',
      parent: 'Zone Nord',
      shared: {
        'members': SharedKind(
          level: 'detail',
          data: {
            'total': 42,
            'people': [
              {
                'name': 'Ewane Brice',
                'roles': ['Président'],
              },
            ],
          },
        ),
        'finances': SharedKind(level: 'summary', hidden: true),
      },
    );
    await tester.pumpWidget(const MsgApp(home: NetworkScreen()));
    await tester.pumpAndSettle();
    expect(
      find.text('42 membres, d’après 1 groupe sur 2 qui partage ses membres'),
      findsOneWidget,
    );
    expect(find.textContaining('Partage : membres, finances'), findsOneWidget);
    await tester.tap(find.byKey(const Key('network-child-3')));
    await tester.pumpAndSettle();
    expect(find.text('Ewane Brice'), findsOneWidget);
    expect(find.text('Président'), findsOneWidget);
    expect(
      find.text(
        'Partagé, mais votre rôle dans ce groupe ne couvre pas cette partie.',
      ),
      findsOneWidget,
    );
  });

  // Build 41: what flows down.
  testWidgets('a zone announcement shows its origin and can\'t be edited', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    f.announcements.items = [
      Announcement(
        id: 77,
        kind: 'annonce',
        title: 'Rencontre de zone',
        body: 'Samedi',
        pinned: false,
        createdAt: DateTime.now(),
        unread: true,
        fromGroup: const GroupInfo(
          id: 7,
          name: 'Zone Nord',
          levelName: 'Zone paroissiale',
        ),
      ),
    ];
    await tester.pumpWidget(
      MsgApp(home: AnnouncementDetailScreen(item: f.announcements.items.first)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('from-group-77')), findsOneWidget);
    expect(
      find.text('De la part de Zone Nord · Zone paroissiale'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
  });

  testWidgets('the zone sends an announcement down', (tester) async {
    final f = await setUpApp(tester);
    currentUser.value = fakeMe(
      groups: const [
        {'id': 7, 'name': 'Zone Nord', 'below': 3},
      ],
    );
    await tester.pumpWidget(const MsgApp(home: ComposeScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('a-title')), 'Pèlerinage');
    // The bottom send bar covers the row in the test window; flip it directly.
    tester.widget<Switch>(find.byKey(const Key('a-cascade'))).onChanged!(true);
    await tester.pump();
    await tester.tap(find.byKey(const Key('a-send')));
    await tester.pumpAndSettle();
    expect(f.announcements.sent.last, 'annonce:Pèlerinage:-:down');
    currentUser.value = null;
  });

  testWidgets('a zone event: read only, no roll call in the parish', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    f.events.events = [
      CalendarEvent(
        id: 5,
        kind: 'messe',
        title: 'Messe de zone',
        startsAt: DateTime.now().add(const Duration(days: 2)),
        place: 'Cathédrale',
        dress: '',
        notes: '',
        fromGroup: const GroupInfo(id: 7, name: 'Zone Nord'),
      ),
    ];
    await tester.pumpWidget(
      MsgApp(
        home: EventDetailScreen(
          eventId: 5,
          me: fakeMe(
            permissions: const {
              'calendar.events': ['view'],
              'calendar.attendance': ['view', 'change'],
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('event-origin')), findsOneWidget);
    expect(find.byKey(const Key('event-from-above-note')), findsOneWidget);
    expect(find.byKey(const Key('roll-call')), findsNothing);
    expect(find.byKey(const Key('warn-absence')), findsNothing);
  });

  // Build 42: joint planning.
  testWidgets('the zone asks each parish for people', (tester) async {
    final f = await setUpApp(tester);
    f.events.events = [
      CalendarEvent(
        id: 8,
        kind: 'messe',
        title: 'Pèlerinage',
        startsAt: DateTime.now().add(const Duration(days: 5)),
        place: '',
        dress: '',
        notes: '',
        cascade: true,
      ),
    ];
    f.events.board = const ContingentBoard(
      canPlan: true,
      sentDown: true,
      groups: [ContingentRow(group: GroupInfo(id: 3, name: 'GS Yapoma'))],
    );
    await tester.pumpWidget(
      MsgApp(
        home: EventDetailScreen(
          eventId: 8,
          me: fakeMe(
            groups: const [
              {'id': 7, 'name': 'Zone Nord', 'below': 1},
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('open-contingents')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('open-contingents')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('more-3')));
    await tester.tap(find.byKey(const Key('more-3')));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('contingents-save')));
    await tester.pumpAndSettle();
    expect(f.events.asked, ['3:2']);
  });

  testWidgets('the parish names its people; the named member sees it', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    f.events.events = [
      CalendarEvent(
        id: 9,
        kind: 'messe',
        title: 'Pèlerinage',
        startsAt: DateTime.now().add(const Duration(days: 5)),
        place: '',
        dress: '',
        notes: '',
        cascade: true,
        fromGroup: const GroupInfo(id: 7, name: 'Zone Nord'),
        contingent: const ContingentSummary(
          requested: 2,
          designated: 1,
          me: true,
        ),
      ),
    ];
    f.events.mine = const MyContingent(requested: 2, canAnswer: true);
    await tester.pumpWidget(
      MsgApp(home: EventDetailScreen(eventId: 9, me: fakeMe())),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('contingent-me')), findsOneWidget);
    expect(find.text('Zone Nord demande 2 personnes'), findsOneWidget);
    await tester.tap(find.byKey(const Key('my-contingent')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('contingent-name')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pick-many-2')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('members-done')));
    await tester.pumpAndSettle();
    expect(f.events.answered, [
      [2],
    ]);
    expect(find.byKey(const Key('named-2')), findsOneWidget);
  });

  // Build 43: neighbours and twinning.
  testWidgets('the président twins with another group, then ends it', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    f.profile.networkInfo = const NetworkInfo(levelName: '', canManage: true);
    await tester.pumpWidget(const MsgApp(home: NetworkScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('twin-join')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('twin-join')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('join-code')), 'abcd-efgh');
    await tester.tap(find.byKey(const Key('join-check')));
    await tester.pumpAndSettle();
    expect(find.text('Jumeler votre groupe avec Zone Nord ?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('join-confirm')));
    await tester.pumpAndSettle();
    expect(f.profile.twinsJoined, ['abcdefgh']);
    await tester.scrollUntilVisible(
      find.byKey(const Key('end-twin-7')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('end-twin-7')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('leave-reason')), 'Fin');
    await tester.tap(find.byKey(const Key('leave-confirm')));
    await tester.pumpAndSettle();
    expect(f.profile.twinsEnded, ['7:Fin']);
  });

  testWidgets('neighbours are listed and get their own sharing', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    f.profile.networkInfo = const NetworkInfo(
      networkName: 'MGS Cameroun',
      levelName: 'Paroisse',
      parents: [FakeProfileRepository.zone],
      canManage: true,
      sharing: {'members': 'none'},
      sharingNeighbours: {'members': 'summary'},
      neighbours: [
        NetworkGroup(
          group: GroupInfo(id: 4, name: 'GS Bonamoussadi'),
          levelName: 'Paroisse',
          shares: ['calendar'],
        ),
      ],
    );
    await tester.pumpWidget(const MsgApp(home: NetworkScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('neighbour-4')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Partage : calendrier'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('sharing-neighbours')),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('sharing-neighbours')));
    await tester.pumpAndSettle();
    expect(f.profile.lastAudience, 'neighbours');
    expect(
      find.text('Avec les groupes voisins (même groupe au-dessus)'),
      findsWidgets,
    );
  });
}
