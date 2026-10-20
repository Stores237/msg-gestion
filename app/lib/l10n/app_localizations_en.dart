// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MSG Gestion';

  @override
  String get movementName => 'Swiss Guard Movement';

  @override
  String get parishName => 'Our Lady of Lourdes Parish, Yapoma';

  @override
  String get motto => 'Service · Order · Welcome';

  @override
  String get splashPreparing => 'Preparing your data…';

  @override
  String get welcome => 'Welcome';

  @override
  String get loginIntro =>
      'Sign in with the phone number registered with the movement.';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get phoneHint => 'Format: 6 XX XX XX XX (+237)';

  @override
  String get phoneInvalid =>
      'Format: 6 XX XX XX XX, or the full international number.';

  @override
  String get continueButton => 'Continue';

  @override
  String get noAccountNotice =>
      'No account yet? The general secretary registers you at the Saturday meeting.';

  @override
  String get pinTitle => 'Your PIN';

  @override
  String pinGreeting(String firstName) {
    return 'Hello $firstName, enter your 4 digits.';
  }

  @override
  String get pinForgot => 'Forgot your PIN?';

  @override
  String get pinForgotHelp =>
      'Ask the general secretary to reset your PIN at the meeting.';

  @override
  String get keypadFingerprint => 'Fingerprint';

  @override
  String get keypadDelete => 'Delete';

  @override
  String get back => 'Back';

  @override
  String get networkError => 'Can’t connect. Check your network and try again.';

  @override
  String get serverError =>
      'The server isn’t responding properly. Try again in a moment.';

  @override
  String get retry => 'Retry';

  @override
  String helloName(String firstName) {
    return 'Hello $firstName';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get tabHome => 'Home';

  @override
  String get tabMembers => 'Members';

  @override
  String get tabFinances => 'Finances';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabAnnouncements => 'Announcements';

  @override
  String get comingSoonTitle => 'Coming soon';

  @override
  String get comingSoonBody =>
      'This tab arrives in a future version of the app.';

  @override
  String get myRoles => 'My roles';

  @override
  String get logout => 'Sign out';

  @override
  String syncOk(String time) {
    return 'Synced · last sync $time';
  }

  @override
  String ageYears(int age) {
    return '$age years old';
  }

  @override
  String get noRole => 'No active role';
}
