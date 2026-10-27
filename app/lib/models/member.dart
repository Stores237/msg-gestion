class RoleBrief {
  const RoleBrief({required this.slug, required this.name, required this.kind});
  final String slug;
  final String name;
  final String kind;

  factory RoleBrief.fromJson(Map<String, dynamic> j) => RoleBrief(
    slug: j['slug'] as String,
    name: j['name'] as String,
    kind: j['kind'] as String,
  );
}

/// Member status keys from the server: actif, conge, classe, suspendu.
class MemberSummary {
  const MemberSummary({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.fullName,
    required this.status,
    required this.isDiaspora,
    required this.city,
    required this.age,
    required this.isMinor,
    required this.joinedYear,
    required this.roles,
    this.photo,
    this.leaveUntil,
  });

  final String? photo;

  /// On leave in this group: the last day, when known.
  final DateTime? leaveUntil;
  final int id;
  final String lastName;
  final String firstName;
  final String fullName;
  final String status;
  final bool isDiaspora;
  final String city;
  final int? age;
  final bool isMinor;
  final int joinedYear;
  final List<RoleBrief> roles;

  factory MemberSummary.fromJson(Map<String, dynamic> j) => MemberSummary(
    id: j['id'] as int,
    lastName: j['last_name'] as String,
    firstName: j['first_name'] as String,
    fullName: j['full_name'] as String,
    status: j['status'] as String,
    leaveUntil: j['leave_until'] == null
        ? null
        : DateTime.parse(j['leave_until'] as String),
    isDiaspora: j['is_diaspora'] as bool,
    city: (j['city'] as String?) ?? '',
    age: j['age'] as int?,
    isMinor: j['is_minor'] as bool,
    joinedYear: j['joined_year'] as int,
    roles: [
      for (final r in j['roles'] as List)
        RoleBrief.fromJson(r as Map<String, dynamic>),
    ],
  );
}

class ParentContact {
  const ParentContact({
    required this.name,
    required this.relation,
    required this.phone,
  });
  final String name;
  final String relation;
  final String phone;
}

class AttendanceSummary {
  const AttendanceSummary({
    required this.present,
    required this.absent,
    required this.excused,
    required this.of,
    this.last,
  });
  final int present;
  final int absent;
  final int excused;
  final int of;
  final DateTime? last;
}

class MemberDetail {
  const MemberDetail({
    required this.summary,
    this.phone,
    required this.joinedOn,
    this.birthDate,
    this.parent,
    required this.restricted,
    this.temporaryPin,
    this.attendance,
  });

  final AttendanceSummary? attendance;

  final MemberSummary summary;
  final String? phone;
  final DateTime joinedOn;
  final DateTime? birthDate;
  final ParentContact? parent;

  /// What exists but this viewer may not see: `minor_contacts`, `contributions`.
  final List<String> restricted;

  /// Only right after registration, shown once.
  final String? temporaryPin;

  factory MemberDetail.fromJson(Map<String, dynamic> j) {
    final p = j['parent'] as Map<String, dynamic>?;
    return MemberDetail(
      summary: MemberSummary.fromJson(j),
      phone: j['phone'] as String?,
      joinedOn: DateTime.parse(j['joined_on'] as String),
      birthDate: j['birth_date'] == null
          ? null
          : DateTime.parse(j['birth_date'] as String),
      parent: p == null
          ? null
          : ParentContact(
              name: p['name'] as String,
              relation: p['relation'] as String,
              phone: p['phone'] as String,
            ),
      restricted: List<String>.from(j['restricted'] as List),
      temporaryPin: j['temporary_pin'] as String?,
      attendance: j['attendance'] == null
          ? null
          : AttendanceSummary(
              present: j['attendance']['present'] as int,
              absent: j['attendance']['absent'] as int,
              excused: j['attendance']['excuse'] as int,
              of: j['attendance']['of'] as int,
              last: j['attendance']['last'] == null
                  ? null
                  : DateTime.parse(j['attendance']['last'] as String).toLocal(),
            ),
    );
  }
}

class MemberCounts {
  const MemberCounts({
    this.all = 0,
    this.active = 0,
    this.leave = 0,
    this.retired = 0,
    this.diaspora = 0,
  });
  final int all;
  final int active;
  final int leave;
  final int retired;
  final int diaspora;

  factory MemberCounts.fromJson(Map<String, dynamic> j) => MemberCounts(
    all: j['all'] as int,
    active: j['actif'] as int,
    leave: j['conge'] as int,
    retired: j['classe'] as int,
    diaspora: j['diaspora'] as int,
  );
}

class MemberPage {
  const MemberPage({required this.counts, required this.members});
  final MemberCounts counts;
  final List<MemberSummary> members;
}

class BureauEntry {
  const BureauEntry({required this.member, required this.role, this.endsOn});
  final MemberSummary member;
  final RoleBrief role;
  final DateTime? endsOn;

  factory BureauEntry.fromJson(Map<String, dynamic> j) => BureauEntry(
    member: MemberSummary.fromJson(j['member'] as Map<String, dynamic>),
    role: RoleBrief.fromJson(j['role'] as Map<String, dynamic>),
    endsOn: j['ends_on'] == null
        ? null
        : DateTime.parse(j['ends_on'] as String),
  );
}

/// What the secretary types in "Nouveau membre".
class NewMember {
  const NewMember({
    required this.lastName,
    required this.firstName,
    required this.phone,
    this.birthDate,
    this.isDiaspora = false,
    this.city = '',
    this.parentName = '',
    this.parentRelation = '',
    this.parentPhone = '',
    this.registrationPaid = false,
  });

  final bool registrationPaid;

  final String lastName;
  final String firstName;
  final String phone;
  final DateTime? birthDate;
  final bool isDiaspora;
  final String city;
  final String parentName;
  final String parentRelation;
  final String parentPhone;

  Map<String, dynamic> toJson() => {
    'last_name': lastName,
    'first_name': firstName,
    'phone': phone,
    if (birthDate != null)
      'birth_date': birthDate!.toIso8601String().substring(0, 10),
    'is_diaspora': isDiaspora,
    'city': city,
    'parent_name': parentName,
    'parent_relation': parentRelation,
    'parent_phone': parentPhone,
    'registration_paid': registrationPaid,
  };
}
