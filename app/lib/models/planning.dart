class Slot {
  const Slot(this.post, this.side, this.index);
  final String post;
  final String side;
  final int index;

  @override
  bool operator ==(Object other) =>
      other is Slot &&
      other.post == post &&
      other.side == side &&
      other.index == index;

  @override
  int get hashCode => Object.hash(post, side, index);
}

class DutyAssignment {
  const DutyAssignment({
    required this.id,
    required this.slot,
    required this.memberId,
    required this.memberName,
    required this.status,
    this.conflict = false,
    this.eventId,
    this.title,
    this.startsAt,
    this.dress,
    this.chef,
  });

  final int id;
  final Slot slot;
  final int memberId;
  final String memberName;

  /// pend | conf | swap | repl | absent
  final String status;
  final bool conflict;

  // Only on "Mes services" rows.
  final int? eventId;
  final String? title;
  final DateTime? startsAt;
  final String? dress;
  final String? chef;

  factory DutyAssignment.fromJson(Map<String, dynamic> j) => DutyAssignment(
    id: j['id'] as int,
    slot: Slot(j['post'] as String, j['side'] as String, j['index'] as int),
    memberId: j['member'] as int,
    memberName: j['member_name'] as String,
    status: j['status'] as String,
    conflict: j['conflict'] == true,
    eventId: j['event'] as int?,
    title: j['title'] as String?,
    startsAt: j['starts_at'] == null
        ? null
        : DateTime.parse(j['starts_at'] as String).toLocal(),
    dress: j['dress'] as String?,
    chef: j['chef'] as String?,
  );
}

class PlannedService {
  const PlannedService({
    required this.id,
    required this.eventId,
    required this.title,
    required this.startsAt,
    required this.size,
    this.group,
    this.chef,
    required this.published,
    required this.slots,
    required this.assignments,
  });

  final int id;
  final int eventId;
  final String title;
  final DateTime startsAt;
  final int size;
  final String? group;
  final String? chef;
  final bool published;
  final List<Slot> slots;
  final List<DutyAssignment> assignments;

  DutyAssignment? at(Slot s) {
    for (final a in assignments) {
      if (a.slot == s) return a;
    }
    return null;
  }

  int get filled => assignments
      .where((a) => a.status != 'repl' && a.status != 'absent')
      .length;

  factory PlannedService.fromJson(Map<String, dynamic> j) => PlannedService(
    id: j['id'] as int,
    eventId: j['event'] as int,
    title: j['title'] as String,
    startsAt: DateTime.parse(j['starts_at'] as String).toLocal(),
    size: j['size'] as int,
    group: j['group'] as String?,
    chef: j['chef'] as String?,
    published: j['published'] as bool,
    slots: [
      for (final s in j['slots'] as List)
        Slot(s['post'] as String, s['side'] as String, s['index'] as int),
    ],
    assignments: [
      for (final a in j['assignments'] as List)
        DutyAssignment.fromJson(a as Map<String, dynamic>),
    ],
  );
}

class PlanningAlert {
  const PlanningAlert({
    required this.code,
    this.serviceId,
    this.filled,
    this.size,
    this.member,
  });
  final String code;
  final int? serviceId;
  final int? filled;
  final int? size;
  final String? member;

  factory PlanningAlert.fromJson(Map<String, dynamic> j) => PlanningAlert(
    code: j['code'] as String,
    serviceId: j['service'] as int?,
    filled: j['filled'] as int?,
    size: j['size'] as int?,
    member: j['member'] as String?,
  );
}

class UnplannedEvent {
  const UnplannedEvent({
    required this.eventId,
    required this.title,
    required this.startsAt,
  });
  final int eventId;
  final String title;
  final DateTime startsAt;
}

class PlanningWeek {
  const PlanningWeek({
    required this.start,
    required this.end,
    required this.services,
    required this.alerts,
    required this.unplanned,
    required this.published,
  });
  final DateTime start;
  final DateTime end;
  final List<PlannedService> services;
  final List<PlanningAlert> alerts;
  final List<UnplannedEvent> unplanned;
  final bool published;

