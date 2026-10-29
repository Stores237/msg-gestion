import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:msg_gestion/data/data_settings.dart';
import 'package:msg_gestion/main.dart';
import 'package:msg_gestion/models/announcement.dart';
import 'package:msg_gestion/screens/announcements/compose_screen.dart';
import 'package:msg_gestion/widgets/photo_frame.dart';
import 'package:msg_gestion/widgets/ui.dart';

import 'helpers.dart';

/// Photos in announcements (owner, 2026-10-28): landscape 4:3, ≤ 2 MB,
/// 4 per announcement.
Uint8List _photo(int w, int h, {bool noise = false}) {
  final im = img.Image(width: w, height: h);
  for (final p in im) {
    p
      ..r = noise ? (p.x * 37 + p.y * 91) % 256 : 40
      ..g = noise ? (p.x * 13 ^ p.y * 7) % 256 : 120
      ..b = noise ? (p.x * p.y) % 256 : 70;
  }
  return img.encodeJpg(im, quality: 95);
}

/// Waits in real time for work done outside the test clock (image decode,
/// cropping in an isolate) until [finder] shows.
Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 50 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
}

void main() {
  test('framing crops to 4:3, resizes and stays under 2 MB', () {
    // A tall photo, busy enough to be heavy.
    final src = _photo(1800, 2400, noise: true);
    final out = framePhoto((
      src,
      const Rect.fromLTWH(0, 600, 1800, 1350),
      2048,
      1536,
    ));
    final back = img.decodeJpg(out)!;
    expect((back.width, back.height), (2048, 1536));
    expect(out.length, lessThanOrEqualTo(photoMaxBytes));
  });

  testWidgets(
    'composer: add a framed photo; it is sent with the announcement',
    (tester) async {
      final f = await setUpApp(tester);
      pickRawPhoto = (_) async => _photo(1600, 1000);
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
      await tester.enterText(find.byKey(const Key('a-title')), 'Sortie');
      await tester.ensureVisible(find.byKey(const Key('a-photo')));
      await tester.tap(find.byKey(const Key('a-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('photo-src-gallery')));
      await tester.pump();
      await _waitFor(tester, find.byKey(const Key('photo-frame')));
      expect(find.byKey(const Key('photo-frame')), findsOneWidget);
      expect(
        find.text('Format paysage 4:3 · 2 Mo maximum · 4 photos par annonce'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('photo-use')));
      // Cropping runs off the UI thread.
      await _waitFor(tester, find.byKey(const Key('picked-photo-0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('picked-photo-0')), findsOneWidget);
      await tester.tap(find.byKey(const Key('a-send')));
      await tester.pumpAndSettle();
      expect(
        f.announcements.attached.single,
        matches(RegExp(r':photo-\d+\.jpg$')),
      );
    },
  );

  testWidgets(
    'card: photos slide by themselves, a touch pauses; tap-to-load when off',
    (tester) async {
      await setUpApp(tester);
      Announcement withPhotos() => Announcement(
        id: 3,
        kind: 'annonce',
        title: 'Album',
        body: '',
        pinned: false,
        authorName: 'Din Y.',
        createdAt: DateTime(2026, 10, 28),
        unread: false,
        attachments: [
          for (final i in [1, 2, 3])
            AttachmentInfo(
              id: i,
              name: 'photo-$i.jpg',
              size: 200000,
              contentType: 'image/jpeg',
              url: 'https://example.test/$i.jpg',
            ),
        ],
      );
      // Photos stay as "Afficher la photo" here: tests have no network.
      DataSettings.instance
        ..network = 'mobile'
        ..dataSaver = true;
      await tester.pumpWidget(
        MsgApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnnouncementCard(item: withPhotos(), onTap: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PhotoCarousel), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      expect(find.byKey(const Key('photo-tap-to-load')), findsOneWidget);

      // Moves on by itself, and back to the first after the last.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.text('3/3'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.text('1/3'), findsOneWidget);

      // Swiped by hand, horizontally.
      await tester.drag(
        find.byKey(const Key('photo-carousel')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);

      // A finger held on it pauses it.
      final hold = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('photo-carousel'))),
      );
      await tester.pump(const Duration(seconds: 9));
      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);
      await hold.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('reduced motion: no automatic sliding', (tester) async {
    await setUpApp(tester);
    await tester.pumpWidget(
      MsgApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: PhotoCarousel(
                  urls: [
                    'https://example.test/1.jpg',
                    'https://example.test/2.jpg',
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text('1/2'), findsOneWidget);
  });
}
