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

  @override
  String get errorUnknownMember =>
      'This number isn’t registered. The general secretary registers you at the Saturday meeting.';

  @override
  String errorWrongPin(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Wrong PIN. $n attempts left.',
      one: 'Wrong PIN. 1 attempt left.',
    );
    return '$_temp0';
  }

  @override
  String errorLocked(int minutes) {
    return 'Account locked after too many attempts. Try again in $minutes min.';
  }

  @override
  String get errorNoPin =>
      'This account has no PIN yet. Ask the general secretary to set one.';

  @override
  String get errorForbidden => 'Your role doesn’t allow this action.';

  @override
  String get language => 'Language';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get roleSuperAdmin => 'Super admin';

  @override
  String get rolePresident => 'President';

  @override
  String get roleSecretaryGeneral => 'General secretary';

  @override
  String get roleTreasurer => 'Treasurer';

  @override
  String get roleAuditor => 'Auditor';

  @override
  String get roleHeadCensor => 'Head censor';

  @override
  String get roleTrainer => 'Trainer';

  @override
  String get roleAdviser => 'Adviser';

  @override
  String get roleGroupLeader => 'Group leader';

  @override
  String get roleCensorOfTheDay => 'Censor of the day';

  @override
  String get roleMember => 'Member';

  @override
  String get roleGuard => 'Guard';

  @override
  String get seeAll => 'See all';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get search => 'Search';

  @override
  String get required => 'This field is required.';

  @override
  String get restrictedTitle => 'Restricted';

  @override
  String get pullToRefresh => 'Pull to refresh';

  @override
  String get loadError => 'Couldn’t load';

  @override
  String get statusActive => 'Active';

  @override
  String get statusLeave => 'On leave';

  @override
  String get statusRetired => 'Retired';

  @override
  String get statusSuspended => 'Suspended';

  @override
  String get diaspora => 'Diaspora';

  @override
  String get minor => 'Minor';

  @override
  String membersSubtitle(int n) {
    return '$n guards';
  }

  @override
  String get membersSearchHint => 'Search a name, a number…';

  @override
  String filterAll(int n) {
    return 'All $n';
  }

  @override
  String filterActive(int n) {
    return 'Active $n';
  }

  @override
  String filterLeave(int n) {
    return 'On leave $n';
  }

  @override
  String filterRetired(int n) {
    return 'Retired $n';
  }

  @override
  String filterDiaspora(int n) {
    return 'Diaspora $n';
  }

  @override
  String get theBureau => 'The bureau';

  @override
  String get theBureauSub => 'Bureau roles and mandates';

  @override
  String mandateUntil(String date) {
    return 'Mandate until $date';
  }

  @override
  String guardSince(int year) {
    return 'Guard · since $year';
  }

  @override
  String get noMembersFound => 'No member matches.';

  @override
  String get addMember => 'Add';

  @override
  String get profile => 'Profile';

  @override
  String get information => 'Information';

  @override
  String get phone => 'Phone';

  @override
  String get joinedOn => 'Joined on';

  @override
  String get birthDate => 'Date of birth';

  @override
  String get parentOrGuardian => 'Parent or guardian';

  @override
  String get contributions => 'Contributions';

  @override
  String get restrictedMinorContacts =>
      'Minors’ contact details are visible to the president and the general secretary only.';

  @override
  String get restrictedContributions =>
      'Contribution history is reserved for the treasurer, the auditor and the president.';

  @override
  String get call => 'Call';

  @override
  String get newMember => 'New member';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get firstNamesLabel => 'First names';

  @override
  String get birthDateHint => 'Pick a date';

  @override
  String ageMinorHint(int age) {
    return '$age years old · parent contact required';
  }

  @override
  String get diasporaMember => 'Diaspora member';

  @override
  String get cityCountry => 'City, country';

  @override
  String get parentName => 'Parent or guardian’s name';

  @override
  String get parentRelation => 'Relationship (mother, father, guardian…)';

  @override
  String get parentPhone => 'Parent or guardian’s phone';

  @override
  String get parentRequired => 'Required for a minor.';

  @override
  String get phoneTaken => 'This number already belongs to a member.';

  @override
  String get saveMember => 'Save member';

  @override
  String get memberSavedTitle => 'Member saved';

  @override
  String memberSavedPin(String name, String pin) {
    return '$name’s temporary PIN: $pin. Give it to them in person; it won’t be shown again.';
  }

  @override
  String get monthView => 'Month';

  @override
  String get agendaView => 'Agenda';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get newEvent => 'New event';

  @override
  String get noEventsDay => 'Nothing planned that day.';

  @override
  String get noEventsUpcoming => 'No upcoming events.';

  @override
  String get kindAssise => 'Saturday meeting';

  @override
  String get kindMass => 'Mass';

  @override
  String get kindOutsideService => 'Outside service';

  @override
  String get kindVigil => 'Night vigil';

  @override
  String get kindMeeting => 'Meeting';

  @override
  String get kindOther => 'Other';

  @override
  String get dressInside => 'Indoor uniform';

  @override
  String get dressOutside => 'Outdoor uniform';

  @override
  String get dressSport => 'Sportswear';

  @override
  String get dressCivil => 'Civilian clothes';

  @override
  String get dressNone => 'No dress code';

  @override
  String get myPresence => 'My attendance';

  @override
  String get presenceNotMarked => 'Not marked yet';

  @override
  String get presenceNotMarkedSub => 'The censor takes the roll call on site';

  @override
  String get presencePresent => 'Present';

  @override
  String get presenceAbsent => 'Absent';

  @override
  String get presenceExcused => 'Excused';

  @override
  String get warnAbsence => 'Report an absence';

  @override
  String get absenceReason => 'Reason (optional)';

  @override
  String get absenceSent => 'Absence reported to the censor.';

  @override
  String get alreadyMarked => 'The censor has already marked your attendance.';

  @override
  String get takeRollCall => 'Take the roll call';

  @override
  String rollCallTitle(String title) {
    return 'Roll call · $title';
  }

  @override
  String get statPresent => 'Present';

  @override
  String get statAbsent => 'Absent';

  @override
  String get statExcused => 'Excused';

  @override
  String get statRemaining => 'Remaining';

  @override
  String get remote => 'Remote';

  @override
  String get rollCallSaved => 'Roll call saved.';

  @override
  String unsavedChanges(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n unsaved changes',
      one: '1 unsaved change',
    );
    return '$_temp0';
  }

  @override
  String get eventKind => 'Type';

  @override
  String get eventTitle => 'Title';

  @override
  String get eventDate => 'Date';

  @override
  String get eventStart => 'Start';

  @override
  String get eventEnd => 'End (optional)';

  @override
  String get eventPlace => 'Place';

  @override
  String get eventDress => 'Dress code';

  @override
  String get eventNotes => 'Notes';

  @override
  String get eventEndBeforeStart => 'The end must be after the start.';

  @override
  String get eventCreated => 'Event added to the calendar.';

  @override
  String nightUntil(String time) {
    return '→ $time · overnight';
  }

  @override
  String get filterAnnAll => 'All';

  @override
  String get filterConvocations => 'Convocations';

  @override
  String filterUnread(int n) {
    return 'Unread $n';
  }

  @override
  String get filterSent => 'Sent';

  @override
  String get kindAnnouncement => 'Announcement';

  @override
  String get kindConvocation => 'Convocation';

  @override
  String get pinned => 'Pinned';

  @override
  String get unreadDot => 'Unread';

  @override
  String readBy(int read, int total) {
    return 'Read by $read of $total';
  }

  @override
  String get compose => 'Write';

  @override
  String get newAnnouncement => 'New announcement';

  @override
  String get message => 'Message';

  @override
  String get linkedEvent => 'Linked event';

  @override
  String get chooseEvent => 'Choose an event';

  @override
  String get eventRequired => 'A convocation must be linked to an event.';

  @override
  String get pinOnTop => 'Pin to the top of the feed';

  @override
  String get recipientsAll => 'All members';

  @override
  String get sendAnnouncement => 'Publish announcement';

  @override
  String get sendConvocation => 'Send convocation';

  @override
  String get announcementSent => 'Published.';

  @override
  String get allRead => 'All caught up';

  @override
  String get allReadBody =>
      'New announcements and convocations from the bureau will appear here.';

  @override
  String get noAnnouncements => 'No announcements';

  @override
  String get readReceipts => 'Read receipts';

  @override
  String notReadYet(int n) {
    return 'Not read $n';
  }

  @override
  String readTab(int n) {
    return 'Read $n';
  }

  @override
  String get nextMeeting => 'Next meeting';

  @override
  String get lastAnnouncement => 'Latest announcement';

  @override
  String get nothingPlanned => 'Nothing planned yet.';

  @override
  String get calendarLink => 'Calendar';

  @override
  String get allAnnouncements => 'All';

  @override
  String get myAccount => 'My account';

  @override
  String get readStatus => 'Read';

  @override
  String get openAccount => 'Open my account';

  @override
  String unreadCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n unread announcements',
      one: '1 unread announcement',
    );
    return '$_temp0';
  }
}
