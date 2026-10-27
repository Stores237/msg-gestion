import 'package:msg_gestion/data/api_client.dart';
import 'package:msg_gestion/data/repositories/announcements_repository.dart';
import 'package:msg_gestion/data/repositories/auth_repository.dart';
import 'package:msg_gestion/data/repositories/events_repository.dart';
import 'package:msg_gestion/data/repositories/finances_repository.dart';
import 'package:msg_gestion/data/repositories/members_repository.dart';
import 'package:msg_gestion/data/repositories/planning_repository.dart';
import 'package:msg_gestion/data/repositories/profile_repository.dart';
import 'package:msg_gestion/models/announcement.dart';
import 'package:msg_gestion/models/event.dart';
import 'package:msg_gestion/models/finance.dart';
import 'package:msg_gestion/models/me.dart';
import 'package:msg_gestion/models/access_request.dart';
import 'package:msg_gestion/models/member.dart';
import 'package:msg_gestion/models/planning.dart';

Me fakeMe({
  String firstName = 'Ingrid',
  List<String> tabs = const ['accueil', 'calendrier', 'annonces'],
  List<Map<String, dynamic>>? roles,
  Map<String, dynamic> permissions = const {
    'calendar.events': ['view'],
    'announcements.posts': ['view'],
  },
  String welcome = '',
  List<Map<String, dynamic>> groups = const [
    {'id': 1, 'name': 'Mouvement Garde Suisse'},
  ],
}) => Me.fromJson({
  'id': 1,
  'first_name': firstName,
  'last_name': 'Fotso',
  'full_name': 'Fotso $firstName',
  'status': 'actif',
  'is_diaspora': false,
  'age': 34,
  'roles':
      roles ??
      [
        {
          'slug': 'membre',
          'name': 'Membre',
          'kind': 'standard',
          'starts_on': '2025-10-01',
          'ends_on': null,
        },
      ],
  'permissions': permissions,
  'tabs': tabs,
  'group': {
    ...groups.first,
    'place': 'Yapoma, Douala',
    'welcome_message': welcome,
  },
  'groups': groups,
});

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.pin = '4821', this.firstName = 'Ingrid'});

  final String pin;
  final String firstName;
  int attemptsLeft = 3;
  int logouts = 0;

  @override
  Future<PhoneLookup> lookupPhone(String phone) async {
    if (phone.replaceAll(' ', '') != '677452108') {
      throw const UnknownMember();
    }
    return PhoneLookup(
      phone: phone,
      firstName: firstName,
      hasPin: true,
      termsVersion: termsVersion,
    );
  }

  bool mustChange = false;
  final changed = <String>[];
  bool smsAvailable = false;

  /// Conditions versions sent with each login (the checkbox).
  final acceptedTerms = <int>[];
  int termsVersion = 1;

  @override
  Future<TermsInfo> terms() async => TermsInfo(
    version: termsVersion,
    termsText: 'Conditions d’utilisation de test.',
  );

  @override
  Future<bool> loginWithPin({
    required String phone,
    required String pin,
    required int acceptedTerms,
  }) async {
    if (pin == this.pin) {
      if (acceptedTerms != termsVersion) throw const TermsRequired();
      this.acceptedTerms.add(acceptedTerms);
      return mustChange;
    }
    attemptsLeft -= 1;
    if (attemptsLeft == 0) throw const AccountLocked(15);
    throw WrongPin(attemptsLeft);
  }

  @override
  Future<void> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    if (currentPin != pin) throw const WrongPin(2);
    if (newPin == '1111' || newPin == '1234') {
      throw ApiException(400, '{"code":"pin_too_simple"}');
    }
    changed.add(newPin);
  }

  @override
  Future<void> forgotPin(String phone) async {
    if (!smsAvailable) throw ApiException(503, '{"code":"sms_unavailable"}');
  }

  @override
  Future<void> forgotPinConfirm({
    required String phone,
    required String code,
    required String newPin,
    required int acceptedTerms,
  }) async {
    if (code != '123456') throw ApiException(400, '{"code":"bad_code"}');
    changed.add(newPin);
  }

  @override
  Future<void> logout() async => logouts += 1;
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this.me);
  Me me;

  @override
  Future<Me> fetchMe() async => me;

  final photos = <String>[];

  @override
  Future<String?> uploadMyPhoto({
    required List<int> bytes,
    required String filename,
  }) async {
    photos.add(filename);
    return 'https://example.test/$filename';
  }

  @override
  Future<void> removeMyPhoto() async => photos.add('removed');

  PlatformInfo platformInfo = const PlatformInfo(
    supportPhone: '659802679',
    supportWhatsapp: '654858138',
    supportEmail: 'aide@example.org',
    privacyText: 'Vos données restent dans le groupe.',
    termsText: 'Usage réservé aux membres.',
  );

  @override
  Future<PlatformInfo> platform() async => platformInfo;

  final reminders = <String>[];
  BureauHome bureau = const BureauHome();

  @override
  Future<AppSettings> settings() async => const AppSettings(
    quickAmounts: [500, 1000, 3000],
    fees: {'inscription': 500},
  );

  @override
  Future<void> setReminders({bool? eve, bool? twoHours}) async =>
      reminders.add('eve=$eve 2h=$twoHours');

  @override
  Future<BureauHome> bureauHome() async => bureau;
}

