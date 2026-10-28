import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/data/data_settings.dart';
import 'package:msg_gestion/data/offline.dart';
import 'package:msg_gestion/main.dart';
import 'package:msg_gestion/screens/account_screen.dart';

import 'fakes.dart';
import 'helpers.dart';

/// Mon compte → Stockage et données (owner, 2026-10-28).
void main() {
  Future<void> openScreen(WidgetTester tester) async {
    await tester.pumpWidget(MsgApp(home: AccountScreen(me: fakeMe())));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('open-storage')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('open-storage')));
    await tester.pumpAndSettle();
  }

  testWidgets('usage, saver, quality and auto-download', (tester) async {
    await setUpApp(tester);
    final d = DataSettings.instance
      ..countTraffic(sent: 2048, received: 3 * 1024 * 1024);
    await openScreen(tester);
    expect(find.text('Stockage et données'), findsOneWidget);
    expect(find.textContaining('2 Ko envoyés • 3.0 Mo reçus'), findsOneWidget);

    // Less mobile data: photos on mobile data are off and say why.
    d.network = 'mobile';
    expect(d.autoPhotos, isTrue);
    await tester.tap(find.byKey(const Key('data-saver')));
    await tester.pumpAndSettle();
    expect(d.dataSaver, isTrue);
    expect(d.autoPhotos, isFalse);
    expect(find.text('Désactivé : économie de données'), findsOneWidget);

    await tester.tap(find.byKey(const Key('upload-quality')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quality-high')));
    await tester.pumpAndSettle();
    expect(d.uploadQuality, 'high');
    // The saver still keeps photos standard on mobile data; Wi-Fi gets high.
    expect(d.uploadSize, (1024.0, 85));
    d.network = 'wifi';
    expect(d.uploadSize, (2048.0, 92));

    await tester.tap(find.byKey(const Key('auto-wifi')));
    await tester.pumpAndSettle();
    expect(d.autoPhotosWifi, isFalse);
    expect(d.autoPhotos, isFalse);

    // Reset the counters.
    await tester.tap(find.byKey(const Key('network-usage')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset-traffic')));
    await tester.pumpAndSettle();
    expect((d.bytesSent, d.bytesReceived), (0, 0));
  });

  testWidgets('clearing offline data keeps unsent changes', (tester) async {
    await setUpApp(tester);
    final o = OfflineState.instance;
    await o.remember('g1:/members/', {'x': 1});
    await o.enqueue(OutboxItem(method: 'POST', path: '/x/', kind: 'read'));
    await openScreen(tester);
    await tester.tap(find.byKey(const Key('manage-storage')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clear-offline')));
    await tester.pumpAndSettle();
    expect(o.has('g1:/members/'), isFalse);
    expect(o.pending, 1);
  });
}
