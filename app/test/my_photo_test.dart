// Every member changes their own profile picture (owner, 2026-10-23).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/widgets/my_photo.dart';
import 'package:msg_gestion/widgets/ui.dart';

import 'fakes.dart';
import 'helpers.dart';

Iterable<String?> _photos(WidgetTester tester) => tester
    .widgetList<MemberAvatar>(find.byType(MemberAvatar))
    .map((a) => a.photo);

void main() {
  testWidgets('pick, upload, shown on Mon compte and Accueil, then remove', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    pickPhoto = (_) async => (const [1, 2, 3], 'moi.jpg');
    addTearDown(() => pickPhoto = (_) async => null);
    await pumpShell(tester, fakeMe()); // a plain member
    await tester.tap(find.byKey(const Key('open-account')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('my-photo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photo-remove')), findsNothing);
    await tester.tap(find.byKey(const Key('photo-gallery')));
    await tester.pumpAndSettle();
    expect(f.profile.photos, ['moi.jpg']);
    expect(find.text('Photo enregistrée.'), findsOneWidget);
    expect(_photos(tester), contains('https://example.test/moi.jpg'));

    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    expect(
      _photos(tester),
      contains('https://example.test/moi.jpg'),
    ); // Accueil

    await tester.tap(find.byKey(const Key('open-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('change-photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo-remove')));
    await tester.pumpAndSettle();
    expect(f.profile.photos.last, 'removed');
    expect(_photos(tester).whereType<String>(), isEmpty);
  });
}
