import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

/// Open a link, a phone call (tel:) or an SMS (sms:); say so if it can't.
Future<void> openUri(BuildContext context, Uri uri) async {
  final l = AppLocalizations.of(context);
  final ok = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  ).catchError((_) => false);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.openFileFailed)));
  }
}

/// "+237 6 77 45 21 08" → tel:+237677452108
Uri telUri(String phone) => Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
Uri smsUri(String phone) => Uri(scheme: 'sms', path: phone.replaceAll(' ', ''));
