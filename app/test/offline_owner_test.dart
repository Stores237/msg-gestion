import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/data/offline.dart';
import 'package:msg_gestion/main.dart';
import 'package:msg_gestion/screens/account_screen.dart';

import 'fakes.dart';
import 'helpers.dart';

/// Security check 2026-10-26: a phone passed between members never shows
/// the previous one's offline data.
void main() {
  test('another account signing in erases the offline copy', () async {
    final disk = MemoryOfflineStorage();
    final o = OfflineState(storage: disk);
    await o.belongsTo(7);
    await o.remember('g1:/finances/entries/', {'secret': 1});
    await o.enqueue(OutboxItem(method: 'POST', path: '/x/', kind: 'read'));
    await o.belongsTo(7); // the same member again: kept
    expect(o.has('g1:/finances/entries/'), isTrue);
    expect(o.pending, 1);
    await o.belongsTo(8);
    expect(o.has('g1:/finances/entries/'), isFalse);
    expect(o.pending, 0);
    // Written to disk too, not only in memory.
    final reloaded = OfflineState(storage: disk);
    await reloaded.load();
    expect(reloaded.has('g1:/finances/entries/'), isFalse);
    expect(reloaded.pending, 0);
  });

  testWidgets('sign-out erases the offline copy, after asking if unsent', (
    tester,
  ) async {
    await setUpApp(tester);
    final o = OfflineState.instance;
    await o.remember('g1:/members/', {'x': 1});
    await o.enqueue(OutboxItem(method: 'POST', path: '/x/', kind: 'read'));
    await tester.pumpWidget(MsgApp(home: AccountScreen(me: fakeMe())));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('logout')), 200);
    await tester.tap(find.byKey(const Key('logout')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('1 modification n’est pas encore envoyée'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('logout-confirm')));
    await tester.pumpAndSettle();
    expect(o.has('g1:/members/'), isFalse);
    expect(o.pending, 0);
  });
}
