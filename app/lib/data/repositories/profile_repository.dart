import '../../models/me.dart';
import '../../models/network_reach.dart';

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
    this.waiting = false,
  });
  final GroupInfo group;
  final String levelName;

  /// Set up by the platform team, no président yet (build 46).
  final bool waiting;

  /// The kinds it shares with the groups above (children list only).
  final List<String> shares;

  /// Groups under it, at any depth (children list only).
  final int below;

  factory NetworkGroup.fromJson(Map<String, dynamic> j) => NetworkGroup(
    group: GroupInfo.fromJson(j),
    levelName: (j['level_name'] as String?) ?? '',
    below: (j['children'] as int?) ?? 0,
    shares: [for (final k in (j['shares'] as List?) ?? const []) k as String],
    waiting: j['waiting'] == true,
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
    this.neighbours = const [],
    this.twins = const [],
    this.sharingNeighbours,
    this.sharingTwins,
    this.twinInvitations = const [],
    this.requestsWaiting = 0,
  });

  /// Visibility requests waiting for the président (build 48).
  final int requestsWaiting;

  /// Groups under the same parent, and twinned groups (build 43), each
  /// with what it shares with this group.
  final List<NetworkGroup> neighbours;
  final List<NetworkGroup> twins;

  /// What this group shares with its neighbours / twins (null: none).
  final Map<String, String>? sharingNeighbours;
  final Map<String, String>? sharingTwins;
  final List<Invitation> twinInvitations;

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
      sharing: _levels(j['sharing']),
      neighbours: [
        for (final g in (j['neighbours'] as List?) ?? const [])
          NetworkGroup.fromJson(g as Map<String, dynamic>),
      ],
      twins: [
        for (final g in (j['twins'] as List?) ?? const [])
          NetworkGroup.fromJson(g as Map<String, dynamic>),
      ],
      sharingNeighbours: _levels(j['sharing_neighbours']),
      sharingTwins: _levels(j['sharing_twins']),
      twinInvitations: [
        for (final i in (j['twin_invitations'] as List?) ?? const [])
          Invitation.fromJson(i as Map<String, dynamic>),
      ],
      requestsWaiting: (j['requests_waiting'] as int?) ?? 0,
    );
  }
}

Map<String, String>? _levels(Object? m) =>
    (m as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as String));

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

/// A linked group, as far as it shares and the viewer may read.
class SharedGroup {
  const SharedGroup({
    required this.group,
    this.levelName = '',
    this.parent,
    this.relation = 'up',
    this.shared = const {},
    this.kinds = const [],
  });
  final GroupInfo group;
  final String levelName;
  final String? parent;

  /// How the viewer's group sees it: up (it is below), neighbours, twins.
  final String relation;
  final Map<String, SharedKind> shared;

  /// Every kind, shared or not (build 48), for the filters and requests.
  final List<KindStatus> kinds;

  factory SharedGroup.fromJson(Map<String, dynamic> j) => SharedGroup(
    group: GroupInfo.fromJson(j),
    levelName: (j['level_name'] as String?) ?? '',
    parent: j['parent'] as String?,
    relation: (j['relation'] as String?) ?? 'up',
    shared: sharedKinds(j['shared']),
    kinds: [
      for (final k in (j['kinds'] as List?) ?? const [])
        KindStatus.fromJson(k as Map<String, dynamic>),
    ],
  );
}

Map<String, SharedKind> sharedKinds(Object? m) =>
    ((m as Map<String, dynamic>?) ?? const {}).map(
      (k, v) => MapEntry(
        k,
        SharedKind(
          level: v['level'] as String,
          hidden: v['hidden'] == true,
          data: v['data'] as Map<String, dynamic>?,
        ),
      ),
    );

/// One kind of a linked group, as the viewer stands with it (build 48).
class KindStatus {
  const KindStatus({
    required this.kind,
    this.level = 'none',
    this.state = 'none',
    this.levels = const [],
    this.data,
    this.request,
    this.lastAnswer,
    this.canRequest = false,
    this.nextLevel,
  });
  final String kind;
  final String level;

  /// shared (readable here) | hidden (shared, for other roles) | none
  final String state;

  /// The levels this kind offers (summary, detail).
  final List<String> levels;
  final Map<String, dynamic>? data;

  /// This group's request waiting for an answer, and the last answered one.
  final ShareRequestInfo? request;
  final ShareRequestInfo? lastAnswer;
  final bool canRequest;
  final String? nextLevel;

