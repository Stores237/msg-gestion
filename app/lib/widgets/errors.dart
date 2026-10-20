import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/repositories/auth_repository.dart';
import '../l10n/app_localizations.dart';

/// Turns any failure into a sentence in the member's language. A tap that
/// fails must never look like nothing happened (playbook §8).
String describeError(BuildContext context, Object error) {
  final l = AppLocalizations.of(context);
  return switch (error) {
    WrongPin(:final attemptsLeft) => l.errorWrongPin(attemptsLeft),
    AccountLocked(:final minutes) => l.errorLocked(minutes),
    UnknownMember() => l.errorUnknownMember,
    NoPinSet() => l.errorNoPin,
    NetworkException() => l.networkError,
    ApiException(statusCode: 403) => l.errorForbidden,
    ApiException(code: 'pin_too_simple') => l.pinTooSimple,
    ApiException(code: 'bad_code') => l.badCode,
    ApiException(code: 'sms_unavailable') => l.smsUnavailable,
    // Server-side validation messages are written for people; show them
    // when there is no code to translate.
    ApiException(:final detail?) => detail,
    _ => l.serverError,
  };
}

void showErrorSnack(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(describeError(context, error))));
}