class FakeMembersRepository implements MembersRepository {
  final created = <NewMember>[];

  static MemberSummary summary(
    int id,
    String last,
    String first, {
    String status = 'actif',
    bool diaspora = false,
    int? age,
    List<RoleBrief> roles = const [],
  }) => MemberSummary(
    id: id,
    lastName: last,
    firstName: first,
    fullName: '$last $first',
    status: status,
    isDiaspora: diaspora,
    city: diaspora ? 'Lyon, France' : '',
    age: age,
    isMinor: (age ?? 30) < 18,
    joinedYear: 2020,
    roles: roles,
  );

  final members = [
    summary(
      1,
      'Ewane',
      'Brice',
      roles: const [
        RoleBrief(slug: 'president', name: 'Président', kind: 'bureau'),
      ],
    ),
    summary(2, 'Mbella', 'Grâce', status: 'conge'),
    summary(3, 'Ateba', 'Sandrine', diaspora: true),
    summary(4, 'Essomba', 'Kévin', age: 15),
  ];

  @override
  Future<MemberPage> list({
    String query = '',
    String? status,
    bool diaspora = false,
  }) async {
    var rows = members.where(
      (m) => m.fullName.toLowerCase().contains(query.toLowerCase()),
    );
    if (status != null) rows = rows.where((m) => m.status == status);
    if (diaspora) rows = rows.where((m) => m.isDiaspora);
    return MemberPage(
      counts: const MemberCounts(all: 4, active: 3, leave: 1, diaspora: 1),
      members: rows.toList(),
    );
  }

  @override
  Future<MemberDetail> get(int id) async {
    final s = members.firstWhere((m) => m.id == id);
    return MemberDetail(
      summary: s,
      phone: s.isMinor ? null : '+237 6 77 45 21 08',
      joinedOn: DateTime(2020, 9, 14),
      restricted: [if (s.isMinor) 'minor_contacts', 'contributions'],
    );
  }

  final resets = <int>[];

  @override
  Future<String> resetPin(int id) async {
    resets.add(id);
    return '7391';
  }

  @override
  Future<List<BureauEntry>> bureau() async => [
    BureauEntry(
      member: members.first,
      role: members.first.roles.first,
      endsOn: DateTime(2027, 9, 30),
    ),
  ];

  final requestedRoles = <String>[];
  late List<AccessRequestItem> requests = [
    AccessRequestItem(
      id: 7,
      fullName: 'Mbarga Rose',
      phone: '+237690112233',
      role: 'tresorier',
      roleName: 'Trésorier',
      status: 'approved',
      createdAt: DateTime(2026, 10, 22),
      decidedAt: DateTime(2026, 10, 23),
      pinReady: true,
    ),
  ];
  final revealed = <int>[];

