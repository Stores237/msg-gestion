import 'package:flutter/foundation.dart';

import '../models/me.dart';

/// The logged-in member, for screens pushed above the shell (a profile
/// opened from a list) that need to know what the viewer may do.
/// Set by ShellScreen; cleared on sign-out.
final currentUser = ValueNotifier<Me?>(null);
