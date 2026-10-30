/// One bottom-nav tab, as decided by the server from the member's roles.
enum AppTab { accueil, membres, finances, calendrier, annonces }

class RoleAssignment {
  const RoleAssignment({
    required this.slug,
    required this.name,
    required this.kind,
    this.endsOn,
  });

  final String slug;
  final String name;
  final String kind;
  final DateTime? endsOn;

  factory RoleAssignment.fromJson(Map<String, dynamic> json) => RoleAssignment(
    slug: json['slug'] as String,
    name: json['name'] as String,
    kind: json['kind'] as String,
    endsOn: json['ends_on'] == null
        ? null
        : DateTime.parse(json['ends_on'] as String),
  );
}

/// A group of the MSG platform, as the app sees it.
class GroupInfo {
  const GroupInfo({
    required this.id,
    required this.name,
    this.place = '',
    this.motto = '',
    this.welcomeMessage = '',
    this.color,
    this.color2,
    this.financeCodeRequired = false,
  });

  /// Opening Finances asks the finance code (owner, 2026-10-30; set per
  /// group in the back-office).
  final bool financeCodeRequired;

  /// The group's app colour, "#RRGGBB" (back-office → Paramètres).
  final String? color;

  /// Its second colour for a gradient header; null or empty = plain.
  final String? color2;

  final int id;
  final String name;
  final String place;
  final String motto;

  /// Written by the partner for this group; shown on Accueil.
  final String welcomeMessage;

  factory GroupInfo.fromJson(Map<String, dynamic> j) => GroupInfo(
    id: j['id'] as int,
    name: j['name'] as String,
    place: (j['place'] as String?) ?? '',
    motto: (j['motto'] as String?) ?? '',
    welcomeMessage: (j['welcome_message'] as String?) ?? '',
    color: j['color'] as String?,
    color2: j['color2'] as String?,
    financeCodeRequired: j['finance_code_required'] == true,
  );
}

class Me {
  const Me({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.status,
    required this.isDiaspora,
    required this.age,
    required this.roles,
    required this.permissions,
    required this.tabs,
    this.pinMustChange = false,
    this.remindEve = true,
    this.remind2h = false,
    this.group,
    this.groups = const [],
    this.photo,
    this.financeCodeSet = false,
    this.financeCodeOn = false,
  });

  /// The member asked for the finance code on their own Finances.
  final bool financeCodeOn;

  /// Finances asks the code: the group requires it, or the member chose it.
  bool get financeCodeAsked =>
      (group?.financeCodeRequired ?? false) || financeCodeOn;

  /// The member has chosen a finance code (second code for Finances).
  final bool financeCodeSet;

  /// Signed URL of the member's own picture; null = initials.
  final String? photo;

  /// The same member with a new picture (Mon compte → Photo de profil).
  Me withPhoto(String? photo) => Me(
    id: id,
    firstName: firstName,
    lastName: lastName,
    fullName: fullName,
    status: status,
    isDiaspora: isDiaspora,
    age: age,
    roles: roles,
    permissions: permissions,
    tabs: tabs,
    pinMustChange: pinMustChange,
    remindEve: remindEve,
    remind2h: remind2h,
    group: group,
    groups: groups,
    photo: photo,
    financeCodeSet: financeCodeSet,
    financeCodeOn: financeCodeOn,
  );

  /// The group this session works in, and every group the member is in.
  final GroupInfo? group;
  final List<GroupInfo> groups;

  final bool remindEve;
  final bool remind2h;

  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String status;
  final bool isDiaspora;
  final int? age;
  final List<RoleAssignment> roles;
  final Map<String, List<String>> permissions;
  final List<AppTab> tabs;
  final bool pinMustChange;

  bool can(String resource, String action) =>
      permissions[resource]?.contains(action) ?? false;

  factory Me.fromJson(Map<String, dynamic> json) => Me(
    id: json['id'] as int,
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String,
    fullName: json['full_name'] as String,
    status: json['status'] as String,
    isDiaspora: json['is_diaspora'] as bool,
    age: json['age'] as int?,
    roles: [
      for (final r in json['roles'] as List)
        RoleAssignment.fromJson(r as Map<String, dynamic>),
    ],
    permissions: {
      for (final e in (json['permissions'] as Map<String, dynamic>).entries)
        e.key: List<String>.from(e.value as List),
    },
    photo: json['photo'] as String?,
    financeCodeSet: json['finance_code_set'] == true,
    financeCodeOn: json['finance_code_on'] == true,
    group: json['group'] == null
        ? null
        : GroupInfo.fromJson(json['group'] as Map<String, dynamic>),
    groups: [
      for (final g in (json['groups'] as List?) ?? const [])
        GroupInfo.fromJson(g as Map<String, dynamic>),
    ],
    // Unknown tab names (a newer server) are skipped, not a crash.
    tabs: [
      for (final t in json['tabs'] as List)
        if (AppTab.values.any((v) => v.name == t))
          AppTab.values.byName(t as String),
    ],
  );
}