  @override
  Future<AccessRequestItem> requestAccess(
    NewMember member, {
    required String role,
    String note = '',
  }) async {
    created.add(member);
    requestedRoles.add(role);
    final item = AccessRequestItem(
      id: 100 + created.length,
      fullName: '${member.lastName} ${member.firstName}',
      phone: member.phone,
      role: role,
      roleName: role,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    requests = [item, ...requests];
    return item;
  }

  @override
  Future<List<AccessRequestItem>> accessRequests() async => requests;

  @override
  Future<AccessPin> revealAccessPin(int requestId) async {
    revealed.add(requestId);
    return const AccessPin(
      fullName: 'Mbarga Rose',
      phone: '+237690112233',
      pin: '4821',
    );
  }

  final photos = <int>[];
  final roleRequests = <String>[];

  @override
  Future<String?> uploadPhoto(
    int id, {
    required List<int> bytes,
    required String filename,
  }) async {
    photos.add(id);
    return 'https://example.test/p.png';
  }

  @override
  Future<List<(String, String)>> requestableRoles({bool daily = false}) async =>
      daily
      ? const [
          ('president', 'Président'),
          ('censeur-du-jour', 'Censeur du jour'),
          ('tresorier', 'Trésorier'),
        ]
      : const [
          ('censeur-du-jour', 'Censeur du jour'),
          ('chef-de-groupe', 'Chef de groupe'),
        ];

  @override
  Future<void> requestRole(
    int id, {
    required String role,
    required String reason,
    required DateTime startsOn,
    DateTime? endsOn,
    bool daily = false,
  }) async => roleRequests.add(
    daily
        ? '$id:$role:$reason:day:${startsOn.toIso8601String().substring(0, 10)}'
        : '$id:$role:$reason',
  );
}

class FakeEventsRepository implements EventsRepository {
  FakeEventsRepository() {
    final now = DateTime.now();
    events = [
      CalendarEvent(
        id: 1,
        kind: 'assise',
        title: 'Assise hebdomadaire',
        startsAt: DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
        ).add(const Duration(days: 2)),
        place: 'Salle paroissiale',
        dress: 'interieure',
        notes: '',
        chefId: 10,
        chefName: 'Eboa L.',
        reportStatus: 'pending',
        reportDueAt: DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
        ).add(const Duration(days: 3)),
      ),
    ];
  }

  late List<CalendarEvent> events;
  final excused = <int>[];
  Map<int, String>? saved;
  final sheet = [
    AttendanceRow(
      member: 10,
      fullName: 'Eboa Lionel',
      isDiaspora: false,
      status: '',
      reason: '',
    ),
    AttendanceRow(
      member: 11,
      fullName: 'Ateba Sandrine',
      isDiaspora: true,
      status: '',
      reason: '',
    ),
  ];

  @override
  Future<List<CalendarEvent>> list({
    required DateTime from,
    required DateTime to,
  }) async => events;

  @override
  Future<CalendarEvent> get(int id) async {
    final e = events.firstWhere((e) => e.id == id);
    return CalendarEvent(
      id: e.id,
      kind: e.kind,
      title: e.title,
      startsAt: e.startsAt,
      place: e.place,
      dress: e.dress,
      notes: e.notes,
      myAttendance: excused.contains(id) ? 'excuse' : null,
      createdByName: 'Ewane B.',
      createdByRole: 'Commissaire aux comptes',
      canEdit: owner,
      canDelete: owner,
      kindOther: e.kindOther,
      scope: e.scope,
      chefId: e.chefId,
      chefName: e.chefName,
      reportDueAt: e.reportDueAt,
      reportStatus: savedReport != null ? 'submitted' : e.reportStatus,
      canReport: e.canReport,
      canReadReport: savedReport != null || e.canReadReport,
    );
  }

  /// The chef de groupe's report (owner, 2026-10-27).
  EventReport? savedReport;
  final submitted = <(int, String, String?)>[];

  @override
  Future<EventReport> report(int eventId) async =>
      savedReport ?? (throw ApiException(404, '{"code":"no_report"}'));

  @override
  Future<EventReport> submitReport(
    int eventId, {
    required String body,
    (String, List<int>)? pdf,
  }) async {
    if (body.isEmpty && pdf == null) {
      throw ApiException(400, '{"code":"report_empty"}');
    }
    submitted.add((eventId, body, pdf?.$1));
    return savedReport = EventReport(
      body: body,
      fileName: pdf?.$1 ?? '',
      fileUrl: pdf == null ? null : 'https://example.org/r.pdf',
      authorName: 'Ingrid N.',
      submittedAt: DateTime.now(),
    );
  }

  /// The viewer added the events (edit / delete shown).
  bool owner = false;
  final updated = <String>[];
  final deleted = <int>[];

  @override
  Future<CalendarEvent> create(CalendarEvent draft) async {
    events = [...events, draft];
    return draft;
  }

  @override
  Future<CalendarEvent> update(int id, CalendarEvent draft) async {
    updated.add('$id:${draft.title}:${draft.place}');
    events = [
      for (final e in events)
        e.id == id
            ? CalendarEvent(
                id: id,
                kind: draft.kind,
                title: draft.title,
                startsAt: draft.startsAt,
                endsAt: draft.endsAt,
                place: draft.place,
                dress: draft.dress,
                notes: draft.notes,
                kindOther: draft.kindOther,
                scope: draft.scope,
                chefId: draft.chefId,
                chefName: e.chefName,
                reportStatus: e.reportStatus,
                reportDueAt: e.reportDueAt,
              )
            : e,
    ];
    return draft;
  }

  @override
  Future<void> delete(int id) async {
    deleted.add(id);
    events = events.where((e) => e.id != id).toList();
  }

  @override
  Future<void> excuse(int eventId, {String reason = ''}) async =>
      excused.add(eventId);

  @override
  Future<AttendanceSheet> attendance(int eventId) async =>
      AttendanceSheet(counts: const {}, rows: sheet);

  @override
  Future<AttendanceSheet> saveAttendance(
    int eventId,
    Map<int, String> marks,
  ) async {
    saved = marks;
    return AttendanceSheet(counts: const {}, rows: sheet);
  }
}

