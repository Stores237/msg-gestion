import 'me.dart';
import 'network_reach.dart';

/// Kind and dress keys are the group's own (back-office → Paramètres); the
/// server also sends their names (kindName, dressName).
/// Attendance keys: present, absent, excuse ('' = not marked).
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.kind,
    required this.title,
    required this.startsAt,
    this.endsAt,
    required this.place,
    required this.dress,
    required this.notes,
    this.myAttendance,
    this.attendanceCounts,
    this.kindName,
    this.dressName,
    this.createdByName,
    this.createdByRole = '',
    this.canEdit = false,
    this.ended = false,
    this.canDelete = false,
    this.kindOther = '',
    this.scope = '',
    this.chefId,
    this.chefName,
    this.reportDueAt,
    this.reportStatus = '',
    this.canReport = false,
    this.canReadReport = false,
    this.reportReadBy,
    this.hasLineup = false,
    this.myDuty,
    this.placeDetail = '',
    this.dressDetail = '',
    this.cascade = false,
    this.fromGroup,
    this.contingent,
    this.reach,
    this.sentTo,
  });

  /// Chosen recipients to send with a save (build 48); null: unchanged.
  final NetworkReach? reach;

  /// Where this group sent it in the network (build 48).
  final SentTo? sentTo;

  /// Joint planning (build 42): from above, what this group is asked and
  /// whether the viewer is named; on an event this group sent down, totals.
  final ContingentSummary? contingent;

  /// Also in the calendars of the groups attached below (build 41).
  final bool cascade;

  /// Sent down by a group above; read-only here, no roll call.
  final GroupInfo? fromGroup;

  /// Second line under the place ("Quartier, ville").
  final String placeDetail;

  /// The event is over: its end (or start, without an end) has passed.
  bool get isOver => (endsAt ?? startsAt).isBefore(DateTime.now());

  /// What the dress means in this group (Paramètres → Tenues).
  final String dressDetail;

  /// Who opened the report first; from then on the chef can't change it.
  final String? reportReadBy;

  /// The event has a service lineup: only those lined up are on the roll
  /// call, and [myDuty] is the viewer's post (null: not serving).
  final bool hasLineup;
  final Duty? myDuty;

  /// With kind "autre": the type in the author's words (owner, 2026-10-27).
  final String kindOther;

  /// interieur | exterieur, for types that have it (Messe); '' otherwise.
  final String scope;

  /// The chef de groupe, designated with the event; reports within 24 h.
  final int? chefId;
  final String? chefName;
  final DateTime? reportDueAt;

  /// '' (no chef) | pending | submitted | late | missing
  final String reportStatus;
  final bool canReport;
  final bool canReadReport;

  /// The viewer may edit / delete it (they added it, or manage the calendar).
  final bool canEdit;

  /// Over (owner, 2026-11-02): nothing changes any more but the roll call.
  final bool ended;
  final bool canDelete;

  /// Who added it, and their role then (owner, 2026-10-26).
  final String? createdByName;
  final String createdByRole;

  final String? kindName;
  final String? dressName;

  final int id;
  final String kind;
  final String title;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String place;
  final String dress;
  final String notes;
  final String? myAttendance;
  final Map<String, int>? attendanceCounts;

  factory CalendarEvent.fromJson(Map<String, dynamic> j) => CalendarEvent(
    id: j['id'] as int,
    kind: j['kind'] as String,
    kindName: j['kind_name'] as String?,
    dressName: j['dress_name'] as String?,
    title: j['title'] as String,
    startsAt: DateTime.parse(j['starts_at'] as String).toLocal(),
    endsAt: j['ends_at'] == null
        ? null
        : DateTime.parse(j['ends_at'] as String).toLocal(),
    place: (j['place'] as String?) ?? '',
    dress: (j['dress'] as String?) ?? '',
    notes: (j['notes'] as String?) ?? '',
    myAttendance: j['my_attendance'] as String?,
    createdByName: j['created_by_name'] as String?,
    createdByRole: (j['created_by_role'] as String?) ?? '',
    canEdit: (j['can_edit'] as bool?) ?? false,
    ended: j['ended'] == true,
    canDelete: (j['can_delete'] as bool?) ?? false,
    kindOther: (j['kind_other'] as String?) ?? '',
    scope: (j['scope'] as String?) ?? '',
    chefId: j['chef'] as int?,
    chefName: j['chef_name'] as String?,
    reportDueAt: j['report_due_at'] == null
        ? null
        : DateTime.parse(j['report_due_at'] as String).toLocal(),
    reportStatus: (j['report_status'] as String?) ?? '',
    canReport: (j['can_report'] as bool?) ?? false,
    canReadReport: (j['can_read_report'] as bool?) ?? false,
    reportReadBy: j['report_read_by'] as String?,
    placeDetail: (j['place_detail'] as String?) ?? '',
    dressDetail: (j['dress_detail'] as String?) ?? '',
    hasLineup: (j['has_lineup'] as bool?) ?? false,
    myDuty: j['my_duty'] == null
        ? null
        : Duty.fromJson(j['my_duty'] as Map<String, dynamic>),
    attendanceCounts: (j['attendance_counts'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(k, v as int),
    ),
    cascade: j['cascade'] == true,
    fromGroup: j['from_group'] == null
        ? null
        : GroupInfo.fromJson(j['from_group'] as Map<String, dynamic>),
    contingent: j['contingent'] == null
        ? null
        : ContingentSummary.fromJson(j['contingent'] as Map<String, dynamic>),
    sentTo: SentTo.fromJson(j['sent_to']),
  );

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'title': title,
    'starts_at': startsAt.toUtc().toIso8601String(),
    'ends_at': endsAt?.toUtc().toIso8601String(),
    'place': place,
    'place_detail': placeDetail,
    'dress': dress,
    'notes': notes,
    'kind_other': kindOther,
    'scope': scope,
    'chef': chefId,
    'cascade': cascade,
    if (reach case final r?) ...{'reach': r.ids, 'reach_audience': r.audience},
  };
}

