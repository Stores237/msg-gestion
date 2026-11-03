import '../../models/me.dart';

/// (slug, name) of one of the group's activity types or dress codes.
typedef NamedItem = (String, String);

/// The partner's contacts and texts (back-office → Plateforme), for Mon
/// compte → Aide / À propos. Empty = not filled in yet.
class PlatformInfo {
  const PlatformInfo({
    this.supportPhone = '',
    this.supportWhatsapp = '',
    this.supportEmail = '',
    this.website = '',
    this.privacyText = '',
    this.termsText = '',
  });

  final String supportPhone;
  final String supportWhatsapp;
  final String supportEmail;
  final String website;
  final String privacyText;
  final String termsText;

  factory PlatformInfo.fromJson(Map<String, dynamic> j) => PlatformInfo(
    supportPhone: (j['support_phone'] as String?) ?? '',
    supportWhatsapp: (j['support_whatsapp'] as String?) ?? '',
    supportEmail: (j['support_email'] as String?) ?? '',
    website: (j['website'] as String?) ?? '',
    privacyText: (j['privacy_text'] as String?) ?? '',
    termsText: (j['terms_text'] as String?) ?? '',
  );
}

class AppSettings {
  const AppSettings({
    required this.quickAmounts,
    required this.fees,
    this.activityTypes = defaultActivityTypes,
    this.dressCodes = defaultDressCodes,
    this.scopedTypes = defaultScopedTypes,
    this.typesWithoutChef = defaultTypesWithoutChef,
    this.eventMinutes = 120,
    this.remindBeforeHours = 2,
    this.reportHours = 24,
    this.contactPhone = '',
    this.contactEmail = '',
    this.website = '',
    this.rulesText = '',
  });

  /// Wider group settings (back-office → Paramètres, owner 2026-11-02).
  /// An event without an end time lasts this long.
  final int eventMinutes;

  /// "N h avant" reminders.
  final int remindBeforeHours;

  /// The chef de groupe's report is due this long after the end.
  final int reportHours;

  /// The group's own contacts and rules (Aide → Mon groupe).
  final String contactPhone;
  final String contactEmail;
  final String website;
  final String rulesText;

  /// Types whose events say intérieur or extérieur (Messe).
  final Set<String> scopedTypes;

  /// Types with no chef de groupe (Réunion); every other type has one.
  final Set<String> typesWithoutChef;
  static const defaultScopedTypes = {'messe'};
  static const defaultTypesWithoutChef = {'reunion'};
  final List<int> quickAmounts;

  /// The group's own lists (back-office → Paramètres).
  final List<NamedItem> activityTypes;
  final List<NamedItem> dressCodes;

  static const defaultActivityTypes = <NamedItem>[
    ('assise', 'Assise du samedi'),
    ('messe', 'Messe'),
    ('grande_veillee', 'Grande veillée'),
    ('reunion', 'Réunion'),
    ('autre', 'Autre'),
  ];
  static const defaultDressCodes = <NamedItem>[
    ('interieure', 'Tenue intérieure'),
    ('exterieure', 'Tenue extérieure'),
    ('sportive', 'Tenue sportive'),
    ('civile', 'Tenue civile'),
  ];

  /// inscription | medaille | maladie | deces → amount
  final Map<String, int> fees;

  static const fallback = AppSettings(
    quickAmounts: [500, 1000, 2000, 2500],
    fees: {
      'inscription': 500,
      'medaille': 2000,
      'maladie': 1000,
      'deces': 2500,
    },
  );
}

class BureauHome {
  const BureauHome({
    this.membersActive,
    this.toValidate,
    this.toConfirm,
    this.collections = const [],
    this.unfilled = const [],
  });
  final int? membersActive;
  final int? toValidate;

  /// Lines the trésorier edited and validated, for the commissaire.
  final int? toConfirm;

  /// (id, title, paid_full, members)
  final List<(int, String, int, int)> collections;

  /// (title, starts_at, missing)
  final List<(String, DateTime, int)> unfilled;