  factory PlanningWeek.fromJson(Map<String, dynamic> j) => PlanningWeek(
    start: DateTime.parse(j['start'] as String),
    end: DateTime.parse(j['end'] as String),
    services: [
      for (final s in j['services'] as List)
        PlannedService.fromJson(s as Map<String, dynamic>),
    ],
    alerts: [
      for (final a in j['alerts'] as List)
        PlanningAlert.fromJson(a as Map<String, dynamic>),
    ],
    unplanned: [
      for (final u in j['unplanned'] as List)
        UnplannedEvent(
          eventId: u['event'] as int,
          title: u['title'] as String,
          startsAt: DateTime.parse(u['starts_at'] as String).toLocal(),
        ),
    ],
    published: j['published'] as bool,
  );
}

class Candidate {
  const Candidate({
    required this.memberId,
    required this.fullName,
    this.servicesThisMonth = 0,
    this.flag,
  });
  final int memberId;
  final String fullName;
  final int servicesThisMonth;

  /// null | busy_same_day | on_leave | many_this_month
  final String? flag;

  factory Candidate.fromJson(Map<String, dynamic> j) => Candidate(
    memberId: j['member'] as int,
    fullName: j['full_name'] as String,
    servicesThisMonth: (j['services_this_month'] as int?) ?? 0,
    flag: j['flag'] as String?,
  );
}

class ServiceGroupInfo {
  const ServiceGroupInfo({
    required this.id,
    required this.name,
    this.chef,
    required this.members,
    required this.available,
  });
  final int id;
  final String name;
  final String? chef;
  final int members;
  final int available;

  factory ServiceGroupInfo.fromJson(Map<String, dynamic> j) => ServiceGroupInfo(
    id: j['id'] as int,
    name: j['name'] as String,
    chef: j['chef'] as String?,
    members: (j['members'] as List).length,
    available: j['available'] as int,
  );
}

class DutyRequest {
  const DutyRequest({
    required this.id,
    required this.kind,
    required this.status,
    required this.reason,
    required this.requester,
    this.target,
    required this.post,
    required this.side,
    required this.title,
    required this.startsAt,
  });

  final int id;

  /// swap | absence
  final String kind;
  final String status;
  final String reason;
  final String requester;
  final String? target;
  final String post;
  final String side;
  final String title;
  final DateTime startsAt;

  factory DutyRequest.fromJson(Map<String, dynamic> j) => DutyRequest(
    id: j['id'] as int,
    kind: j['kind'] as String,
    status: j['status'] as String,
    reason: (j['reason'] as String?) ?? '',
    requester: j['requester'] as String,
    target: j['target'] as String?,
    post: j['post'] as String,
    side: j['side'] as String,
    title: j['title'] as String,
    startsAt: DateTime.parse(j['starts_at'] as String).toLocal(),
  );
}

class AlbWeek {
  const AlbWeek({
    required this.id,
    required this.weekStart,
    this.group,
    this.responsible,
    required this.albs,
    required this.status,
    required this.canAdvance,
  });
  final int id;
  final DateTime weekStart;
  final String? group;
  final String? responsible;
  final int albs;

  /// a_laver | lavees | rendues
  final String status;
  final bool canAdvance;

  factory AlbWeek.fromJson(Map<String, dynamic> j) => AlbWeek(
    id: j['id'] as int,
    weekStart: DateTime.parse(j['week_start'] as String),
    group: j['group'] as String?,
    responsible: j['responsible'] as String?,
    albs: j['albs'] as int,
    status: j['status'] as String,
    canAdvance: j['can_advance'] as bool,
  );
}

class AlbOverview {
  const AlbOverview({required this.weeks, required this.fairness});
  final List<AlbWeek> weeks;
  final List<(String, int)> fairness;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.target,
    required this.createdAt,
    required this.unread,
  });
  final int id;
  final String kind;
  final String title;
  final String body;
  final Map<String, dynamic> target;
  final DateTime createdAt;
  final bool unread;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as int,
    kind: j['kind'] as String,
    title: j['title'] as String,
    body: (j['body'] as String?) ?? '',
    target: (j['target'] as Map<String, dynamic>?) ?? const {},
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
    unread: j['unread'] as bool,
  );
}