/// The chef de groupe's report on an event: text, a PDF, or both.
class EventReport {
  const EventReport({
    required this.body,
    this.fileName = '',
    this.fileUrl,
    this.authorName,
    required this.submittedAt,
    this.late = false,
    this.readAt,
    this.readByName,
  });

  /// First opened by a bureau reader: locked from then on.
  final DateTime? readAt;
  final String? readByName;
  final String body;
  final String fileName;
  final String? fileUrl;
  final String? authorName;
  final DateTime submittedAt;
  final bool late;

  factory EventReport.fromJson(Map<String, dynamic> j) => EventReport(
    body: (j['body'] as String?) ?? '',
    fileName: (j['file_name'] as String?) ?? '',
    fileUrl: j['file_url'] as String?,
    authorName: j['author_name'] as String?,
    submittedAt: DateTime.parse(j['submitted_at'] as String).toLocal(),
    late: (j['late'] as bool?) ?? false,
    readAt: j['read_at'] == null
        ? null
        : DateTime.parse(j['read_at'] as String).toLocal(),
    readByName: j['read_by_name'] as String?,
  );
}

/// What someone serves as at an event: a post and side of the lineup,
/// and/or chef de groupe (post '' when only chef).
class Duty {
  const Duty({this.post = '', this.side = '', this.chef = false});
  final String post;
  final String side;
  final bool chef;

  factory Duty.fromJson(Map<String, dynamic> j) => Duty(
    post: (j['post'] as String?) ?? '',
    side: (j['side'] as String?) ?? '',
    chef: (j['chef'] as bool?) ?? false,
  );
}

class AttendanceRow {
  AttendanceRow({
    required this.member,
    required this.fullName,
    required this.isDiaspora,
    required this.status,
    required this.reason,
    this.duty,
  });
  final int member;
  final String fullName;
  final bool isDiaspora;
  String status;
  final String reason;

  /// Their post when the event has a lineup (owner, 2026-10-27).
  final Duty? duty;

  factory AttendanceRow.fromJson(Map<String, dynamic> j) => AttendanceRow(
    member: j['member'] as int,
    fullName: j['full_name'] as String,
    isDiaspora: j['is_diaspora'] as bool,
    status: j['status'] as String,
    reason: (j['reason'] as String?) ?? '',
    duty: j['duty'] == null
        ? null
        : Duty.fromJson(j['duty'] as Map<String, dynamic>),
  );
}

/// How many people are asked and named (build 42).
class ContingentSummary {
  const ContingentSummary({
    required this.requested,
    required this.designated,
    this.me = false,
  });
  final int requested;
  final int designated;
  final bool me;

  factory ContingentSummary.fromJson(Map<String, dynamic> j) =>
      ContingentSummary(
        requested: j['requested'] as int,
        designated: j['designated'] as int,
        me: j['me'] == true,
      );
}

typedef NamedPerson = ({int id, String name});

List<NamedPerson> _people(Object? rows) => [
  for (final p in (rows as List?) ?? const [])
    (id: p['id'] as int, name: p['name'] as String),
];

/// One group below, on the asking side.
class ContingentRow {
  const ContingentRow({
    required this.group,
    this.requested = 0,
    this.note = '',
    this.members = const [],
    this.answeredAt,
  });
  final GroupInfo group;
  final int requested;
  final String note;
  final List<NamedPerson> members;
  final DateTime? answeredAt;
}

class ContingentBoard {
  const ContingentBoard({
    this.groups = const [],
    this.canPlan = false,
    this.sentDown = false,
  });
  final List<ContingentRow> groups;
  final bool canPlan;
  final bool sentDown;

  factory ContingentBoard.fromJson(Map<String, dynamic> j) => ContingentBoard(
    canPlan: j['can_plan'] == true,
    sentDown: j['sent_down'] == true,
    groups: [
      for (final r in (j['groups'] as List?) ?? const [])
        ContingentRow(
          group: GroupInfo.fromJson(r['group'] as Map<String, dynamic>),
          requested: r['requested'] as int,
          note: (r['note'] as String?) ?? '',
          members: _people(r['members']),
          answeredAt: r['answered_at'] == null
              ? null
              : DateTime.parse(r['answered_at'] as String).toLocal(),
        ),
    ],
  );
}

/// The asked side: what the group above wants from this group.
class MyContingent {
  const MyContingent({
    required this.requested,
    this.note = '',
    this.members = const [],
    this.canAnswer = false,
  });
  final int requested;
  final String note;
  final List<NamedPerson> members;
  final bool canAnswer;

  factory MyContingent.fromJson(Map<String, dynamic> j) => MyContingent(
    requested: j['requested'] as int,
    note: (j['note'] as String?) ?? '',
    members: _people(j['members']),
    canAnswer: j['can_answer'] == true,
  );
}