class FakeAnnouncementsRepository implements AnnouncementsRepository {
  final read = <int>[];
  final sent = <String>[];
  late List<Announcement> items = [
    Announcement(
      id: 1,
      kind: 'annonce',
      title: 'Répétition des chants',
      body: 'Jeudi 18:00 à l’église.',
      pinned: false,
      authorName: 'Din Y.',
      authorRole: 'Formateur',
      createdAt: DateTime(2026, 10, 19),
      unread: true,
      attachments: const [
        AttachmentInfo(
          id: 9,
          name: 'Programme.pdf',
          size: 245760,
          contentType: 'application/pdf',
          url: 'https://example.test/p.pdf',
        ),
      ],
    ),
  ];

  @override
  Future<AnnouncementFeed> feed({String filter = 'all'}) async {
    final shown = [
      for (final a in items)
        a.copyWith(unread: !read.contains(a.id) && a.unread),
    ];
    final f = filter == 'unread'
        ? shown.where((a) => a.unread).toList()
        : shown;
    return AnnouncementFeed(
      unread: shown.where((a) => a.unread).length,
      items: f,
    );
  }

  @override
  Future<void> markRead(int id) async => read.add(id);

  @override
  Future<Announcement> create({
    required String kind,
    required String title,
    required String body,
    int? eventId,
    bool pinned = false,
  }) async {
    sent.add('$kind:$title:${eventId ?? '-'}');
    final a = Announcement(
      id: 100 + sent.length,
      kind: kind,
      title: title,
      body: body,
      pinned: pinned,
      createdAt: DateTime.now(),
      unread: false,
      canEdit: true, // the author
      canDelete: true,
    );
    items = [a, ...items];
    return a;
  }

  final updated = <String>[];
  final deleted = <int>[];

  @override
  Future<Announcement> update(
    int id, {
    required String kind,
    required String title,
    required String body,
    int? eventId,
  }) async {
    updated.add('$id:$title');
    items = [
      for (final a in items)
        a.id == id
            ? Announcement(
                id: id,
                kind: kind,
                title: title,
                body: body,
                eventId: eventId,
                pinned: a.pinned,
                createdAt: a.createdAt,
                unread: false,
                canEdit: true,
                canDelete: true,
              )
            : a,
    ];
    return items.firstWhere((a) => a.id == id);
  }

  @override
  Future<void> delete(int id) async {
    deleted.add(id);
    items = items.where((a) => a.id != id).toList();
  }

  @override
  Future<Announcement> get(int id) async => items.firstWhere((a) => a.id == id);

  @override
  Future<List<ReadReceipt>> receipts(int id) async => const [];

  final attached = <String>[];

  @override
  Future<AttachmentInfo> attach(
    int announcementId, {
    required List<int> bytes,
    required String filename,
  }) async {
    attached.add('$announcementId:$filename');
    return AttachmentInfo(
      id: attached.length,
      name: filename,
      size: bytes.length,
      contentType: 'application/pdf',
      url: 'https://example.test/f.pdf',
    );
  }

  int reminded = 0;

  @override
  Future<int> remindUnread(int id) async => ++reminded;
}

