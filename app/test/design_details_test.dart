import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/main.dart';
import 'package:msg_gestion/models/announcement.dart';
import 'package:msg_gestion/models/event.dart';
import 'package:msg_gestion/models/member.dart';
import 'package:msg_gestion/screens/announcements/compose_screen.dart';
import 'package:msg_gestion/screens/calendar/event_detail_screen.dart';
import 'package:msg_gestion/screens/members/member_profile_screen.dart';
import 'package:msg_gestion/widgets/ui.dart';

import 'fakes.dart';
import 'helpers.dart';

/// Design details added 2026-10-27: place and dress details on the event,
/// announcement draft kept on the phone, leave end date on the profile.
void main() {
  testWidgets('event shows the place detail and what the dress means', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    f.events.events = [
      CalendarEvent(
        id: 1,
        kind: 'reunion',
        title: 'Réunion',
        startsAt: DateTime.now().add(const Duration(days: 2)),
        place: 'Salle paroissiale',
        placeDetail: 'Quartier, ville',
        dress: 'civile',
        dressDetail: 'Ce que la tenue comprend',
        notes: '',
      ),
    ];
    await tester.pumpWidget(
      MsgApp(home: EventDetailScreen(eventId: 1, me: fakeMe())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Quartier, ville'), findsOneWidget);
    expect(find.text('Ce que la tenue comprend'), findsOneWidget);
  });

  testWidgets('Brouillon keeps the announcement on the phone until sent', (
    tester,
  ) async {
    await setUpApp(tester);
    Future<void> open() async {
      await tester.pumpWidget(
        MsgApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                key: const Key('open'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ComposeScreen()),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
    }

    await open();
    await tester.enterText(find.byKey(const Key('a-title')), 'Collecte');
    await tester.enterText(find.byKey(const Key('a-body')), 'Samedi après');
    await tester.tap(find.byKey(const Key('a-draft')));
    await tester.pumpAndSettle();
    expect(find.byType(ComposeScreen), findsNothing);
    await open();
    expect(find.text('Collecte'), findsOneWidget);
    expect(find.text('Samedi après'), findsOneWidget);
    expect(find.text('Brouillon repris.'), findsOneWidget);
  });

  testWidgets('a member on leave shows until when', (tester) async {
    final f = await setUpApp(tester);
    final s = f.members.members[1];
    f.members.members[1] = MemberSummary(
      id: s.id,
      lastName: s.lastName,
      firstName: s.firstName,
      fullName: s.fullName,
      status: 'conge',
      isDiaspora: false,
      city: '',
      age: 30,
      isMinor: false,
      joinedYear: 2020,
      roles: const [],
      leaveUntil: DateTime(2026, 11, 15),
    );
    await tester.pumpWidget(
      const MsgApp(home: MemberProfileScreen(memberId: 2)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('JUSQU’AU'), findsOneWidget);
  });

  testWidgets('an event that is over shows a grey Expiré chip', (tester) async {
    await setUpApp(tester);
    CalendarEvent at(Duration from) => CalendarEvent(
      id: 1,
      kind: 'assise',
      title: 'Assise',
      startsAt: DateTime.now().add(from),
      endsAt: DateTime.now().add(from + const Duration(hours: 2)),
      place: '',
      dress: '',
      notes: '',
    );
    await tester.pumpWidget(
      MsgApp(
        home: Scaffold(
          body: Column(
            children: [
              EventCard(event: at(const Duration(days: -2))),
              EventCard(event: at(const Duration(days: 2))),
              // Started, not ended yet: not expired.
              EventCard(event: at(const Duration(hours: -1))),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('event-expired')), findsOneWidget);
    expect(find.text('EXPIRÉ'), findsOneWidget);
  });

  testWidgets('a convocation whose date has passed shows Expiré', (
    tester,
  ) async {
    await setUpApp(tester);
    Announcement conv(Duration from) => Announcement(
      id: 7,
      kind: 'convocation',
      title: 'Assemblée générale',
      body: '',
      pinned: false,
      authorName: 'Nyobe C.',
      createdAt: DateTime(2026, 10, 1),
      unread: false,
      eventId: 3,
      eventStartsAt: DateTime.now().add(from),
    );
    await tester.pumpWidget(
      MsgApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                AnnouncementCard(item: conv(const Duration(days: -3))),
                AnnouncementCard(item: conv(const Duration(days: 3))),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('announcement-expired')), findsOneWidget);
  });
}
