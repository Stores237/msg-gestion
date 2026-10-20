import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msg_gestion/data/offline.dart';

/// Tests never reach the network: Plus Jakarta Sans falls back to the
/// default test font instead of being downloaded. Every test starts with
/// an empty offline cache and outbox (they are app-wide singletons).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(
    () => OfflineState.debugSetInstance(
      OfflineState(storage: MemoryOfflineStorage()),
    ),
  );
  await testMain();
}