class FakeFinancesRepository implements FinancesRepository {
  final created = <NewEntry>[];
  final validated = <int>[];
  Map<int, int>? paid;
  bool reportValidated = false;
  late List<FinanceEntry> items = [
    FinanceEntry(
      id: 1,
      direction: 'in',
      amount: 2500,
      category: 'solidarite',
      label: 'Décès · Nkotto',
      memberName: 'Essomba Kévin',
      date: DateTime(2026, 10, 19),
      status: 'pending',
      createdByName: 'Fotso I.',
      createdAt: DateTime(2026, 10, 19, 10, 12),
    ),
    FinanceEntry(
      id: 2,
      direction: 'out',
      amount: 12000,
      category: 'depense',
      label: 'Cierges et fleurs',
      date: DateTime(2026, 10, 17),
      status: 'validated',
      createdByName: 'Fotso I.',
      createdAt: DateTime(2026, 10, 17, 18, 5),
      validatedByName: 'Tchoumi A.',
    ),
  ];

  @override
  Future<FinanceSummary> summary() async => FinanceSummary(
    balance: 186500,
    balanceWithPending: 189000,
    pending: items.where((e) => e.pending).length,
    validatedUntil: DateTime(2026, 9, 30),
  );

  @override
  Future<List<FinanceEntry>> entries() async => items;

  @override
  Future<FinanceEntry> createEntry(NewEntry entry) async {
    created.add(entry);
    final e = FinanceEntry(
      id: 100 + created.length,
      direction: entry.direction,
      amount: entry.amount,
      category: entry.category,
      label: entry.label,
      memberName: entry.memberName,
      date: entry.date,
      status: 'pending',
      createdByName: 'Moi',
      createdAt: DateTime.now(),
      clientUuid: entry.clientUuid,
    );
    items = [e, ...items];
    return e;
  }

  @override
  Future<FinanceEntry> validate(int id) async {
    validated.add(id);
    items = [
      for (final e in items)
        e.id == id
            ? FinanceEntry(
                id: e.id,
                direction: e.direction,
                amount: e.amount,
                category: e.category,
                label: e.label,
                date: e.date,
                status: 'validated',
                createdByName: e.createdByName,
                createdAt: e.createdAt,
                validatedByName: 'Moi',
              )
            : e,
    ];
    return items.firstWhere((e) => e.id == id);
  }

  Collection _collection({List<CollectionRow>? rows}) => Collection(
    id: 7,
    kind: 'deces',
    title: 'Décès · famille Nkotto',
    amountPerMember: 2500,
    tranches: const [834, 1667, 2500],
    paidFull: 1,
    members: 3,
    collected: 3334,
    openedOn: DateTime(2026, 10, 12),
    rows:
        rows ??
        const [
          CollectionRow(
            memberId: 21,
            fullName: 'Ateba Sandrine',
            isDiaspora: true,
            paid: 2500,
            thirds: 3,
            nextAmount: 0,
          ),
          CollectionRow(
            memberId: 22,
            fullName: 'Essomba Kévin',
            isDiaspora: false,
            paid: 834,
            thirds: 1,
            nextAmount: 833,
          ),
          CollectionRow(
            memberId: 23,
            fullName: 'Mbella Grâce',
            isDiaspora: false,
            paid: 0,
            thirds: 0,
            nextAmount: 834,
          ),
        ],
  );

  @override
  Future<List<Collection>> collections() async => [_collection()];

  @override
  Future<Collection> collection(int id) async => _collection();

  @override
  Future<Collection> openCollection({
    required String kind,
    required String title,
    required int amountPerMember,
  }) async => _collection();

  @override
  Future<void> pay(int collectionId, Map<int, int> payments) async =>
      paid = payments;

  @override
  Future<void> closeCollection(int id) async {}

  @override
  Future<MyDues> mine() async => const MyDues(
    toPay: 3000,
    dues: [
      Due(
        id: 1,
        kind: 'solidarite',
        label: 'Décès · famille Nkotto',
        amount: 2500,
        paid: 0,
        remaining: 2500,
      ),
      Due(
        id: 2,
        kind: 'amende',
        label: 'Retard à l’assise',
        amount: 500,
        paid: 0,
        remaining: 500,
      ),
    ],
  );

  QuarterReport _report(int pending) => QuarterReport(
    year: 2026,
    quarter: 3,
    start: DateTime(2026, 7, 1),
    end: DateTime(2026, 10, 1),
    opening: 142000,
    income: 118500,
    expense: 74000,
    closing: 186500,
    incomeByCategory: const {'solidarite': 70000, 'aide_don': 35000},
    pending: pending,
    validatedBy: reportValidated ? 'Moi' : null,
    validatedAt: reportValidated ? DateTime(2026, 10, 20) : null,
  );

