import 'me.dart';

/// A group a post or an event can go to (build 48): below this one (at
/// any depth), a neighbour (same parent) or a twin.
class ReachGroup {
  const ReachGroup({
    required this.group,
    required this.relation,
    this.depth = 0,
    this.levelName = '',
    this.parent,
  });
  final GroupInfo group;

  /// below | neighbour | twin
  final String relation;

  /// For a group below: 1 = attached directly, 2 = under one of those…
  final int depth;
  final String levelName;
  final String? parent;

  int get id => group.id;

  factory ReachGroup.fromJson(Map<String, dynamic> j) => ReachGroup(
    group: GroupInfo.fromJson(j),
    relation: (j['relation'] as String?) ?? 'below',
    depth: (j['depth'] as int?) ?? 0,
    levelName: (j['level_name'] as String?) ?? '',
    parent: j['parent'] as String?,
  );
}

/// Who receives a post in the network (owner, 2026-11-04: "select who
/// should receive"): the chosen groups, everyone there or the bureau only.
class NetworkReach {
  const NetworkReach({this.groups = const [], this.audience = 'all'});
  final List<GroupInfo> groups;

  /// all | bureau
  final String audience;

  bool get bureauOnly => audience == 'bureau';
  List<int> get ids => [for (final g in groups) g.id];
}

/// Where this group sent a post or an event (null on other groups' ones).
/// [allBelow]: every group below, chosen before build 48.
class SentTo {
  const SentTo({
    this.allBelow = false,
    this.audience = 'all',
    this.groups = const [],
  });
  final bool allBelow;
  final String audience;
  final List<GroupInfo> groups;

  static SentTo? fromJson(Object? j) => j is Map<String, dynamic>
      ? SentTo(
          allBelow: j['all_below'] == true,
          audience: (j['audience'] as String?) ?? 'all',
          groups: [
            for (final g in (j['groups'] as List?) ?? const [])
              GroupInfo.fromJson(g as Map<String, dynamic>),
          ],
        )
      : null;
}
