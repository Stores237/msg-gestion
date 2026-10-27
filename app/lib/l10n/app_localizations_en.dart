// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MSG';

  @override
  String get motto => 'Service · Order · Welcome';

  @override
  String get splashPreparing => 'Preparing your data…';

  @override
  String get welcome => 'Welcome';

  @override
  String get loginIntro =>
      'Sign in with the phone number registered with your group.';

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
      'No account yet? Ask your group’s organiser to register you.';

  @override
  String get pinTitle => 'Your PIN';

  @override
  String pinGreeting(String firstName) {
    return 'Hello $firstName, enter your 4 digits.';
  }

  @override
  String get pinForgot => 'Forgot your PIN?';

  @override
  String get pinForgotHelp => 'Ask your group’s organiser to reset your PIN.';

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
  String get tabAnnouncements => 'News';

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
      'This number isn’t registered. Ask your group’s organiser to register you.';

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
      'This account has no PIN yet. Ask your group’s organiser to set one.';

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

  @override
  String get changePin => 'Change my PIN';

  @override
  String get choosePinTitle => 'Choose your PIN';

  @override
  String get choosePinForced =>
      'Your current PIN is temporary. Choose a 4-digit PIN only you know.';

  @override
  String get currentPin => 'Current PIN';

  @override
  String get newPin => 'New PIN';

  @override
  String get confirmPin => 'Confirm the new PIN';

  @override
  String get pinMismatch => 'The two PINs don’t match.';

  @override
  String get pinFourDigits => '4 digits.';

  @override
  String get pinTooSimple => 'PIN too simple (1111, 1234…). Pick another one.';

  @override
  String get pinChanged => 'PIN changed.';

  @override
  String get forgotTitle => 'Forgotten PIN';

  @override
  String get forgotIntro => 'We’ll text a code to the account’s number.';

  @override
  String get sendCode => 'Send the code';

  @override
  String get smsCode => 'Code received by SMS';

  @override
  String get badCode => 'Wrong or expired code.';

  @override
  String get smsUnavailable =>
      'Text messages aren’t available yet. Ask your group’s organiser to reset your PIN.';

  @override
  String get resetPin => 'Reset PIN';

  @override
  String resetPinConfirm(String name) {
    return 'A new temporary PIN will be created for $name. The old one will stop working.';
  }

  @override
  String resetPinDone(String name, String pin) {
    return '$name’s new temporary PIN: $pin. Give it in person; it won’t be shown again.';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get attachFile => 'Attach a file (PDF, photo)';

  @override
  String get attachHint => 'PDF, JPEG or PNG · 10 MB max';

  @override
  String get fileTooLarge => 'File too large (10 MB max).';

  @override
  String get fileType => 'Only PDF, JPEG and PNG files are accepted.';

  @override
  String attachmentFailed(String name) {
    return 'Announcement published, but “$name” couldn’t be attached.';
  }

  @override
  String get openFileFailed => 'Couldn’t open the file.';

  @override
  String get removeFile => 'Remove';

  @override
  String sizeKb(int n) {
    return '$n KB';
  }

  @override
  String sizeMb(String n) {
    return '$n MB';
  }

  @override
  String get cashBalance => 'Cash balance';

  @override
  String validatedUntil(String date) {
    return 'Validated up to $date';
  }

  @override
  String withPending(String amount) {
    return '$amount including entries awaiting validation';
  }

  @override
  String get cashBook => 'Cash book';

  @override
  String get solidarity => 'Solidarity';

  @override
  String get report => 'Report';

  @override
  String get newEntry => 'New entry';

  @override
  String get entryButton => 'Entry';

  @override
  String get directionIn => 'Income';

  @override
  String get directionOut => 'Expense';

  @override
  String get amount => 'Amount';

  @override
  String get category => 'Category';

  @override
  String get catRegistration => 'Registrations';

  @override
  String get catFine => 'Fines';

  @override
  String get catDonation => 'Aid and donations';

  @override
  String get catSolidarity => 'Solidarity contributions';

  @override
  String get catExpense => 'Expenses';

  @override
  String get member => 'Member';

  @override
  String get memberOptional => 'Member (optional)';

  @override
  String get chooseMember => 'Choose a member';

  @override
  String get description => 'Description';

  @override
  String get amountRequired => 'Enter an amount.';

  @override
  String get willBeValidated => 'Will be validated by the auditor.';

  @override
  String enteredBy(String name, String when) {
    return 'Entered by $name · $when';
  }

  @override
  String validatedBy(String name) {
    return 'Validated by $name';
  }

  @override
  String get toValidate => 'To validate';

  @override
  String get validated => 'Validated';

  @override
  String get notSentYet => 'Not sent yet';

  @override
  String get validateEntryTitle => 'Validate this entry?';

  @override
  String get validateEntryBody =>
      'Your name and the time will be recorded. A validated entry can no longer be changed.';

  @override
  String get validate => 'Validate';

  @override
  String get entryValidated => 'Entry validated.';

  @override
  String get entrySaved => 'Entry saved, awaiting validation.';

  @override
  String get ownEntry => 'You can’t validate your own entry.';

  @override
  String get noEntries => 'No entries yet.';

  @override
  String get collections => 'Collections';

  @override
  String get newCollection => 'New collection';

  @override
  String get collectionKind => 'Reason';

  @override
  String get kindDeath => 'Bereavement';

  @override
  String get kindIllness => 'Illness';

  @override
  String get kindMedal => 'Medal, diploma, sacrament';

  @override
  String get amountPerMember => 'Amount per member';

  @override
  String paidFullOf(int paid, int total) {
    return '$paid of $total have paid in full';
  }

  @override
  String tranchesInfo(String parts) {
    return 'Instalments of $parts, one a week over a month.';
  }

  @override
  String filterToPay(int n) {
    return 'To pay $n';
  }

  @override
  String filterPaid(int n) {
    return 'Paid $n';
  }

  @override
  String thirdsOf3(int n) {
    return '$n/3 instalments';
  }

  @override
  String get paidInFull => 'Paid';

  @override
  String savePayments(int n, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Save $n payments · $amount',
      one: 'Save 1 payment · $amount',
    );
    return '$_temp0';
  }

  @override
  String get paymentsSaved => 'Payments saved.';

  @override
  String get closeCollection => 'Close the collection';

  @override
  String get closeCollectionBody =>
      'Remaining members will be marked “unpaid”.';

  @override
  String get closed => 'Closed';

  @override
  String get noCollections => 'No collections.';

  @override
  String quarterReport(int q, int year) {
    return 'Q$q $year report';
  }

  @override
  String get summary => 'Summary';

  @override
  String get openingBalance => 'Opening balance';

  @override
  String get closingBalance => 'Closing balance';

  @override
  String get incomeLabel => 'Income';

  @override
  String get expenseLabel => 'Expenses';

  @override
  String get incomeByCategory => 'Income by category';

  @override
  String pendingBlock(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n entries still need checking before validating.',
      one: '1 entry still needs checking before validating.',
    );
    return '$_temp0';
  }

  @override
  String get validateReport => 'Validate the report';

  @override
  String reportValidatedBy(String name, String date) {
    return 'Validated by $name on $date';
  }

  @override
  String get previousQuarter => 'Previous quarter';

  @override
  String get nextQuarter => 'Next quarter';

  @override
  String get myContributions => 'My contributions';

  @override
  String get toPayLabel => 'To pay';

  @override
  String get nothingToPay => 'Nothing to pay. Thank you!';

  @override
  String remainingOf(String remaining, String total) {
    return '$remaining left of $total';
  }

  @override
  String get fine => 'Fine';

  @override
  String get planningView => 'Rota';

  @override
  String get myDutiesView => 'My duties';

  @override
  String weekOf(String start, String end) {
    return 'Week of $start to $end';
  }

  @override
  String get previousWeek => 'Previous week';

  @override
  String get nextWeek => 'Next week';

  @override
  String get postPremiereCentrale => 'First central';

  @override
  String get postDeuxiemeCentrale => 'Second central';

  @override
  String get postControle => 'Control';

  @override
  String get postPetitesPortes => 'Side doors';

  @override
  String get postMesanie => 'Mésanie';

  @override
  String get sidePariso => 'Pariso';

  @override
  String get sideYapoma => 'Yapoma';

  @override
  String get freeSlot => '+ Free';

  @override
  String chefLabel(String name) {
    return 'Lead: $name';
  }

  @override
  String filledOf(int filled, int size) {
    return '$filled/$size';
  }

  @override
  String alertsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n alerts',
      one: '1 alert',
    );
    return '$_temp0';
  }

  @override
  String alertUnderstaffed(String title, int filled, int size) {
    return '$title: $filled of $size';
  }

  @override
  String alertDouble(String name) {
    return '$name has two duties the same day';
  }

  @override
  String alertOnLeave(String name) {
    return '$name is on leave';
  }

  @override
  String get publishAndNotify => 'Publish and notify';

  @override
  String get published => 'Published';

  @override
  String publishedDone(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Rota published · $n guards notified.',
      one: 'Rota published · 1 guard notified.',
    );
    return '$_temp0';
  }

  @override
  String get noServicesWeek => 'No duties planned this week.';

  @override
  String get setServiceSize => 'Plan the duty';

  @override
  String get serviceSize => 'Number of guards';

  @override
  String get assignGroup => 'Assign a group';

  @override
  String groupAssigned(int assigned, int empty) {
    return '$assigned slots filled · $empty still free';
  }

  @override
  String groupMembersInfo(int n, int available) {
    return '$n guards · $available available';
  }

  @override
  String get leastSolicitedFirst => 'Least solicited first';

  @override
  String servicesThisMonth(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n duties this month',
      one: '1 duty this month',
      zero: 'No duty this month',
    );
    return '$_temp0';
  }

  @override
  String get flagBusy => 'Already on duty that day';

  @override
  String get flagLeave => 'On leave';

  @override
  String get flagMany => 'Many duties already this month';

  @override
  String get assign => 'Assign';

  @override
  String get assignAnyway => 'Anyway';

  @override
  String get clearSlot => 'Free the slot';

  @override
  String get dutyPending => 'To confirm';

  @override
  String get dutyConfirmed => 'Confirmed';

  @override
  String get dutySwap => 'Swap requested';

  @override
  String get dutyReplaced => 'Replaced';

  @override
  String get dutyAbsent => 'Absence reported';

  @override
  String get conflict => 'Conflict';

  @override
  String get confirmDuty => 'Confirm';

  @override
  String get swapDuty => 'Swap';

  @override
  String get swapTitle => 'Swap my duty';

  @override
  String get withWhom => 'With whom?';

  @override
  String get reasonOptional => 'Reason (optional)';

  @override
  String get sendRequest => 'Send the request';

  @override
  String get declareAbsence => 'I can’t make it';

  @override
  String get requestSent => 'Request sent.';

  @override
  String get noDuties => 'No duties planned for you.';

  @override
  String get myNextDuty => 'My next duty';

  @override
  String get requests => 'Requests';

  @override
  String requestsPending(int n) {
    return '$n pending';
  }

  @override
  String swapForYou(String name) {
    return '$name offers you their duty';
  }

  @override
  String get accept => 'Accept';

  @override
  String get refuse => 'Decline';

  @override
  String get approve => 'Approve';

  @override
  String swapLine(String from, String to) {
    return '$from ⇄ $to';
  }

  @override
  String absenceLine(String name) {
    return 'Absence · $name';
  }

  @override
  String get chooseReplacement => 'Choose a replacement';

  @override
  String get noRequests => 'No pending requests.';

  @override
  String get albs => 'Alb washing';

  @override
  String albsWeek(String date) {
    return 'Week of $date';
  }

  @override
  String albsCount(int n) {
    return '$n albs';
  }

  @override
  String get albToWash => 'To wash';

  @override
  String get albWashed => 'Washed';

  @override
  String get albReturned => 'Returned';

  @override
  String get markWashed => 'Mark as washed';

  @override
  String get markReturned => 'Mark as returned';

  @override
  String get nextWeeks => 'Next weeks';

  @override
  String get fairness12 => 'Fairness · washes over 12 months';

  @override
  String get scheduleAlbs => 'Schedule a week';

  @override
  String responsible(String name) {
    return 'Responsible: $name';
  }

  @override
  String get noAlbs => 'No week scheduled.';

  @override
  String get group => 'Group';

  @override
  String get groups => 'Groups';

  @override
  String get planned => 'Planned';

  @override
  String get notificationsEmpty => 'No notifications.';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This week';

  @override
  String get earlier => 'Earlier';

  @override
  String get offlineBar => 'Offline';

  @override
  String offlinePending(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Offline · $n entries waiting to be sent',
      one: 'Offline · 1 entry waiting to be sent',
    );
    return '$_temp0';
  }

  @override
  String syncedAt(String time) {
    return 'Synced · last sync $time';
  }

  @override
  String get syncing => 'Syncing…';

  @override
  String offlineSince(String time) {
    return 'Offline · last sync $time';
  }

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get savedOnPhone =>
      'Saved on the phone. It will be sent when the network is back.';

  @override
  String pendingSend(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sends waiting',
      one: '1 send waiting',
    );
    return '$_temp0';
  }

  @override
  String get never => 'never';

  @override
  String get addPhoto => 'Add a photo';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get photoSaved => 'Photo saved.';

  @override
  String get registrationFee => 'Registration fee paid';

  @override
  String get registrationFeeSub =>
      'Added to the cash book, awaiting validation';

  @override
  String get presenceLast4 => 'Attendance · last 4 meetings';

  @override
  String presenceSummary(int present, int absent, int excused) {
    return '$present present · $absent absent · $excused excused';
  }

  @override
  String lastOn(String date) {
    return 'Last: $date';
  }

  @override
  String get proposeRole => 'Propose a role';

  @override
  String get roleRequestSent => 'Request sent to the super admin.';

  @override
  String get fromDate => 'From';

  @override
  String get toDate => 'To (optional)';

  @override
  String get reasonRequired => 'Reason (logged)';

  @override
  String get reminders => 'Reminders';

  @override
  String get remindEve => 'The day before at 20:00';

  @override
  String get remind2h => '2 hours before';

  @override
  String remindUnread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Remind the $n unread members',
      one: 'Remind the unread member',
    );
    return '$_temp0';
  }

  @override
  String remindedDone(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n members reminded.',
      one: '1 member reminded.',
    );
    return '$_temp0';
  }

  @override
  String get exportPdf => 'Export as PDF';

  @override
  String get toFollow => 'To follow up';

  @override
  String get activeMembers => 'Active members';

  @override
  String entriesToValidate(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n entries to validate',
      one: '1 entry to validate',
    );
    return '$_temp0';
  }

  @override
  String get awaitingAuditor => 'Waiting for the auditor';

  @override
  String unfilledSlots(int n, String title) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n unfilled posts',
      one: '1 unfilled post',
    );
    return '$_temp0 · $title';
  }

  @override
  String get roleVicePresident => 'Vice-president';

  @override
  String get roleSecretaryGeneralDeputy => 'Deputy general secretary';

  @override
  String get roleFormateurDeputy => 'Deputy trainer';

  @override
  String get designateChef => 'Choose the group lead';

  @override
  String get chefSheetHint => 'From this service\'s guards.';

  @override
  String get removeChef => 'Remove the group lead';

  @override
  String get noChefYet => 'No group lead yet';

  @override
  String get youAreChef => 'You are the group lead';

  @override
  String get chefNeedsGuards => 'Assign guards to this service first.';

  @override
  String get statementPdf => 'Members\' balance statement (PDF)';

  @override
  String get memberStatementPdf => 'Financial statement (PDF)';

  @override
  String get errorBackofficeOnly =>
      'Back-office accounts (super admin, support, IT and integration teams) work only in the back-office (web browser), not in the app.';

  @override
  String get requestAccess => 'Request access';

  @override
  String get accessRequestsTitle => 'Access requests';

  @override
  String get accessRole => 'Requested role';

  @override
  String get accessNote => 'Note for the partner (optional)';

  @override
  String get sendAccessRequest => 'Send the request';

  @override
  String get accessSentTitle => 'Request sent';

  @override
  String get accessSentBody =>
      'The MSG partner will create the access. You’ll be told here, with the temporary PIN to hand over.';

  @override
  String get accessIntro =>
      'The MSG partner opens the account. You’ll then receive the temporary PIN to hand over to the member.';

  @override
  String get accessPending => 'Pending';

  @override
  String get accessApproved => 'Access created';

  @override
  String get accessRefused => 'Refused';

  @override
  String get showTempPin => 'Show the temporary PIN';

  @override
  String get tempPinTitle => 'Temporary PIN';

  @override
  String tempPinBody(String name, String phone) {
    return 'Hand this PIN to $name ($phone). It won’t be shown again. At first sign-in they choose their own PIN and see their role.';
  }

  @override
  String get accessExistingAccount =>
      'Existing account: they sign in with their usual PIN.';

  @override
  String get pinGone =>
      'PIN already handed over or expired. Ask the partner for a reset.';

  @override
  String get noAccessRequests => 'No requests yet.';

  @override
  String get switchGroup => 'Switch group';

  @override
  String get chooseGroup => 'Choose a group';

  @override
  String get errorNoGroup =>
      'This account isn’t in any group yet. Ask your group’s organiser.';

  @override
  String get platformTagline =>
      'Your group, managed: members, cash book, calendar, duties, announcements.';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get appearance => 'Appearance';

  @override
  String get appColor => 'App colour';

  @override
  String get groupColorChoice => 'Group colour';

  @override
  String get appColorHint =>
      'For this phone. “Group colour” follows your group’s setting.';

  @override
  String colorN(int n) {
    return 'Colour $n';
  }

  @override
  String get myPhoto => 'Profile picture';

  @override
  String get photoFromGallery => 'Choose from gallery';

  @override
  String get photoFromCamera => 'Take a photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get photoRemoved => 'Photo removed.';

  @override
  String get requestDayRole => 'Request a role of the day';

  @override
  String get dayRoleHint =>
      'For an active member with no role, for one day. The partner approves; the role ends that night.';

  @override
  String onDay(String date) {
    return 'On $date';
  }

  @override
  String get dayRoleRequestSent => 'Request sent to the partner.';

  @override
  String get unlockTitle => 'Enter your PIN';

  @override
  String get unlockSubtitle => 'To open MSG.';

  @override
  String unlockWrong(int n) {
    return 'Wrong PIN. $n attempt(s) left.';
  }

  @override
  String get unlockTooMany =>
      'Too many attempts: sign in again with your number.';

  @override
  String get unlockSignInAgain =>
      'For your security, sign in once more with your number and PIN.';

  @override
  String get unlockOtherAccount => 'Sign in another way';

  @override
  String get biometricReason => 'Unlock MSG';

  @override
  String get biometricUnlock => 'Unlock with fingerprint or face';

  @override
  String get biometricUnavailable =>
      'No fingerprint or face is set up on this phone.';

  @override
  String get biometricHint => 'Your PIN always works too.';

  @override
  String get addedBy => 'Added by';

  @override
  String get storageUnavailable =>
      'The file couldn’t be sent: storage is unavailable. Try again later; if it keeps failing, tell the partner.';

  @override
  String get helpSection => 'Help';

  @override
  String get aboutSection => 'About';

  @override
  String get faq => 'FAQ';

  @override
  String get faqSub => 'Answers to common questions';

  @override
  String get helpSupport => 'Help & support';

  @override
  String get helpSupportSub => 'Call a real person';

  @override
  String get whatsappSupport => 'WhatsApp support';

  @override
  String get whatsappSupportSub => 'Chat with us on WhatsApp';

  @override
  String get contactUs => 'Contact us';

  @override
  String get contactUsSub => 'Questions or feedback';

  @override
  String get visitWebsite => 'Visit our website';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get notAvailableYet => 'Not available yet';

  @override
  String appVersion(String v) {
    return 'Version $v';
  }

  @override
  String get faqQ1 => 'I forgot my PIN.';

  @override
  String get faqA1 =>
      'On the PIN screen, tap “Forgot PIN?”. If text messages aren’t available, ask your group leader: they can give you a temporary PIN.';

  @override
  String get faqQ2 => 'Why does the app ask for my PIN every time it opens?';

  @override
  String get faqA2 =>
      'To protect the group’s data if someone picks up your phone. You can unlock with your fingerprint or face: My account → Unlock with fingerprint.';

  @override
  String get faqQ3 => 'I can’t see the Finances tab (or another one).';

  @override
  String get faqA3 =>
      'Tabs depend on your role in the group. When your role changes, they adapt the next time you open the app.';

  @override
  String get faqQ4 => 'How do I report an absence?';

  @override
  String get faqA4 =>
      'Open the activity in the Calendar and tap “Report an absence”, with the reason.';

  @override
  String get faqQ5 => 'What is a role of the day?';

  @override
  String get faqA5 =>
      'An active member with no role can be given a role such as president, censor or treasurer for one day. It is requested in the app and approved by the partner; it ends that night.';

  @override
  String get faqQ6 => 'Does the app work without internet?';

  @override
  String get faqA6 =>
      'Yes, to view what was already loaded and for some entries: they are sent as soon as the network is back (“Offline” banner at the top).';

  @override
  String get editAction => 'Edit';

  @override
  String get deleteAction => 'Delete';

  @override
  String get editEvent => 'Edit event';

  @override
  String get eventUpdated => 'Event updated.';

  @override
  String deleteEventConfirm(String title) {
    return 'Delete “$title” from the calendar? Any attendance taken will be lost.';
  }

  @override
  String get eventDeleted => 'Event deleted.';

  @override
  String get editAnnouncement => 'Edit announcement';

  @override
  String get announcementUpdated => 'Announcement updated.';

  @override
  String deleteAnnouncementConfirm(String title) {
    return 'Delete “$title”? It disappears for every member.';
  }

  @override
  String get announcementDeleted => 'Announcement deleted.';

  @override
  String get termsAcceptPrefix => 'I have read and accept the ';

  @override
  String get termsOfServiceLink => 'terms of use';

  @override
  String get termsRequired =>
      'The terms of use have changed: go back, read them again and tick the box to continue.';

  @override
  String get termsTickToContinue => 'Tick the box to continue.';

  @override
  String logoutPending(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n changes haven’t been sent yet: they will be lost if you log out now.',
      one: '1 change hasn’t been sent yet: it will be lost if you log out now.',
    );
    return '$_temp0';
  }

  @override
  String get scopeInside => 'Inside';

  @override
  String get scopeOutside => 'Outside';

  @override
  String get eventScope => 'Inside or outside service';

  @override
  String get scopeRequired => 'Choose inside or outside.';

  @override
  String get eventKindOther => 'Specify the type';

  @override
  String get eventKindOtherHint => 'E.g. fair, retreat, pilgrimage…';

  @override
  String get chefDeGroupe => 'Group leader';

  @override
  String get chooseChef => 'Choose the group leader';

  @override
  String get chefHelp =>
      'They coordinate the event and hand a report to the trainer within 24 h of its end.';

  @override
  String get chefRequired => 'Choose the group leader.';

  @override
  String chefLine(String name) {
    return 'Group leader: $name';
  }

  @override
  String get reportSection => 'Group leader’s report';

  @override
  String reportDue(String date) {
    return 'Due by $date';
  }

  @override
  String reportSubmittedOn(String date) {
    return 'Handed in on $date';
  }

  @override
  String reportLateOn(String date) {
    return 'Handed in late on $date';
  }

  @override
  String reportMissingSince(String date) {
    return 'Not handed in: the deadline passed on $date';
  }

  @override
  String get reportBadgePending => 'Due';

  @override
  String get reportBadgeSubmitted => 'Handed in';

  @override
  String get reportBadgeLate => 'Late';

  @override
  String get reportBadgeMissing => 'Missing';

  @override
  String reportChefBefore(String date) {
    return 'You are the group leader. Hand in the report after the event, by $date.';
  }

  @override
  String get writeReport => 'Write the report';

  @override
  String get editReport => 'Edit the report';

  @override
  String get readReport => 'Read the report';

  @override
  String get reportTitle => 'Report';

  @override
  String get reportBodyLabel => 'Account of the event';

  @override
  String get reportBodyHint => 'How it went, attendance, incidents, remarks…';

  @override
  String get reportAttachPdf => 'Attach a PDF report';

  @override
  String get reportRecipients =>
      'Sent to the trainer; copied to the deputy trainer, general secretary, general censor and vice-censor.';

  @override
  String get sendReport => 'Send the report';

  @override
  String get reportSent => 'Report sent to the trainer.';

  @override
  String get reportEmpty => 'Write the report or attach a PDF.';

  @override
  String get reportLocked =>
      'The 24 h have passed: the report handed in can no longer be changed.';

  @override
  String get reportTooEarly =>
      'The report is handed in once the event has started.';

  @override
  String reportBy(String name) {
    return 'By $name, group leader';
  }

  @override
  String get reportLateWarning =>
      'The 24 h have passed: the report will be marked “late” and can’t be changed afterwards.';

  @override
  String get pdfOnly => 'PDF only, 10 MB maximum';

  @override
  String get reportHandedIn => 'Handed in to the trainer';

  @override
  String get reportHandedInLate => 'Handed in late to the trainer';

  @override
  String reportReadBy(String name) {
    return 'Opened by $name: can no longer be changed';
  }

  @override
  String reportOpenedOn(String name, String date) {
    return 'Opened by $name on $date';
  }

  @override
  String get reportReadLocked =>
      'A board member has opened the report: it can no longer be changed.';

  @override
  String get reportLockNote =>
      'Once a board member opens the report, it can no longer be changed.';

  @override
  String get lineupOnly =>
      'Only the guards lined up for this service are listed, with their post.';

  @override
  String get lineupEmpty => 'No one is lined up for this service yet.';

  @override
  String myPost(String post) {
    return 'Your post: $post';
  }

  @override
  String get notOnDuty => 'You are not on duty for this event.';
}