  int reportPending = 3;

  @override
  Future<QuarterReport> report(int year, int quarter) async =>
      _report(reportPending);

  @override
  Future<QuarterReport> validateReport(int year, int quarter) async {
    reportValidated = true;
    return _report(0);
  }

  final exports = <String>[];

  @override
  Future<String> reportPdf(int year, int quarter) async {
    exports.add('report:$year:$quarter');
    return 'https://example.test/r.pdf';
  }

  @override
  Future<String> cashbookPdf() async {
    exports.add('cashbook');
    return 'https://example.test/c.pdf';
  }

  @override
  Future<String> statementPdf() async {
    exports.add('statement');
    return 'https://example.test/s.pdf';
  }

  @override
  Future<String> memberStatementPdf(int memberId) async {
    exports.add('statement:$memberId');
    return 'https://example.test/m.pdf';
  }
}

class FakePlanningRepository implements PlanningRepository {
  final calls = <String>[];
  bool doubleOnce = false;
  late DateTime now = DateTime.now();

  PlannedService get _service => PlannedService(
    id: 5,
    eventId: 50,
    title: 'Grand-messe',
    startsAt: DateTime(
      now.year,
      now.month,
      now.day,
      9,
    ).add(const Duration(days: 2)),
    size: 4,
    group: 'Sainte-Agnès',
    chef: 'Kotto H.',
    published: calls.contains('publish'),
    slots: const [
      Slot('premiere_centrale', 'pariso', 0),
      Slot('premiere_centrale', 'yapoma', 0),
      Slot('deuxieme_centrale', 'pariso', 0),
      Slot('deuxieme_centrale', 'yapoma', 0),
    ],
    assignments: [
      const DutyAssignment(
        id: 1,
        slot: Slot('premiere_centrale', 'pariso', 0),
        memberId: 4,
        memberName: 'Essomba K.',
        status: 'pend',
        conflict: true,
      ),
      if (calls.any((c) => c.startsWith('slot:')))
        const DutyAssignment(
          id: 2,
          slot: Slot('premiere_centrale', 'yapoma', 0),
          memberId: 30,
          memberName: 'Bilong S.',
          status: 'pend',
        ),
    ],
  );

  @override
  Future<PlanningWeek> week(DateTime day) async => PlanningWeek(
    start: now,
    end: now.add(const Duration(days: 6)),
    services: [_service],
    alerts: const [
      PlanningAlert(code: 'understaffed', serviceId: 5, filled: 1, size: 4),
      PlanningAlert(code: 'double_service', member: 'Essomba K.'),
    ],
    unplanned: [
      UnplannedEvent(
        eventId: 60,
        title: 'Messe anticipée',
        startsAt: now.add(const Duration(days: 1)),
      ),
    ],
    published: calls.contains('publish'),
  );

  @override
  Future<void> setServiceSize(int eventId, int size) async =>
      calls.add('size:$eventId:$size');

  @override
  Future<void> setSlot(
    int serviceId,
    Slot slot,
    int? member, {
    bool force = false,
  }) async {
    if (doubleOnce && !force) {
      doubleOnce = false;
      throw ApiException(
        409,
        '{"code":"double_service","detail":"Bilong S. a déjà un service ce jour-là."}',
      );
    }
    calls.add('slot:${slot.post}:${slot.side}:$member:$force');
  }

  @override
  Future<List<Candidate>> candidates(int serviceId) async => const [
    Candidate(memberId: 30, fullName: 'Bilong Steve', servicesThisMonth: 1),
    Candidate(memberId: 31, fullName: 'Mbella Grâce', flag: 'on_leave'),
  ];

  @override
  Future<List<ServiceGroupInfo>> groups() async => const [
    ServiceGroupInfo(id: 1, name: 'Saint-Michel', members: 7, available: 7),
  ];

  @override
  Future<(int, int)> assignGroup(int serviceId, int groupId) async {
    calls.add('group:$serviceId:$groupId');
    return (3, 0);
  }

  @override
  Future<void> setChef(int serviceId, int? member) async {
    calls.add('chef:$serviceId:$member');
  }

  @override
  Future<int> publish(DateTime day) async {
    calls.add('publish');
    return 4;
  }