  factory KindStatus.fromJson(Map<String, dynamic> j) => KindStatus(
    kind: j['kind'] as String,
    level: (j['level'] as String?) ?? 'none',
    state: (j['state'] as String?) ?? 'none',
    levels: [for (final l in (j['levels'] as List?) ?? const []) l as String],
    data: j['data'] as Map<String, dynamic>?,
    request: j['request'] == null
        ? null
        : ShareRequestInfo.fromJson(j['request'] as Map<String, dynamic>),
    lastAnswer: j['last_answer'] == null
        ? null
        : ShareRequestInfo.fromJson(j['last_answer'] as Map<String, dynamic>),
    canRequest: j['can_request'] == true,
    nextLevel: j['next_level'] as String?,
  );
}

/// A group asking another to share more (build 48).
class ShareRequestInfo {
  const ShareRequestInfo({
    required this.id,
    required this.kind,
    required this.level,
    required this.fromGroup,
    required this.target,
    required this.createdAt,
    this.audience = 'up',
    this.note = '',
    this.status = 'pending',
    this.by = '',
    this.answeredAt,
    this.answerNote = '',
    this.current,
  });
  final int id;
  final String kind;
  final String level;
  final String audience;
  final String note;

  /// pending | accepted | declined | cancelled
  final String status;
  final GroupInfo fromGroup;
  final GroupInfo target;
  final String by;
  final DateTime createdAt;
  final DateTime? answeredAt;
  final String answerNote;

  /// What the asked group shares now (pending requests only).
  final String? current;

  bool get pending => status == 'pending';

  factory ShareRequestInfo.fromJson(Map<String, dynamic> j) => ShareRequestInfo(
    id: j['id'] as int,
    kind: j['kind'] as String,
    level: j['level'] as String,
    audience: (j['audience'] as String?) ?? 'up',
    note: (j['note'] as String?) ?? '',
    status: (j['status'] as String?) ?? 'pending',
    fromGroup: GroupInfo.fromJson(j['from_group'] as Map<String, dynamic>),
    target: GroupInfo.fromJson(j['target'] as Map<String, dynamic>),
    by: (j['by'] as String?) ?? '',
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
    answeredAt: j['answered_at'] == null
        ? null
        : DateTime.parse(j['answered_at'] as String).toLocal(),
    answerNote: (j['answer_note'] as String?) ?? '',
    current: j['current'] as String?,
  );
}

/// Requests this group received (the président answers) and sent.
class ShareRequests {
  const ShareRequests({
    this.canAnswer = false,
    this.incoming = const [],
    this.outgoing = const [],
  });
  final bool canAnswer;
  final List<ShareRequestInfo> incoming;
  final List<ShareRequestInfo> outgoing;

  factory ShareRequests.fromJson(Map<String, dynamic> j) => ShareRequests(
    canAnswer: j['can_answer'] == true,
    incoming: [
      for (final r in (j['incoming'] as List?) ?? const [])
        ShareRequestInfo.fromJson(r as Map<String, dynamic>),
    ],
    outgoing: [
      for (final r in (j['outgoing'] as List?) ?? const [])
        ShareRequestInfo.fromJson(r as Map<String, dynamic>),
    ],
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
  Future<InvitationPreview> previewInvitation(String code, {bool twin = false});
  Future<NetworkInfo> joinNetwork(String code);
  Future<NetworkInfo> leaveNetwork(String reason);

  /// [twin]: a twinning code (build 43) instead of an attach one.
  Future<Invitation> createInvitation({bool twin = false});
  Future<NetworkInfo> joinTwin(String code);
  Future<NetworkInfo> endTwin(int groupId, String reason);
  Future<void> revokeInvitation(String code);

  /// [audience]: up | neighbours | twins.
  Future<SharingSettings> sharing({String audience = 'up'});
  Future<SharingSettings> saveSharing(
    Map<String, String> values, {
    String audience = 'up',
  });
  Future<SharedGroup> sharedGroup(int id);

  /// Build 48: this group as others would see it with [values] (not saved).
  Future<Map<String, SharedKind>> previewSharing(Map<String, String> values);

  /// Ask group [groupId] to share [kind] at [level].
  Future<void> askShare(
    int groupId, {
    required String kind,
    required String level,
    String note = '',
  });
  Future<ShareRequests> shareRequests();
  Future<void> answerShareRequest(int id, {required bool accept, String note});
  Future<void> cancelShareRequest(int id);

  /// The groups a post or an event can go to.
  Future<List<ReachGroup>> recipients();
}
