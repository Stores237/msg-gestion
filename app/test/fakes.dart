import 'package:msg_gestion/data/api_client.dart';
import 'package:msg_gestion/data/repositories/announcements_repository.dart';
import 'package:msg_gestion/data/repositories/auth_repository.dart';
import 'package:msg_gestion/data/repositories/events_repository.dart';
import 'package:msg_gestion/data/repositories/members_repository.dart';
import 'package:msg_gestion/data/repositories/profile_repository.dart';
import 'package:msg_gestion/models/announcement.dart';
import 'package:msg_gestion/models/event.dart';
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
}