  @override
  Future<List<DutyAssignment>> mine() async => [
    if (!calls.contains('confirm:1'))
      DutyAssignment(
        id: 1,
        slot: const Slot('premiere_centrale', 'pariso', 0),
        memberId: 1,
        memberName: 'Moi',
        status: 'pend',
        title: 'Première messe',
        startsAt: now.add(const Duration(days: 5)),
        chef: 'Din Yannick',
        isChef: true,
        dress: 'interieure',
      )
    else
      DutyAssignment(
        id: 1,
        slot: const Slot('premiere_centrale', 'pariso', 0),
        memberId: 1,
        memberName: 'Moi',
        status: 'conf',
        title: 'Première messe',
        startsAt: now.add(const Duration(days: 5)),
      ),
  ];

  @override
  Future<void> confirm(int assignmentId) async =>
      calls.add('confirm:$assignmentId');

  @override
  Future<List<Candidate>> swapCandidates(int assignmentId) async => const [
    Candidate(memberId: 30, fullName: 'Bilong Steve'),
  ];

  @override
  Future<void> requestSwap(
    int assignmentId, {
    required int target,
    String reason = '',
  }) async => calls.add('swap:$assignmentId:$target:$reason');

  @override
  Future<void> declareAbsence(int assignmentId, {String reason = ''}) async =>
      calls.add('absence:$assignmentId');

  @override
  Future<(List<DutyRequest>, List<DutyRequest>)> requests() async => (
    [
      DutyRequest(
        id: 7,
        kind: 'swap',
        status: 'proposed',
        reason: 'Examen',
        requester: 'Essomba K.',
        post: 'premiere_centrale',
        side: 'pariso',
        title: 'Première messe',
        startsAt: now,
      ),
    ],
    [
      DutyRequest(
        id: 8,
        kind: 'absence',
        status: 'accepted',
        reason: 'Malade',
        requester: 'Eboa L.',
        post: 'controle',
        side: 'pariso',
        title: 'Messe anticipée',
        startsAt: now,
      ),
    ],
  );

  @override
  Future<void> answer(int requestId, {required bool accept}) async =>
      calls.add('answer:$requestId:$accept');

  @override
  Future<void> decide(
    int requestId, {
    required bool approve,
    int? replacement,
  }) async => calls.add('decide:$requestId:$approve:$replacement');

  @override
  Future<List<Candidate>> replacementCandidates(int requestId) async => const [
    Candidate(memberId: 30, fullName: 'Bilong Steve', servicesThisMonth: 1),
  ];

  @override
  Future<AlbOverview> albs() async => AlbOverview(
    weeks: [
      AlbWeek(
        id: 1,
        weekStart: now.subtract(Duration(days: now.weekday - 1)),
        group: 'Saint-Michel',
        responsible: 'Eboa Lionel',
        albs: 12,
        status: calls.contains('alb:1') ? 'lavees' : 'a_laver',
        canAdvance: true,
      ),
      AlbWeek(
        id: 2,
        weekStart: now.add(const Duration(days: 8)),
        group: 'Sainte-Agnès',
        albs: 12,
        status: 'a_laver',
        canAdvance: false,
      ),
    ],
    fairness: const [('Saint-Michel', 4), ('Saint-Tarcisius', 1)],
  );

  @override
  Future<void> scheduleAlbs(DateTime weekStart, {int? groupId}) async =>
      calls.add('schedule:$groupId');

  @override
  Future<void> advanceAlbs(int id) async => calls.add('alb:$id');
}

class FakeNotificationsRepository implements NotificationsRepository {
  bool allRead = false;

  @override
  Future<(int, List<AppNotification>)> list() async {
    final now = DateTime.now();
    final items = [
      AppNotification(
        id: 1,
        kind: 'convocation',
        title: 'Nouvelle convocation',
        body: 'Assemblée générale',
        target: const {},
        createdAt: now,
        unread: !allRead,
      ),
      AppNotification(
        id: 2,
        kind: 'payment',
        title: 'Paiement validé',
        body: 'Médaille · 2 000 FCFA',
        target: const {},
        createdAt: now.subtract(const Duration(days: 2)),
        unread: false,
      ),
    ];
    return (items.where((n) => n.unread).length, items);
  }

  @override
  Future<void> markRead({List<int>? ids}) async {
    if (ids == null) allRead = true;
  }
}
