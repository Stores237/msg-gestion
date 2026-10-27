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
    this.kindOther = '',
    this.scope = '',
    this.chefId,
    this.chefName,
    this.reportDueAt,
    this.reportStatus = '',
    this.canReport = false,
    this.canReadReport = false,
  });

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
    'kind_other': kindOther,
    'scope': scope,
    'chef': chefId,
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
  });
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
  );
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
