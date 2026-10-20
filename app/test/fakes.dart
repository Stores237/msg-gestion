import 'package:msg_gestion/data/api_client.dart';
import 'package:msg_gestion/data/repositories/announcements_repository.dart';
import 'package:msg_gestion/data/repositories/auth_repository.dart';
import 'package:msg_gestion/data/repositories/events_repository.dart';
import 'package:msg_gestion/data/repositories/finances_repository.dart';
import 'package:msg_gestion/data/repositories/members_repository.dart';
import 'package:msg_gestion/data/repositories/profile_repository.dart';
import 'package:msg_gestion/models/announcement.dart';
import 'package:msg_gestion/models/event.dart';
import 'package:msg_gestion/models/finance.dart';
import 'package:msg_gestion/models/me.dart';
import 'package:msg_gestion/models/member.dart';

Me fakeMe({
  String firstName = 'Ingrid',
  List<String> tabs = const ['accueil', 'calendrier', 'annonces'],
  List<Map<String, dynamic>>? roles,
  Map<String, dynamic> permissions = const {
    'calendar.events': ['view'],
    'announcements.posts': ['view'],
  },
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
    return PhoneLookup(phone: phone, firstName: firstName, hasPin: true);
  }

  bool mustChange = false;
  final changed = <String>[];
  bool smsAvailable = false;

  @override
  Future<bool> loginWithPin({
    required String phone,
    required String pin,
  }) async {
    if (pin == this.pin) return mustChange;
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

  @override
  Future<MemberDetail> create(NewMember member) async {
    created.add(member);
    return MemberDetail(
      summary: summary(99, member.lastName, member.firstName),
      joinedOn: DateTime.now(),
      restricted: const [],
      temporaryPin: '4821',
    );
  }
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
    );
  }

  @override
  Future<CalendarEvent> create(CalendarEvent draft) async {
    events = [...events, draft];
    return draft;
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
    );
    items = [a, ...items];
    return a;
  }

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
}
