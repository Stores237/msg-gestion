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
  });

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
  });

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
