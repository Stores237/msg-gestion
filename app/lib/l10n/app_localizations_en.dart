// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Huddle';

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
  String photoCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get lastAnnouncement => 'Latest announcements';

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
      'Text messages aren’t available yet. Ask your group’s organiser for a recovery code, then tap “I have a recovery code”.';

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
  String get willBeValidated =>
      'The other finance officer (treasurer or auditor) approves it; then it counts.';

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
  String get awaitingAuditor => 'Waiting for your approval';

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
      'The Huddle partner will create the access. You’ll be told here, with the temporary PIN to hand over.';

  @override
  String get accessIntro =>
      'The Huddle partner opens the account. You’ll then receive the temporary PIN to hand over to the member.';

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
  String get chooseGroup => 'Choose your group';

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
  String get unlockSubtitle => 'To open Huddle.';

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
  String get biometricReason => 'Unlock Huddle';

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
  String appVersion(String version, String build) {
    return 'Version $version ($build)';
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

  @override
  String flagLeaveUntil(String date) {
    return 'On leave until $date';
  }

  @override
  String alertOnLeaveUntil(String name, String date) {
    return '$name is on leave until $date';
  }

  @override
  String groupOnLeave(int n) {
    return '$n on leave';
  }

  @override
  String groupSheetNotice(String title, int n) {
    return '$title · $n posts. Free posts go to the group’s available members; the others are left out and the remaining cells flagged.';
  }

  @override
  String get keepDraft => 'Draft';

  @override
  String get draftKept => 'Draft: no one is notified until you publish.';

  @override
  String get dragHint => 'Hold a name to drag it to another cell.';

  @override
  String get dropHere => 'Drop here';

  @override
  String swapValidation(String name) {
    return 'Approved by: $name, group leader';
  }

  @override
  String get swapValidationPlanners => 'Approved by: the planning team';

  @override
  String get draftSaved => 'Draft saved on this phone.';

  @override
  String get draftRestored => 'Draft restored.';

  @override
  String get placeDetail => 'Place details (optional)';

  @override
  String get placeDetailHint => 'Area, town';

  @override
  String memberLeaveUntil(String date) {
    return 'On leave until $date';
  }

  @override
  String get poweredBy => 'Powered by';

  @override
  String get storageAndData => 'Storage and data';

  @override
  String get manageStorage => 'Manage storage';

  @override
  String storageUsed(String size) {
    return '$size used on this phone';
  }

  @override
  String get networkUsage => 'Network usage';

  @override
  String trafficSentReceived(String sent, String received) {
    return '$sent sent • $received received';
  }

  @override
  String trafficSince(String date) {
    return 'Since $date';
  }

  @override
  String get resetTrafficConfirm => 'Reset the data counters?';

  @override
  String get reset => 'Reset';

  @override
  String get dataSaver => 'Use less mobile data';

  @override
  String get dataSaverHint =>
      'On mobile data: no automatic photos, photos sent in standard quality';

  @override
  String get uploadQuality => 'Photo upload quality';

  @override
  String get qualityStandard => 'Standard quality';

  @override
  String get qualityStandardHint => 'Faster, less data (up to 1024 px)';

  @override
  String get qualityHigh => 'High quality';

  @override
  String get qualityHighHint => 'Sharper, more data (up to 2048 px)';

  @override
  String get autoDownload => 'Media auto-download';

  @override
  String get autoDownloadHint =>
      'Attachments download only when you open them.';

  @override
  String get onMobileData => 'When using mobile data';

  @override
  String get onWifi => 'When connected on Wi-Fi';

  @override
  String get memberPhotos => 'Photos (members and announcements)';

  @override
  String get noMedia => 'No media';

  @override
  String get autoOffBySaver => 'Off: using less data';

  @override
  String currentNetwork(String network) {
    return 'Current connection: $network';
  }

  @override
  String get networkWifi => 'Wi-Fi';

  @override
  String get networkMobile => 'mobile data';

  @override
  String get networkNone => 'offline';

  @override
  String get networkUnknown => 'unknown';

  @override
  String get offlineData => 'Offline data';

  @override
  String get offlineDataHint => 'reloaded from the server';

  @override
  String get unsentChanges => 'Unsent changes';

  @override
  String get unsentKept => 'kept until sent';

  @override
  String get imagesInMemory => 'Images in memory';

  @override
  String get clear => 'Clear';

  @override
  String sizeGb(String n) {
    return '$n GB';
  }

  @override
  String get framePhoto => 'Frame the photo';

  @override
  String get framePhotoHint =>
      'Move and zoom the photo: only what is inside the frame is sent.';

  @override
  String get photoRules =>
      'Landscape 4:3 · 2 MB maximum · 4 photos per announcement';

  @override
  String get usePhoto => 'Use this photo';

  @override
  String get photoUnreadable => 'This image can’t be read.';

  @override
  String get showPhoto => 'Show the photo';

  @override
  String get addPhotoHint => 'Gallery or camera · framed 4:3, 2 MB max';

  @override
  String get photosLimit => '4 photos maximum per announcement.';

  @override
  String get attachPdfHint => 'PDF document, 10 MB max';

  @override
  String get eventExpired => 'Expired';

  @override
  String get notifyAll => 'Notify: all members';

  @override
  String notifyCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Notify: $n members',
      one: 'Notify: 1 member',
    );
    return '$_temp0';
  }

  @override
  String get notifyHint =>
      'Choose who gets the notification. Everyone can still see it.';

  @override
  String get chooseRecipients => 'Who to notify?';

  @override
  String get chooseRecipientsHint =>
      'Only the members ticked are notified. With none, everyone is.';

  @override
  String get notifyEveryone => 'Everyone';

  @override
  String doneCount(int n) {
    return 'Done ($n)';
  }

  @override
  String get forYou => 'For you';

  @override
  String taggedLine(String names) {
    return 'For: $names';
  }

  @override
  String get filterForMe => 'For me';

  @override
  String get taggedStatus => 'Tagged';

  @override
  String removeRecipient(String name) {
    return 'Remove $name';
  }

  @override
  String get searchName => 'Search a name';

  @override
  String get downloads => 'Downloads';

  @override
  String get downloadsHint =>
      'Photos and PDFs you downloaded or opened stay here, readable without network. Photos already seen in the app too.';

  @override
  String get downloadsEmpty => 'No downloads';

  @override
  String get downloadsEmptyHint =>
      'Download a photo from an announcement or open a PDF report: it will stay here.';

  @override
  String get onThePhone => 'on the phone';

  @override
  String get saveToPhone => 'Save to the phone';

  @override
  String get saveToPhoneFailed =>
      'The phone did not allow saving. The file stays in Downloads.';

  @override
  String get deleteFile => 'Delete';

  @override
  String get savedToDownloads => 'Saved in Downloads › Huddle';

  @override
  String get photoSavedToGallery =>
      'Photo saved to the gallery (Pictures › Huddle)';

  @override
  String get keptInDownloads => 'Kept in My account › Downloads';

  @override
  String get noPdfViewer =>
      'No app can open this PDF. It is kept in My account › Downloads.';

  @override
  String offlineCopyOf(String date) {
    return 'Offline: copy from $date';
  }

  @override
  String get downloadPhoto => 'Download the photo';

  @override
  String get downloadFile => 'Download';

  @override
  String get photosAndFiles => 'Photos seen';

  @override
  String get photosAndFilesHint => 'kept to view them without network';

  @override
  String pdfStatementName(String date) {
    return 'Balance statement $date.pdf';
  }

  @override
  String pdfCashbookName(String date) {
    return 'Cash book $date.pdf';
  }

  @override
  String pdfReportName(int quarter, int year) {
    return 'Report Q$quarter $year.pdf';
  }

  @override
  String pdfMemberStatementName(String name, String date) {
    return 'Statement $name $date.pdf';
  }

  @override
  String get preview => 'Preview';

  @override
  String get gradient => 'Gradient';

  @override
  String get gradientHint =>
      'Accueil’s header goes from the main colour to a second one.';

  @override
  String secondColorN(int n) {
    return 'Second colour $n';
  }

  @override
  String get otherColor => 'Other colour…';

  @override
  String get hue => 'Hue';

  @override
  String get shade => 'Shade';

  @override
  String get choose => 'Choose';

  @override
  String get draftsSection => 'Drafts to publish';

  @override
  String get publishedSection => 'Published';

  @override
  String get reuse => 'Reuse';

  @override
  String get reuseTitle => 'Reuse this lineup for…';

  @override
  String get reuseHint =>
      'Same posts and guards, as a draft: check it, then publish.';

  @override
  String get reuseNoTarget =>
      'No upcoming event without a lineup. Create the event in the Calendar first.';

  @override
  String reuseDone(String title) {
    return 'Lineup reused for $title, as a draft.';
  }

  @override
  String reuseSkipped(String names) {
    return 'Left out (on leave, inactive or already on duty that day): $names.';
  }

  @override
  String get datePassed => 'Date passed';

  @override
  String pastDraftsNotice(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n lineups whose date has passed can no longer be published: reuse them for an upcoming event.',
      one:
          'A lineup whose date has passed can no longer be published: reuse it for an upcoming event.',
    );
    return '$_temp0';
  }

  @override
  String get errorDatePassed =>
      'The date has passed: this lineup can no longer be published. Reuse it for an upcoming event.';

  @override
  String get signedOutOtherDevice =>
      'Your account was opened on another phone, so this one was signed out. If it wasn’t you, sign in again and change your PIN.';

  @override
  String get checkAll => 'Select all';

  @override
  String get chooseMembers => 'Choose members';

  @override
  String get membersLabel => 'Members';

  @override
  String get memberRequiredError => 'Choose at least one member.';

  @override
  String membersChosen(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n members chosen',
      one: '1 member chosen',
    );
    return '$_temp0';
  }

  @override
  String perMemberTotal(int n, String amount, String total) {
    return '$n members × $amount = $total';
  }

  @override
  String get perMemberHint => 'One line per member, same amount each.';

  @override
  String get catOther => 'Other';

  @override
  String get otherDescription => 'Description (required)';

  @override
  String get descriptionRequired => 'Describe the operation.';

  @override
  String get editEntryTitle => 'Edit the operation';

  @override
  String get entryEdited => 'Entry edited. The other officer approves it.';

  @override
  String get editedBadge => 'Edited';

  @override
  String editedBy(String name) {
    return 'edited by $name';
  }

  @override
  String get toConfirmBadge => 'To finalise';

  @override
  String get confirmEntryTitle => 'Finalise the operation?';

  @override
  String confirmEntryBody(String name) {
    return '$name edited and validated it. Finalise it if the correction is right, otherwise send it back with the reason.';
  }

  @override
  String get finalise => 'Finalise';

  @override
  String get sendBack => 'Send back';

  @override
  String get sendBackReason => 'Why send it back to the treasurer?';

  @override
  String get entryFinalised => 'Operation finalised.';

  @override
  String get entrySentBack => 'Operation sent back to the treasurer.';

  @override
  String get validateEditedNote =>
      'It was edited: validating it approves the corrected version.';

  @override
  String get linkedEntryNote =>
      'Payment towards a share or a fine: the member and the category stay.';

  @override
  String entriesToConfirm(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n operations to finalise',
      one: '1 operation to finalise',
    );
    return '$_temp0';
  }

  @override
  String get groupBy => 'Group by';

  @override
  String get groupByDay => 'Day';

  @override
  String get groupByType => 'Type';

  @override
  String get groupByStatus => 'Status';

  @override
  String get groupByMember => 'Member';

  @override
  String get noMemberGroup => 'No member';

  @override
  String entriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String get awaitingOtherBadge => 'Waiting for the other';

  @override
  String get longPressHint => 'Long-press an entry to validate several.';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get selectAll => 'Select all';

  @override
  String validateSelected(int count) {
    return 'Validate ($count)';
  }

  @override
  String validateManyTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Validate $count entries?',
      one: 'Validate 1 entry?',
    );
    return '$_temp0';
  }

  @override
  String validateManyBody(String total) {
    return 'Total: $total. Your name and the time are recorded on each; they can no longer be changed.';
  }

  @override
  String validatedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries validated.',
      one: '1 entry validated.',
    );
    return '$_temp0';
  }

  @override
  String skippedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count were not validated (they wait for the other officer).',
      one: '1 was not validated (it waits for the other officer).',
    );
    return '$_temp0';
  }

  @override
  String get financeCodeTitle => 'Finance code';

  @override
  String get financeCodeSubtitle => 'Enter your finance code to open Finances.';

  @override
  String financeCodeWrong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wrong finance code. $count tries left.',
      one: 'Wrong finance code. 1 try left.',
      zero: 'Wrong finance code.',
    );
    return '$_temp0';
  }

  @override
  String get financeCodeForgot => 'Forgot the finance code?';

  @override
  String get financeCodeChooseTitle => 'Your finance code';

  @override
  String get financeCodeChooseBody =>
      'Your group protects Finances with a second 4-digit code, different from your PIN. Choose it and confirm with your PIN.';

  @override
  String get financeCodeYourPin => 'Your PIN';

  @override
  String get financeCodeNew => 'Finance code (4 digits)';

  @override
  String get financeCodeConfirm => 'Confirm the finance code';

  @override
  String get financeCodeMismatch => 'The two codes don\'t match.';

  @override
  String get financeCodeFourDigits => 'The PIN and the code have 4 digits.';

  @override
  String get financeCodeSameAsPin =>
      'The finance code must differ from the PIN.';

  @override
  String get financeCodeSaved => 'Finance code saved.';

  @override
  String get financeCodeSave => 'Save the code';

  @override
  String get financeCodeOffline =>
      'Offline: this code was never checked on this phone yet.';

  @override
  String get expensesTitle => 'Expense requests';

  @override
  String get expTodo => 'To handle';

  @override
  String get expMine => 'My requests';

  @override
  String get expAll => 'All';

  @override
  String get expNew => 'New request';

  @override
  String get expNothingTodo => 'No request is waiting for you.';

  @override
  String get expNone => 'No requests.';

  @override
  String get expStatusSubmitted => 'With the lead';

  @override
  String get expStatusApproved => 'With the auditor';

  @override
  String get expStatusToPay => 'To pay';

  @override
  String get expStatusPaid => 'Paid';

  @override
  String get expStatusRefused => 'Refused';

  @override
  String get expStatusCancelled => 'Cancelled';

  @override
  String expReplaces(int id) {
    return 'Replaces request no. $id.';
  }

  @override
  String expReplacedBy(int id) {
    return 'Redone: request no. $id.';
  }

  @override
  String get expDomain => 'Expense type';

  @override
  String get expDomainRequired => 'Choose the expense type.';

  @override
  String get expTitleRequired => 'Say what the expense is for.';

  @override
  String expLeadHint(String role) {
    return 'Approved first by: $role (or a coordinator you tag).';
  }

  @override
  String get expNoLeadHint => 'Tag the coordinator who will approve it.';

  @override
  String get expTitle => 'What for (e.g. Paper for the exam)';

  @override
  String get expAmount => 'Amount requested';

  @override
  String get expDescription => 'Details (optional)';

  @override
  String get expTagCoordinators => 'Tag a coordinator';

  @override
  String get expTagHint => 'Optional: a higher lead can approve it too.';

  @override
  String get expSend => 'Send the request';

  @override
  String get expSent => 'Request sent.';

  @override
  String get expDetailTitle => 'Expense request';

  @override
  String get expThread => 'Thread';

  @override
  String get expCancelTitle => 'Cancel the request?';

  @override
  String get expRefuseTitle => 'Refuse the request?';

  @override
  String get expReasonLabel => 'Reason (required)';

  @override
  String get expCancelled => 'Request cancelled. It stays in the history.';

  @override
  String get expApproved => 'Request approved and passed on.';

  @override
  String get expRefused => 'Request refused.';

  @override
  String get expPaid => 'Payment recorded, proof attached.';

  @override
  String get expMessageSent => 'Message sent.';

  @override
  String get expApprove => 'Approve';

  @override
  String get expRefuse => 'Refuse';

  @override
  String get expPayAction => 'Pay and attach the proof';

  @override
  String get expCancelAction => 'Cancel the request';

  @override
  String get expResubmit => 'Make a new request';

  @override
  String get expAttach => 'Attach a file';

  @override
  String get expMessageHint => 'Write a message…';

  @override
  String get expSendMessage => 'Send';

  @override
  String expPaidAmount(String amount) {
    return 'Paid: $amount';
  }

  @override
  String expAskedBy(String name) {
    return 'asked by $name';
  }

  @override
  String expTagged(String names) {
    return 'Tagged coordinators: $names';
  }

  @override
  String expReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get expStepAsked => 'Request';

  @override
  String get expStepLead => 'Domain lead';

  @override
  String get expStepAuditor => 'Auditor';

  @override
  String get expStepPaid => 'Payment by the treasurer';

  @override
  String get expProof => 'Proof of payment';

  @override
  String get expPayTitle => 'Pay the expense';

  @override
  String expApprovedAmount(String amount) {
    return 'Approved amount: $amount';
  }

  @override
  String get expAmountPaid => 'Amount paid';

  @override
  String get expAmountMaxHint =>
      'At most the approved amount. For more, the requester cancels and asks again.';

  @override
  String expAmountMax(String amount) {
    return 'The amount paid is from 1 to $amount.';
  }

  @override
  String get expProofRequired => 'Attach the transaction screenshot.';

  @override
  String get expAddProof => 'Attach the transaction screenshot';

  @override
  String get expPayNote => 'Note (e.g. Orange Money, ref …)';

  @override
  String get expPayCashbook =>
      'The expense goes into the cash book and counts at once: the auditor approved the request.';

  @override
  String get expPayConfirm => 'Record the payment';

  @override
  String get homeExpenses => 'Expense requests';

  @override
  String get homeExpensesHint => 'Ask for a purchase, follow your requests';

  @override
  String fromExpense(int id) {
    return 'Paid on expense request no. $id · see the proof';
  }

  @override
  String get selectLines => 'Select';

  @override
  String expTodoCount(int count) {
    return '$count to handle';
  }

  @override
  String get expAttachments => 'Attachments';

  @override
  String get expAddFile => 'Attach a photo or a PDF';

  @override
  String get expRemoveFile => 'Remove';

  @override
  String get expAttachmentsHint =>
      'Optional: quote, invoice, photo of the item (JPEG, PNG or PDF, 10 MB, 3 at most).';

  @override
  String get expAttachmentBody => 'Attached to the request';

  @override
  String expSentFilesMissed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Request sent, but $count attachments didn\'t go: add them in the thread.',
      one: 'Request sent, but 1 attachment didn\'t go: add it in the thread.',
      zero: 'Request sent.',
    );
    return '$_temp0';
  }

  @override
  String get financeSettingsTitle => 'Finance settings';

  @override
  String get financeCodeAskTitle => 'Ask for my finance code';

  @override
  String get financeCodeAskHint =>
      'Opening Finances on this account will ask your 4-digit code.';

  @override
  String get financeCodeForced =>
      'Required by your group for everyone: it can\'t be turned off.';

  @override
  String get financeCodeChange => 'Change my finance code';

  @override
  String get financeCodeChangeHint => 'With your PIN, also if you forgot it.';

  @override
  String get financeCodeAbout =>
      'The finance code is a second code, different from the PIN. Once typed, Finances stays open 5 minutes; it closes when the app locks.';

  @override
  String get financeCodeTurnOffTitle => 'Turn the finance code off?';

  @override
  String get financeCodeTurnedOn => 'Finance code turned on.';

  @override
  String get financeCodeTurnedOff => 'Finance code turned off.';

  @override
  String get chooseGroupHint =>
      'You belong to several groups. You can switch any time from Home.';

  @override
  String get groupLabel => 'Group';

  @override
  String get groupProfileTitle => 'Group name and logo';

  @override
  String get groupProfileHint => 'What members see in Huddle';

  @override
  String get groupLogoChange => 'Change the logo';

  @override
  String get groupLogoRemove => 'Remove the logo';

  @override
  String get groupLogoSaved => 'Group logo saved.';

  @override
  String get groupLogoHint =>
      'A square image is best (JPEG or PNG, 5 MB). Without a logo, the short name shows on the group\'s colour.';

  @override
  String get groupName => 'Group name';

  @override
  String get groupShortName => 'Short name';

  @override
  String get groupShortNameHint => '8 characters at most, e.g. MSG';

  @override
  String get groupNameRequired => 'The group\'s name is required.';

  @override
  String get groupProfileSaved => 'Group saved.';

  @override
  String get huddleBy => 'Huddle ·';

  @override
  String get eventEnded =>
      'This event is over: it can no longer be changed. Only the roll call is still possible.';

  @override
  String get showBalance => 'Show the balance';

  @override
  String get hideBalance => 'Hide the balance';

  @override
  String get downloadAskTitle => 'Download this document?';

  @override
  String get downloadAskWhere =>
      'PDF · saved in Downloads/Huddle and readable later without a connection.';

  @override
  String get download => 'Download';

  @override
  String get aboutStatementPdf =>
      'Members\' general statement: for each member, what they owe, what they paid (validated), what awaits validation and what is left to pay, over the chosen period.';

  @override
  String get aboutCashbookPdf =>
      'Cash book: the period\'s operations (money in and out) with their date, description, the member concerned, who entered and validated them, and their amount; with a period, the balance at its start and end.';

  @override
  String aboutReportPdf(int quarter, int year) {
    return 'Financial report for quarter $quarter $year: opening balance, money in and out, closing balance and income by category.';
  }

  @override
  String aboutMemberStatementPdf(String name) {
    return 'Statement for $name: what they owe (dues, fines), what they paid, what awaits validation and what is left to pay.';
  }

  @override
  String get faqGroupSection => 'Group questions';

  @override
  String get faqCommonSection => 'Common questions';

  @override
  String get faqSuggest => 'Suggest a question';

  @override
  String get faqSuggestHint =>
      'A question others ask too? Suggest it with its answer: the Huddle team reviews it and adds it to the help.';

  @override
  String get faqMine => 'My suggestions';

  @override
  String get faqPublished => 'Published';

  @override
  String get faqDeclined => 'Not kept';

  @override
  String get faqPending => 'Under review';

  @override
  String get faqSent => 'Thank you! Your question was sent to the Huddle team.';

  @override
  String get faqQuestion => 'The question';

  @override
  String get faqQuestionRequired => 'Write the question.';

  @override
  String get faqAnswer => 'The answer (if you know it)';

  @override
  String get faqAnswerHint =>
      'The team corrects or completes it before publishing.';

  @override
  String get faqSend => 'Send';

  @override
  String get myGroupSection => 'My group';

  @override
  String get groupRules => 'Group rules';

  @override
  String get groupCall => 'Call the group';

  @override
  String get groupMail => 'Email the group';

  @override
  String get groupLink => 'Group link';

  @override
  String get recoveryCode => 'Recovery code (8 digits)';

  @override
  String get recoveryCodeHint =>
      'Given by your group leader or the Huddle team. Valid 24 h, once.';

  @override
  String get haveRecoveryCode => 'I have a recovery code';

  @override
  String get memberInactive => 'Inactive';

  @override
  String get memberOnProbation => 'On probation';

  @override
  String remindBefore(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours before',
      one: '1 hour before',
    );
    return '$_temp0';
  }

  @override
  String get periodLabel => 'Period';

  @override
  String get periodAll => 'All';

  @override
  String get periodThisMonth => 'This month';

  @override
  String get periodLastMonth => 'Last month';

  @override
  String get periodThisYear => 'This year';

  @override
  String get periodCustom => 'Choose…';

  @override
  String get periodWhole => 'The whole history, up to today.';

  @override
  String periodRange(String from, String to) {
    return 'From $from to $to.';
  }

  @override
  String get groupNetTitle => 'Network';

  @override
  String get groupNetSheetHint => 'The groups above and attached';

  @override
  String get groupNetNone =>
      'Your group isn’t part of a network. The Huddle team places groups in a network (parishes, zones, dioceses…).';

  @override
  String groupNetIn(String network, String level) {
    return 'Network $network · your group: $level.';
  }

  @override
  String get groupNetAbove => 'Attached to';

  @override
  String get groupNetNoParent => 'Your group isn’t attached to any group.';

  @override
  String get groupNetJoinWithCode => 'Join with a code';

  @override
  String get groupNetJoinHint =>
      'Type the invitation code you received from the higher-level group (e.g. your zone).';

  @override
  String get groupNetCodeLength => 'The code has 8 characters, e.g. ABCD-EFGH.';

  @override
  String groupNetJoinAskTitle(String name) {
    return 'Attach your group to $name?';
  }

  @override
  String groupNetUnder(String chain) {
    return 'Itself attached to $chain';
  }

  @override
  String get groupNetJoinAskBody =>
      'This group will be able to inform yours (announcements, events). It doesn’t decide for your group and only sees what you choose to share. You can detach at any time.';

  @override
  String get groupNetJoin => 'Attach';

  @override
  String groupNetJoined(String name) {
    return 'Your group is attached to $name.';
  }

  @override
  String groupNetLeave(String name) {
    return 'Detach from $name';
  }

  @override
  String get groupNetLeaveBody =>
      'Both groups’ presidents will be told. To come back, you’ll need a new invitation code.';

  @override
  String get groupNetLeaveReason => 'Give the reason.';

  @override
  String get groupNetLeaveConfirm => 'Detach';

  @override
  String groupNetLeft(String name) {
    return 'Your group is no longer attached to $name.';
  }

  @override
  String groupNetBelow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attached groups',
      one: '1 attached group',
      zero: 'Attached groups',
    );
    return '$_temp0';
  }

  @override
  String get groupNetNoChildren => 'No attached group yet.';

  @override
  String groupNetGroupsBelow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count groups below',
      one: '1 group below',
    );
    return '$_temp0';
  }

  @override
  String get groupNetInvite => 'Invite a group';

  @override
  String get groupNetInviteAbout =>
      'One code per invited group, valid 14 days, single use. Its president types it in Network → Join with a code.';

  @override
  String get groupNetInviteTitle => 'Invitation code';

  @override
  String groupNetInviteHint(String date) {
    return 'Send this code to the president of the group to invite. Valid until $date, single use.';
  }

  @override
  String get groupNetPendingCodes => 'Pending codes';

  @override
  String groupNetCodeUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get groupNetRevoke => 'Cancel this code';

  @override
  String get groupNetCodeCopied => 'Code copied.';

  @override
  String get groupNetCodeRevoked => 'Code cancelled: it no longer works.';

  @override
  String get groupNetUnknownCode =>
      'Unknown invitation code. Check it with the group inviting you.';

  @override
  String get groupNetAbout =>
      'A higher group informs the groups attached to it; it doesn’t decide for them and only sees what each group chooses to share.';

  @override
  String get copy => 'Copy';

  @override
  String get groupNetSharingTitle => 'What we share';

  @override
  String groupNetSharingWith(String name) {
    return 'With $name and the groups above';
  }

  @override
  String get groupNetSharingAbout =>
      'Choose what the groups above yours can see. Up there, each part is read only by those whose role covers it (the treasurer for finances…). Nothing is shared until you choose.';

  @override
  String get groupNetSharingSaved =>
      'Sharing saved. The groups above are told.';

  @override
  String get groupNetNeverShared =>
      'Never shared: phone numbers, codes, minors’ contacts, attachments, personal statements.';

  @override
  String get groupNetKindMembers => 'Members';

  @override
  String get groupNetKindFinances => 'Finances';

  @override
  String get groupNetKindCalendar => 'Calendar';

  @override
  String get groupNetKindAnnouncements => 'Announcements';

  @override
  String get groupNetKindReports => 'Attendance and reports';

  @override
  String get groupNetLevelNone => 'Nothing';

  @override
  String get groupNetLevelSummary => 'Summary';

  @override
  String get groupNetLevelDetail => 'Detail';

  @override
  String get groupNetHintMembers =>
      'Summary: how many members. Detail: + names and roles.';

  @override
  String get groupNetHintFinances =>
      'Summary: the balance and the year’s totals. Detail: + the last 30 validated operations.';

  @override
  String get groupNetHintCalendar =>
      'Summary: how many events in the next 30 days. Detail: + their dates and places.';

  @override
  String get groupNetHintAnnouncements =>
      'Detail: your last 10 announcements (not call-ups).';

  @override
  String get groupNetHintReports =>
      'Summary: the attendance rate over 3 months. Detail: + attendance per event.';

  @override
  String get groupNetSharesNone => 'Shares nothing';

  @override
  String groupNetSharesList(String kinds) {
    return 'Shares: $kinds';
  }

  @override
  String groupNetTotals(int members, int sharing, int groups) {
    String _temp0 = intl.Intl.pluralLogic(
      sharing,
      locale: localeName,
      other:
          '$members members, from $sharing groups out of $groups sharing their members',
      one: '$members members, from 1 group out of $groups sharing its members',
      zero: 'None of the $groups groups shares its members yet',
    );
    return '$_temp0';
  }

  @override
  String get groupNetSharesNothing => 'This group shares nothing';

  @override
  String get groupNetSharesNothingBody =>
      'Its president chooses what it shares, in Network → What we share.';

  @override
  String get groupNetNotYourRole =>
      'Shared, but your role in this group doesn’t cover this part.';

  @override
  String get groupNetMembersActive => 'Members';

  @override
  String get groupNetBalance => 'Validated balance';

  @override
  String get groupNetYearIn => 'Income this year';

  @override
  String get groupNetYearOut => 'Spending this year';

  @override
  String get groupNetUpcoming => 'Events in the next 30 days';

  @override
  String get groupNetNoneYet => 'Nothing yet.';

  @override
  String get groupNetEvents90 => 'Events with a roll call (3 months)';

  @override
  String get groupNetPresenceRate => 'Attendance rate';

  @override
  String groupNetAttendance(int present, int absent, int excused) {
    return '$present present · $absent absent · $excused excused';
  }

  @override
  String get groupNetReportIn => 'Report';

  @override
  String groupNetFrom(String name) {
    return 'From $name';
  }

  @override
  String groupNetEventFromAbove(String name) {
    return 'An event of $name, passed on to your group. It is changed, and the roll call taken, in $name.';
  }

  @override
  String get groupNetSendDown => 'Also for the attached groups';

  @override
  String groupNetSendDownHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The $count attached groups (and those below) get it too, with a notification.',
      one: 'The attached group gets it too, with a notification.',
    );
    return '$_temp0';
  }

  @override
  String groupNetSendDownEventHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'It also shows in the calendars of the $count attached groups and those below.',
      one: 'It also shows in the attached group’s calendar.',
    );
    return '$_temp0';
  }

  @override
  String get contingentsTitle => 'People asked of the groups';

  @override
  String get contingentsAbout =>
      'Say how many people each attached group should send. Its planning officer chooses who; you see the names here.';

  @override
  String get contingentsNone => 'No request yet';

  @override
  String get contingentLess => 'One person fewer';

  @override
  String get contingentMore => 'One more person';

  @override
  String get contingentSend => 'Send the requests';

  @override
  String get contingentAsked =>
      'Requests sent. The groups’ planning officers are told.';

  @override
  String get contingentWaiting => 'Waiting for names';

  @override
  String contingentNamed(int named, int requested, String names) {
    return '$named/$requested: $names';
  }

  @override
  String get contingentTitle => 'People asked';

  @override
  String contingentAsk(String from, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$from asks for $_temp0';
  }

  @override
  String contingentNamedLabel(int named, int requested) {
    return '$named named out of $requested';
  }

  @override
  String get contingentNobody => 'Nobody is named yet.';

  @override
  String get contingentChoose => 'Name the people';

  @override
  String get contingentChooseHint =>
      'Only active members of your group. They get a notification; the asking group sees their names.';

  @override
  String get contingentSaved => 'Saved.';

  @override
  String get contingentYou => 'You are named';

  @override
  String get groupNetSharingNeighbours =>
      'With neighbouring groups (same group above)';

  @override
  String get groupNetSharingTwins => 'With twinned groups';

  @override
  String get groupNetNeighbours => 'Neighbouring groups';

  @override
  String get groupNetTwins => 'Twinned groups';

  @override
  String get groupNetNoTwins =>
      'No twinning. Two groups of any network can twin to share what they choose.';

  @override
  String get groupNetTwinInvite => 'Twin';

  @override
  String get groupNetTwinAccept => 'Accept a twinning';

  @override
  String get groupNetTwinJoinHint =>
      'Type the twinning code you received from the other group.';

  @override
  String groupNetTwinAskTitle(String name) {
    return 'Twin your group with $name?';
  }

  @override
  String get groupNetTwinAskBody =>
      'Each group chooses what it shares with its twinned groups (nothing at first). Either can end the twinning.';

  @override
  String get groupNetTwin => 'Twin';

  @override
  String groupNetTwinned(String name) {
    return 'Your group is twinned with $name.';
  }

  @override
  String get groupNetTwinCodeTitle => 'Twinning code';

  @override
  String groupNetTwinCodeHint(String date) {
    return 'Send this code to the other group’s president: they type it in Network → Accept a twinning. Valid until $date, single use.';
  }

  @override
  String get groupNetTwinEnd => 'End the twinning';

  @override
  String groupNetTwinEndTitle(String name) {
    return 'End the twinning with $name';
  }

  @override
  String get groupNetTwinEndBody =>
      'Both groups’ presidents will be told; nothing is shared between you any more.';

  @override
  String groupNetTwinEnded(String name) {
    return 'Twinning with $name ended.';
  }

  @override
  String get catNetwork => 'Network contributions';

  @override
  String get netDuesTitle => 'Network contributions';

  @override
  String get netDuesRowHint =>
      'What you owe the group above, what you ask of the attached groups';

  @override
  String get netDuesAbout =>
      'Paying a contribution adds money out to your cash book and money in to the asking group’s; each is approved as usual. It is “received” once the group above has validated its line.';

  @override
  String get netDuesOwed => 'To pay to the group above';

  @override
  String get netDuesNothingOwed => 'Nothing to pay.';

  @override
  String get netDuesAsked => 'Asked of the attached groups';

  @override
  String get netDuesNothingAsked => 'No contribution asked.';

  @override
  String get netDueNew => 'Ask for a contribution';

  @override
  String get netDueNewHint =>
      'Asked of each group attached directly to yours; their finance team is told.';

  @override
  String get netDueTitleLabel => 'Title (e.g. 2027 contribution)';

  @override
  String get netDueAmountLabel => 'Amount per group';

  @override
  String get netDueNoDate => 'No deadline (tap to choose one)';

  @override
  String netDueBefore(String date) {
    return 'before $date';
  }

  @override
  String get netDueFormError => 'Write a title and an amount.';

  @override
  String get netDueSend => 'Ask';

  @override
  String get netDueAsked =>
      'Contribution asked. The groups’ finance teams are told.';

  @override
  String get netDuePay => 'Pay';

  @override
  String netDuePayTitle(String amount) {
    return 'Pay $amount?';
  }

  @override
  String netDuePayBody(String group, String title) {
    return '“$title” for $group. Money out is added to your cash book (to approve) and money in to $group’s.';
  }

  @override
  String get netDuePaid =>
      'Contribution paid. It awaits approval in both cash books.';

  @override
  String get netDueCancel => 'Cancel';

  @override
  String netDueCancelTitle(String group) {
    return 'Cancel $group’s contribution?';
  }

  @override
  String get netDueCancelled => 'Contribution cancelled; the group is told.';

  @override
  String get netDueOpen => 'To pay';

  @override
  String get netDueLate => 'Late';

  @override
  String get netDueSent => 'Paid, to confirm';

  @override
  String get netDueReceived => 'Received';

  @override
  String get netDueCancelledBadge => 'Cancelled';

  @override
  String reportNetPaid(String group) {
    return 'Paid to $group';
  }

  @override
  String reportNetReceived(String group) {
    return 'Received from $group';
  }

  @override
  String get reportNetNone => 'No contribution settled this quarter';

  @override
  String get reportNetOwedOpen => 'Still to pay to the group above';

  @override
  String get reportNetAskedOpen => 'Still to receive from attached groups';

  @override
  String get groupNetWaiting => 'To complete (no president yet)';
}
