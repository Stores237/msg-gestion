import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/file_store.dart';
import '../data/offline.dart';
import '../data/repositories/auth_repository.dart';
import '../l10n/app_localizations.dart';

/// Turns any failure into a sentence in the member's language. A tap that
/// fails must never look like nothing happened (playbook §8).
String describeError(BuildContext context, Object error) {
  final l = AppLocalizations.of(context);
  return switch (error) {
    WrongPin(:final attemptsLeft) => l.errorWrongPin(attemptsLeft),
    WrongFinanceCode(:final attemptsLeft) => l.financeCodeWrong(attemptsLeft),
    AccountLocked(:final minutes) => l.errorLocked(minutes),
    UnknownMember() => l.errorUnknownMember,
    NoPinSet() => l.errorNoPin,
    BackofficeOnly() => l.errorBackofficeOnly,
    TermsRequired() => l.termsRequired,
    ApiException(code: 'terms_required') => l.termsRequired,
    ApiException(code: 'backoffice_only') => l.errorBackofficeOnly,
    ApiException(code: 'no_group') => l.errorNoGroup,
    ApiException(code: 'pin_gone') => l.pinGone,
    QueuedOffline() => l.savedOnPhone,
    NetworkException() => l.networkError,
    FileUnavailable() => l.networkError,
    ApiException(statusCode: 403) => l.errorForbidden,
    ApiException(code: 'pin_too_simple') => l.pinTooSimple,
    ApiException(code: 'same_as_pin') => l.financeCodeSameAsPin,
    ApiException(code: 'bad_code') => l.badCode,
    ApiException(code: 'sms_unavailable') => l.smsUnavailable,
    ApiException(code: 'storage_unavailable') => l.storageUnavailable,
    ApiException(code: 'report_empty') => l.reportEmpty,
    ApiException(code: 'report_locked') => l.reportLocked,
    ApiException(code: 'report_read') => l.reportReadLocked,
    ApiException(code: 'not_on_duty') => l.notOnDuty,
    ApiException(code: 'too_early') => l.reportTooEarly,
    ApiException(code: 'date_passed') => l.errorDatePassed,
    ApiException(code: 'member_required') => l.memberRequiredError,
    ApiException(code: 'description_required') => l.descriptionRequired,
    ApiException(code: 'linked_entry') => l.linkedEntryNote,
    ApiException(code: 'reason_required') => l.sendBackReason,
    ApiException(code: 'other_device') => l.signedOutOtherDevice,
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
