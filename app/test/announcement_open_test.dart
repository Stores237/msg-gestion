import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/main.dart';
import 'package:msg_gestion/models/announcement.dart';
import 'package:msg_gestion/screens/announcements/announcement_detail_screen.dart';
import 'package:msg_gestion/screens/notifications_screen.dart';
import 'package:msg_gestion/widgets/photo_frame.dart';

import 'fakes.dart';
import 'helpers.dart';

/// Owner, 2026-10-29: a notification opens its announcement, "Pour vous" is
/// a small mark; photos scroll vertically; Accueil shows the three newest.
void main() {
  testWidgets('a notification opens its announcement; "Pour vous" is a mark', (
    tester,
  ) async {
    await setUpApp(tester);
    await tester.pumpWidget(const MsgApp(home: NotificationsScreen()));
    await tester.pumpAndSettle();
    // The announcement's own title, with the mark beside it.
    expect(find.text('Répétition des chants'), findsOneWidget);
    expect(find.byKey(const Key('notif-for-me-1')), findsOneWidget);
    expect(find.byKey(const Key('notif-for-me-2')), findsNothing);

    await tester.tap(find.byKey(const Key('notif-1')));
    await tester.pumpAndSettle();
    expect(find.byType(AnnouncementDetailScreen), findsOneWidget);
    expect(find.text('Jeudi 18:00 à l’église.'), findsOneWidget);
  });

  testWidgets('photos: all of them, one under the other, from the tapped one', (
    tester,
  ) async {
    await setUpApp(tester);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MsgApp(
        home: PhotoGallery(
          urls: [
            'https://example.test/0.jpg',
            'https://example.test/1.jpg',
            'https://example.test/2.jpg',
            'https://example.test/3.jpg',
          ],
          initial: 3,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final list = tester.widget<ListView>(
      find.byKey(const Key('photo-gallery')),
    );
    expect(list.scrollDirection, Axis.vertical);
    expect(find.text('4 photos'), findsOneWidget);
    expect(find.byKey(const Key('gallery-photo-3')), findsOneWidget);
    expect(find.byKey(const Key('gallery-photo-0')), findsNothing);
    await tester.drag(
      find.byKey(const Key('photo-gallery')),
      const Offset(0, 2000),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gallery-photo-0')), findsOneWidget);
  });

  testWidgets('Accueil: the three newest announcements, pinned or not', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    Announcement item(int id, int day, {bool pinned = false}) => Announcement(
      id: id,
      kind: 'annonce',
      title: 'Annonce $id',
      body: '',
      pinned: pinned,
      createdAt: DateTime(2026, 10, day),
      unread: false,
    );
    // The feed lists pinned first.
    f.announcements.items = [
      item(1, 20, pinned: true),
      item(2, 29),
      item(3, 27),
      item(4, 25),
    ];
    await pumpShell(tester, fakeMe());
    await tester.scrollUntilVisible(
      find.byKey(const Key('home-latest')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('DERNIÈRES ANNONCES'), findsOneWidget);
    final rows = tester
        .widgetList(
          find.descendant(
            of: find.byKey(const Key('home-latest')),
            matching: find.byWidgetPredicate(
              (w) =>
                  w.key is ValueKey<String> &&
                  (w.key as ValueKey<String>).value.startsWith(
                    'home-announcement-',
                  ),
            ),
          ),
        )
        .map((w) => (w.key as ValueKey<String>).value)
        .toList();
    expect(rows, [
      'home-announcement-2',
      'home-announcement-3',
      'home-announcement-4',
    ]);
  });
}