  bool get isEmpty =>
      membersActive == null &&
      toValidate == null &&
      collections.isEmpty &&
      unfilled.isEmpty;
}

/// One question of Aide → Questions fréquentes, from the server.
typedef FaqItem = (String question, String answer);

/// The platform's common questions and the group's own (owner, 2026-11-02).
class FaqData {
  const FaqData({this.common = const [], this.group = const []});
  final List<FaqItem> common;
  final List<FaqItem> group;
}

/// A question the member proposed: pending | published | declined.
class FaqSuggestion {
  const FaqSuggestion({
    required this.id,
    required this.question,
    required this.status,
    this.note = '',
  });
  final int id;
  final String question;
  final String status;
  final String note;
}

/// A group in a network, as the Réseau screen lists it (owner, 2026-11-03).
class NetworkGroup {
  const NetworkGroup({
    required this.group,
    this.levelName = '',
    this.below = 0,
    this.shares = const [],
  });
  final GroupInfo group;
  final String levelName;

  /// The kinds it shares with the groups above (children list only).
  final List<String> shares;

  /// Groups under it, at any depth (children list only).
  final int below;

  factory NetworkGroup.fromJson(Map<String, dynamic> j) => NetworkGroup(
    group: GroupInfo.fromJson(j),
    levelName: (j['level_name'] as String?) ?? '',
    below: (j['children'] as int?) ?? 0,
    shares: [for (final k in (j['shares'] as List?) ?? const []) k as String],
  );
}

/// Where the current group stands: its network, the groups above it (nearest
/// first) and those attached to it. The président joins, leaves and, in an
/// umbrella group, invites; everyone can look.
class NetworkInfo {
  const NetworkInfo({
    this.networkName,
    this.levels = const [],
    this.levelName = '',
    this.parents = const [],
    this.children = const [],
    this.canManage = false,
    this.canInvite = false,
    this.invitations = const [],
    this.totals,
    this.sharing,
  });

  /// Below an umbrella: (groups, groups sharing their members, members).
  final ({int groups, int sharingMembers, int members})? totals;

  /// What this group shares upward (attached groups only).
  final Map<String, String>? sharing;
  final String? networkName;
  final List<String> levels;
  final String levelName;
  final List<NetworkGroup> parents;
  final List<NetworkGroup> children;
  final bool canManage;
  final bool canInvite;
  final List<Invitation> invitations;

  factory NetworkInfo.fromJson(Map<String, dynamic> j) {
    final net = j['network'] as Map<String, dynamic>?;
    return NetworkInfo(
      networkName: net?['name'] as String?,
      levels: [
        for (final l in (net?['levels'] as List?) ?? const []) l as String,
      ],
      levelName: (j['level_name'] as String?) ?? '',
      parents: [
        for (final g in (j['parents'] as List?) ?? const [])
          NetworkGroup.fromJson(g as Map<String, dynamic>),
      ],
      children: [
        for (final g in (j['children'] as List?) ?? const [])
          NetworkGroup.fromJson(g as Map<String, dynamic>),
      ],
      canManage: j['can_manage'] == true,
      canInvite: j['can_invite'] == true,
      invitations: [
        for (final i in (j['invitations'] as List?) ?? const [])
          Invitation.fromJson(i as Map<String, dynamic>),
      ],
      totals: switch (j['totals']) {
        final Map<String, dynamic> t => (
          groups: t['groups'] as int,
          sharingMembers: t['sharing_members'] as int,
          members: t['members'] as int,
        ),
        _ => null,
      },
      sharing: (j['sharing'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v as String),
      ),
    );
  }
}

/// What a group shares upward (owner, 2026-11-03): per kind "none",
/// "summary" or "detail"; [options] lists the levels each kind offers.
class SharingSettings {
  const SharingSettings({
    required this.values,
    required this.options,
    this.canManage = false,
  });
  final Map<String, String> values;
  final Map<String, List<String>> options;
  final bool canManage;

  static const kinds = [
    'members',
    'finances',
    'calendar',
    'announcements',
    'reports',
  ];

