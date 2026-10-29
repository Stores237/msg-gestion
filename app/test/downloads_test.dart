import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/data/data_settings.dart';
import 'package:msg_gestion/data/file_store.dart';
import 'package:msg_gestion/data/offline.dart';
import 'package:msg_gestion/main.dart';
import 'package:msg_gestion/models/announcement.dart';
import 'package:msg_gestion/screens/downloads_screen.dart';
import 'package:msg_gestion/widgets/attachments.dart';
import 'package:msg_gestion/widgets/photo_frame.dart';
import 'package:msg_gestion/widgets/store_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';
import 'helpers.dart';

/// Downloads and offline viewing (owner, 2026-10-29): a photo or a PDF can
/// be downloaded, and what was seen stays viewable without network.
void main() {
  const photo = 'https://cdn.test/announcements/a1.jpg';

  group('FileStore', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      DataSettings.debugSetInstance(DataSettings());
    });

    test(
      'one copy per file, whatever the signature; offline reads it',
      () async {
        final files = FakeFiles();
        final store = files.store;
        await store.bytes('$photo?X-Amz-Signature=one');
        await store.bytes('$photo?X-Amz-Signature=two');
        expect(files.fetched, hasLength(1));
        expect(store.isCached('$photo?sig=three'), isTrue);
        files.online = false;
        expect(await store.bytes('$photo?sig=four'), isNotEmpty);
        await expectLater(
          store.bytes('https://cdn.test/never-seen.jpg'),
          throwsA(isA<FileUnavailable>()),
        );
      },
    );

    test(
      'downloaded again, a source keeps one copy; forget erases all',
      () async {
        final files = FakeFiles();
        final store = files.store;
        final a = await store.keep(
          source: 'fin-cashbook',
          name: 'Livre de caisse.pdf',
          mime: 'application/pdf',
          data: Uint8List.fromList([1, 2, 3]),
        );
        expect(await store.saveToPhone(a), isTrue);
        // Same bytes: still on the phone, not copied twice.
        final again = await store.keep(
          source: 'fin-cashbook',
          name: 'Livre de caisse.pdf',
          mime: 'application/pdf',
          data: Uint8List.fromList([1, 2, 3]),
        );
        expect(again.onPhone, isTrue);
        expect(await store.saveToPhone(again), isTrue);
        expect(files.platform.saved, ['Livre de caisse.pdf']);
        // New content replaces the old copy.
        await store.keep(
          source: 'fin-cashbook',
          name: 'Livre de caisse.pdf',
          mime: 'application/pdf',
          data: Uint8List.fromList([4, 5]),
        );
        expect(store.downloads.single.size, 2);
        expect(
          files.backend.files.keys.where((k) => k.endsWith('.pdf')),
          hasLength(1),
        );
        // Photos aren't counted as PDFs and PDFs aren't kept twice.
        await store.bytes(photo);
        await store.forget();
        expect(store.downloads, isEmpty);
        expect(store.mediaBytes, 0);
      },
    );

    test('a PDF is not kept twice (Téléchargements only)', () async {
      final files = FakeFiles();
      await files.store.keep(
        source: 'att-3',
        name: 'Programme.pdf',
        mime: 'application/pdf',
        url: 'https://cdn.test/p.pdf?sig=1',
      );
      expect(files.store.mediaBytes, 0);
      expect(files.store.downloads.single.name, 'Programme.pdf');
    });

    test('signing out erases photos and downloads too', () async {
      final files = FakeFiles();
      FileStore.debugSetInstance(files.store);
      final offline = OfflineState(storage: MemoryOfflineStorage());
      await files.store.bytes(photo);
      await files.store.keep(
        source: 'x',
        name: 'x.pdf',
        mime: 'application/pdf',
        data: Uint8List.fromList([1]),
      );
      await offline.forget();
      expect(files.store.downloads, isEmpty);
      expect(files.store.mediaBytes, 0);
    });
  });

  testWidgets('gallery: Télécharger saves the shown photo to the gallery', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await tester.pumpWidget(
      const MsgApp(
        home: PhotoGallery(
          urls: [photo, 'https://cdn.test/announcements/a2.jpg'],
          initial: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('gallery-download')));
    await tester.pumpAndSettle();
    expect(f.files.platform.saved, ['MSG-a2.jpg']);
    expect(
      find.text('Photo enregistrée dans la galerie (Images › MSG)'),
      findsOneWidget,
    );
    expect(f.files.store.downloads.single.mime, 'image/jpeg');
  });

  testWidgets('a photo seen before shows offline, even with data saver', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await f.files.store.bytes('$photo?sig=old');
    f.files.online = false;
    final settings = DataSettings.instance
      ..network = 'mobile'
      ..dataSaver = true;
    expect(settings.autoPhotos, isFalse);
    await tester.pumpWidget(
      const MsgApp(
        home: Scaffold(body: AnnouncementPhoto(url: '$photo?sig=new')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photo-tap-to-load')), findsNothing);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as StoreImage).key, FileStore.keyFor(photo));
  });

  testWidgets('a PDF opens, is kept, and opens again offline', (tester) async {
    final f = await setUpApp(tester);
    const pdf = AttachmentInfo(
      id: 7,
      name: 'Programme.pdf',
      size: 1200,
      contentType: 'application/pdf',
      url: 'https://cdn.test/p.pdf?sig=1',
    );
    await tester.pumpWidget(
      const MsgApp(
        home: Scaffold(body: AttachmentList(items: [pdf])),
      ),
    );
    await tester.tap(find.byKey(const Key('att-file-7')));
    await tester.pumpAndSettle();
    expect(f.files.platform.opened, hasLength(1));
    expect(f.files.platform.saved, ['Programme.pdf']);
    expect(find.text('Enregistré dans Téléchargements › MSG'), findsOneWidget);

    f.files.online = false;
    await tester.tap(find.byKey(const Key('att-file-7')));
    await tester.pumpAndSettle();
    expect(f.files.platform.opened, hasLength(2));
    expect(find.textContaining('Hors ligne : copie du'), findsOneWidget);
  });

  testWidgets('no PDF viewer on the phone: said, and kept', (tester) async {
    final f = await setUpApp(tester);
    f.files.platform.canOpen = false;
    await openFinances(tester, const {
      'finances.cashbook': ['view', 'export'],
    });
    await tester.tap(find.byKey(const Key('export-cashbook')));
    await tester.pumpAndSettle();
    expect(f.finances.exports, ['cashbook']);
    expect(
      find.textContaining('Aucune application ne peut ouvrir'),
      findsOneWidget,
    );
    expect(
      f.files.store.downloads.single.name,
      startsWith('Livre de caisse 20'),
    );
  });

  testWidgets('Téléchargements lists, opens and deletes', (tester) async {
    final f = await setUpApp(tester);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MsgApp(home: DownloadsScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('downloads-empty')), findsOneWidget);

    final kept = await f.files.store.keep(
      source: 'fin-report-2026-3',
      name: 'Rapport T3 2026.pdf',
      mime: 'application/pdf',
      data: Uint8List.fromList([1, 2]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rapport T3 2026.pdf'), findsOneWidget);
    await tester.tap(find.text('Rapport T3 2026.pdf'));
    await tester.pumpAndSettle();
    expect(f.files.platform.opened, hasLength(1));

    await tester.tap(find.byKey(Key('download-menu-${kept.path}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer sur le téléphone'));
    await tester.pumpAndSettle();
    expect(f.files.platform.saved, ['Rapport T3 2026.pdf']);
    expect(find.textContaining('sur le téléphone'), findsOneWidget);

    await tester.tap(find.byKey(Key('download-menu-${kept.path}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('download-delete')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('downloads-empty')), findsOneWidget);
  });
}

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
