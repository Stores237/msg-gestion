import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Tests never reach the network: Plus Jakarta Sans falls back to the
/// default test font instead of being downloaded.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
