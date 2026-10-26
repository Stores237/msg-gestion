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
    this.canDelete = false,
  });

  /// The viewer may edit / delete it (they added it, or manage the calendar).
  final bool canEdit;
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
    canDelete: (j['can_delete'] as bool?) ?? false,
    attendanceCounts: (j['attendance_counts'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(k, v as int),
    ),
  );

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'title': title,
    'starts_at': startsAt.toUtc().toIso8601String(),
    'ends_at': endsAt?.toUtc().toIso8601String(),
    'place': place,
    'dress': dress,
    'notes': notes,
  };
}

class AttendanceRow {
  AttendanceRow({
    required this.member,
    required this.fullName,
    required this.isDiaspora,
    required this.status,
    required this.reason,
  });
  final int member;
  final String fullName;
  final bool isDiaspora;
  String status;
  final String reason;

  factory AttendanceRow.fromJson(Map<String, dynamic> j) => AttendanceRow(
    member: j['member'] as int,
    fullName: j['full_name'] as String,
    isDiaspora: j['is_diaspora'] as bool,
    status: j['status'] as String,
    reason: (j['reason'] as String?) ?? '',
  );
}
