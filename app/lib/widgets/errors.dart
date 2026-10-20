import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../l10n/app_localizations.dart';

/// Turns any failure into a sentence a member can act on. A tap that fails
/// must never look like nothing happened (playbook §8).
String describeError(BuildContext context, Object error) {
  final l = AppLocalizations.of(context);
  if (error is NetworkException) return l.networkError;
  if (error is ApiException) return error.detail ?? l.serverError;
  return l.serverError;
}

void showErrorSnack(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(describeError(context, error))));
}
