import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huddle/data/current_user.dart';
import 'package:huddle/data/repositories/profile_repository.dart';
import 'package:huddle/main.dart';
import 'package:huddle/models/announcement.dart';
import 'package:huddle/models/me.dart';
import 'package:huddle/models/network_reach.dart';
import 'package:huddle/screens/announcements/compose_screen.dart';
import 'package:huddle/screens/network_sharing_screens.dart';
import 'package:huddle/widgets/ui.dart';

import 'fakes.dart';
import 'helpers.dart';

/// Build 48 (owner, 2026-11-04): the sender picks which groups of the
/// network receive a post (and whether only their bureau); each sharing
/// level says what it shows, with a preview; a linked group's page filters
/// what is visible or not and lets you ask for more; the président answers.
void main() {
  const kotto = GroupInfo(id: 4, name: 'GS Kotto');
  const yapoma = GroupInfo(id: 3, name: 'GS Yapoma');
  const chorale = GroupInfo(id: 9, name: 'Chorale');
  final zone = ShareRequestInfo(
    id: 1,
    kind: 'finances',
    level: 'detail',
    fromGroup: const GroupInfo(id: 7, name: 'Zone Nord'),
    target: yapoma,
    createdAt: DateTime(2026, 11, 4),
    note: 'Pour le rapport',
    by: 'Ngono A.',
    current: 'none',
  );

  // A phone-sized window, taller than the 800×600 default.
  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> scrollTo(WidgetTester tester, String key) =>
      tester.scrollUntilVisible(
        find.byKey(Key(key)),
        200,
        scrollable: find.byType(Scrollable).first,
      );

  testWidgets('the sender picks groups and the bureau only', (tester) async {
    final f = await setUpApp(tester);
    currentUser.value = fakeMe(
      groups: const [
        {'id': 3, 'name': 'GS Yapoma', 'reach': 3},
      ],
    );
    f.profile.reachGroups = const [
      ReachGroup(group: kotto, relation: 'neighbour'),
      ReachGroup(group: chorale, relation: 'twin'),
      ReachGroup(
        group: GroupInfo(id: 5, name: 'GS Bonamoussadi'),
        relation: 'neighbour',
      ),
    ];
    await tester.pumpWidget(const MsgApp(home: ComposeScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('a-title')), 'Concert');
    await scrollTo(tester, 'a-cascade');
    expect(find.text('Pas diffusé dans le réseau'), findsOneWidget);
    // The bottom send bar covers the row in the test window: tap it directly.
    tester
        .widget<InkWell>(
          find.descendant(
            of: find.byKey(const Key('a-cascade')),
            matching: find.byType(InkWell),
          ),
        )
        .onTap!();
    await tester.pumpAndSettle();
    // Filters by link; the twin only.
    expect(find.text('Jumelés (1)'), findsOneWidget);
    await tester.tap(find.text('Jumelés (1)'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reach-4')), findsNothing);
    await tester.tap(find.byKey(const Key('reach-9')));
    await tester.tap(find.text('Le bureau seulement'));
    await tester.pump();
    expect(
      find.text(
        'Seuls les membres du bureau des groupes choisis la voient et sont prévenus.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('reach-done')));
    await tester.pumpAndSettle();
    expect(find.text('Chorale · Le bureau seulement'), findsOneWidget);
    await tester.tap(find.byKey(const Key('a-send')));
    await tester.pumpAndSettle();
    expect(f.announcements.lastReach!.ids, [9]);
    expect(f.announcements.lastReach!.audience, 'bureau');
    currentUser.value = null;
  });

  testWidgets('a sent post says where it went', (tester) async {
    await setUpApp(tester);
    await tester.pumpWidget(
      MsgApp(
        home: Scaffold(
          body: AnnouncementCard(
            item: Announcement(
              id: 1,
              kind: 'annonce',
              title: 'Réunion des présidents',
              body: '',
              pinned: false,
              createdAt: DateTime.now(),
              unread: false,
              cascade: true,
              sentTo: const SentTo(audience: 'bureau', groups: [kotto]),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Diffusé à : GS Kotto · Le bureau seulement'),
      findsOneWidget,
    );
  });

  testWidgets('each level says what it shows; preview before saving', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    f.profile.sharingSettings = const SharingSettings(
      values: {'announcements': 'summary'},
      options: {
        'members': ['none', 'summary', 'detail'],
        'announcements': ['none', 'summary', 'detail'],
      },
      canManage: true,
    );
    f.profile.requests = ShareRequests(canAnswer: true, incoming: [zone]);
    f.profile.preview = const {
      'members': SharedKind(level: 'summary', data: {'total': 42}),
    };
    await tester.pumpWidget(const MsgApp(home: SharingScreen()));
    await tester.pumpAndSettle();
    expect(
      find.text('1 demande de partage attend votre réponse'),
      findsOneWidget,
    );
    expect(
      find.text(
        'En plus : leurs photos et fichiers joints.',
        findRichText: true,
      ),
      findsNothing, // detail repeats the summary, then adds files
    );
    expect(
      find.textContaining('En plus : leurs photos et fichiers joints.'),
      findsOneWidget,
    );
    await scrollTo(tester, 'share-members-summary');
    await tester.tap(find.byKey(const Key('share-members-summary')));
    await tester.pump();
    expect(find.text('MODIFIÉ'), findsOneWidget);
    await tester.tap(find.byKey(const Key('sharing-preview-open')));
    await tester.pumpAndSettle();
    expect(f.profile.previewed.single['members'], 'summary');
    expect(find.text('Ce qu’ils verront'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('a linked group: filters, then ask for what is not shared', (
    tester,
  ) async {
    tall(tester);
    final f = await setUpApp(tester);
    f.profile.shared = SharedGroup(
      group: yapoma,
      levelName: 'Paroisse',
      kinds: [
        const KindStatus(
          kind: 'members',
          level: 'summary',
          state: 'shared',
          levels: ['summary', 'detail'],
          data: {'total': 42},
          canRequest: true,
          nextLevel: 'detail',
        ),
        const KindStatus(
          kind: 'finances',
          levels: ['summary', 'detail'],
          canRequest: true,
          nextLevel: 'summary',
        ),
        const KindStatus(kind: 'reports', level: 'detail', state: 'hidden'),
        KindStatus(
          kind: 'calendar',
          levels: const ['summary', 'detail'],
          request: ShareRequestInfo(
            id: 8,
            kind: 'calendar',
            level: 'summary',
            fromGroup: const GroupInfo(id: 7, name: 'Zone Nord'),
            target: yapoma,
            createdAt: DateTime(2026, 11, 3),
          ),
        ),
      ],
    );
    await tester.pumpWidget(const MsgApp(home: SharedGroupScreen(groupId: 3)));
    await tester.pumpAndSettle();
    expect(find.text('Rattaché à votre groupe'.toUpperCase()), findsOneWidget);
    // Not shared only: finances and calendar.
    await tester.tap(find.byKey(const Key('sg-stat-3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sg-kind-members')), findsNothing);
    expect(find.byKey(const Key('sg-kind-finances')), findsOneWidget);
    expect(find.byKey(const Key('sg-pending-calendar')), findsOneWidget);
    await scrollTo(tester, 'sg-cancel-calendar');
    await tester.tap(find.byKey(const Key('sg-cancel-calendar')));
    await tester.pumpAndSettle();
    expect(f.profile.cancelled, [8]);
    await scrollTo(tester, 'sg-ask-finances');
    await tester.tap(find.byKey(const Key('sg-ask-finances')));
    await tester.pumpAndSettle();
    expect(find.textContaining('pas seulement avec vous'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ask-level-detail')));
    await tester.enterText(find.byKey(const Key('ask-note')), 'Bilan');
    await tester.tap(find.byKey(const Key('ask-send')));
    await tester.pumpAndSettle();
    expect(f.profile.asked, ['3:finances:detail:Bilan']);
    // Reserved for other roles: said, no request button.
    await tester.tap(find.byKey(const Key('sg-stat-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sg-kind-reports')), findsOneWidget);
    expect(find.byKey(const Key('sg-ask-reports')), findsNothing);
  });

  testWidgets('the président accepts or declines a request', (tester) async {
    tall(tester);
    final f = await setUpApp(tester);
    f.profile.requests = ShareRequests(
      canAnswer: true,
      incoming: [
        zone,
        ShareRequestInfo(
          id: 2,
          kind: 'members',
          level: 'summary',
          fromGroup: kotto,
          target: yapoma,
          createdAt: DateTime(2026, 11, 2),
        ),
      ],
    );
    await tester.pumpWidget(const MsgApp(home: ShareRequestsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Reçues (2)'), findsOneWidget);
    expect(find.text('« Pour le rapport »'), findsOneWidget);
    await tester.tap(find.byKey(const Key('sr-accept-1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('tous les groupes au-dessus'), findsOneWidget);
    await tester.tap(find.byKey(const Key('sr-accept-confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sr-decline-2')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('sr-decline-note')),
      'Plus tard',
    );
    await tester.tap(find.byKey(const Key('sr-decline-confirm')));
    await tester.pumpAndSettle();
    expect(f.profile.answered, ['1:true:', '2:false:Plus tard']);
  });
}
