import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/main.dart';
import 'package:msg_gestion/models/announcement.dart';
import 'package:msg_gestion/screens/announcements/compose_screen.dart';
import 'package:msg_gestion/widgets/ui.dart';

import 'helpers.dart';

/// Choosing who is notified (owner, 2026-10-29): the tagged members get the
/// notification; the announcement stays visible to everyone.
/// Brings the composer's "Notifier" row above the bottom send bar.
Future<void> _showNotifyRow(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('a-notify')));
  await tester.drag(find.byType(ListView).first, const Offset(0, -300));
  await tester.pumpAndSettle();
}

void main() {
  Widget opener() => MsgApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          key: const Key('open'),
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ComposeScreen())),
          child: const Text('open'),
        ),
      ),
    ),
  );

  testWidgets('composer: tag two members, untag one, send with the rest', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await tester.pumpWidget(opener());
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('a-title')), 'Clés');
    expect(find.text('Notifier : tous les membres'), findsOneWidget);

    await _showNotifyRow(tester);
    await tester.tap(find.byKey(const Key('a-notify')));
    await tester.pumpAndSettle();
    expect(find.text('Qui notifier ?'), findsOneWidget);
    // Search ignores accents.
    await tester.enterText(find.byKey(const Key('recipients-search')), 'kevin');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipient-12')), findsNothing);
    await tester.tap(find.byKey(const Key('recipient-11')));
    await tester.enterText(find.byKey(const Key('recipients-search')), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recipient-12')));
    await tester.pumpAndSettle();
    expect(find.text('Valider (2)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('recipients-done')));
    await tester.pumpAndSettle();

    expect(find.text('Notifier : 2 membres'), findsOneWidget);
    await _showNotifyRow(tester);
    expect(find.text('Essomba Kévin'), findsOneWidget);
    await tester.tap(find.byTooltip('Retirer Mbarga Rose'));
    await tester.pumpAndSettle();
    expect(find.text('Notifier : 1 membre'), findsOneWidget);

    await tester.tap(find.byKey(const Key('a-send')));
    await tester.pumpAndSettle();
    expect(f.announcements.lastTagged, [11]);
  });

  testWidgets('"Tout le monde" clears the choice', (tester) async {
    final f = await setUpApp(tester);
    await tester.pumpWidget(opener());
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('a-title')), 'Répétition');
    await _showNotifyRow(tester);
    await tester.tap(find.byKey(const Key('a-notify')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recipient-13')));
    await tester.tap(find.byKey(const Key('recipients-everyone')));
    await tester.pumpAndSettle();
    expect(find.text('Notifier : tous les membres'), findsOneWidget);
    await tester.tap(find.byKey(const Key('a-send')));
    await tester.pumpAndSettle();
    expect(f.announcements.lastTagged, isEmpty);
  });

  testWidgets('card: "Pour vous" and who it is for', (tester) async {
    await setUpApp(tester);
    Announcement item({required bool forMe}) => Announcement(
      id: 5,
      kind: 'annonce',
      title: 'Clés de la sacristie',
      body: '',
      pinned: false,
      createdAt: DateTime(2026, 10, 29),
      unread: true,
      forMe: forMe,
      tagged: const [
        TaggedMember(1, 'Essomba K.'),
        TaggedMember(2, 'Mbarga R.'),
        TaggedMember(3, 'Ndi P.'),
        TaggedMember(4, 'Fotso I.'),
      ],
    );
    await tester.pumpWidget(
      MsgApp(
        home: Scaffold(
          body: AnnouncementCard(item: item(forMe: true), onTap: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('announcement-for-me')), findsOneWidget);
    // The feed card shortens the list; the announcement itself shows all.
    expect(
      find.text('Pour : Essomba K., Mbarga R., Ndi P. +1'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      MsgApp(
        home: Scaffold(
          body: AnnouncementCard(key: UniqueKey(), item: item(forMe: false)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('announcement-for-me')), findsNothing);
    expect(
      find.text('Pour : Essomba K., Mbarga R., Ndi P., Fotso I.'),
      findsOneWidget,
    );
  });
}