  factory SharingSettings.fromJson(Map<String, dynamic> j) => SharingSettings(
    values: (j['values'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as String),
    ),
    options: (j['options'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, [for (final o in v as List) o as String]),
    ),
    canManage: j['can_manage'] == true,
  );
}

/// One kind a group below shares: its level and the data, or [hidden]
/// when the viewer's role up here doesn't cover it.
class SharedKind {
  const SharedKind({required this.level, this.hidden = false, this.data});
  final String level;
  final bool hidden;
  final Map<String, dynamic>? data;
}

/// A group below, as far as it shares and the viewer may read.
class SharedGroup {
  const SharedGroup({
    required this.group,
    this.levelName = '',
    this.parent,
    this.shared = const {},
  });
  final GroupInfo group;
  final String levelName;
  final String? parent;
  final Map<String, SharedKind> shared;

  factory SharedGroup.fromJson(Map<String, dynamic> j) => SharedGroup(
    group: GroupInfo.fromJson(j),
    levelName: (j['level_name'] as String?) ?? '',
    parent: j['parent'] as String?,
    shared: ((j['shared'] as Map<String, dynamic>?) ?? const {}).map(
      (k, v) => MapEntry(
        k,
        SharedKind(
          level: v['level'] as String,
          hidden: v['hidden'] == true,
          data: v['data'] as Map<String, dynamic>?,
        ),
      ),
    ),
  );
}

/// An umbrella group's single-use code ("ABCD-EFGH").
class Invitation {
  const Invitation({required this.code, required this.expiresAt});
  final String code;
  final DateTime expiresAt;

  factory Invitation.fromJson(Map<String, dynamic> j) => Invitation(
    code: j['code'] as String,
    expiresAt: DateTime.parse(j['expires_at'] as String).toLocal(),
  );
}

/// Who a code comes from, shown before the président accepts.
class InvitationPreview {
  const InvitationPreview({
    required this.group,
    this.levelName = '',
    this.network = '',
    this.parents = const [],
  });
  final GroupInfo group;
  final String levelName;
  final String network;
  final List<String> parents;

  factory InvitationPreview.fromJson(Map<String, dynamic> j) =>
      InvitationPreview(
        group: GroupInfo.fromJson(j),
        levelName: (j['level_name'] as String?) ?? '',
        network: (j['network'] as String?) ?? '',
        parents: [
          for (final p in (j['parents'] as List?) ?? const []) p as String,
        ],
      );
}

abstract class ProfileRepository {
  Future<Me> fetchMe();
  Future<AppSettings> settings();
  Future<void> setReminders({bool? eve, bool? twoHours});
  Future<BureauHome> bureauHome();

  /// The member's own picture: returns its new URL; [removeMyPhoto] clears it.
  Future<String?> uploadMyPhoto({
    required List<int> bytes,
    required String filename,
  });
  Future<void> removeMyPhoto();

  /// The group's name and sigle (the group.profile right: the président).
  Future<GroupInfo> updateGroup({String? name, String? shortName});

  /// Its logo (JPEG/PNG, cropped to a square by the server), or none.
  Future<GroupInfo> uploadGroupLogo({
    required List<int> bytes,
    required String filename,
  });
  Future<GroupInfo> removeGroupLogo();

  Future<PlatformInfo> platform();

  Future<FaqData> faq();
  Future<List<FaqSuggestion>> myFaqSuggestions();
  Future<void> suggestFaq({required String question, String answer = ''});

  /// The group's network (owner, 2026-11-03).
  Future<NetworkInfo> network();
  Future<InvitationPreview> previewInvitation(String code);
  Future<NetworkInfo> joinNetwork(String code);
  Future<NetworkInfo> leaveNetwork(String reason);
  Future<Invitation> createInvitation();
  Future<void> revokeInvitation(String code);
  Future<SharingSettings> sharing();
  Future<SharingSettings> saveSharing(Map<String, String> values);
  Future<SharedGroup> sharedGroup(int id);
}
