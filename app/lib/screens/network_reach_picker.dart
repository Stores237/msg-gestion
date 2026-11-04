import 'package:flutter/material.dart';

import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/me.dart';
import '../models/network_reach.dart';
import '../theme/tokens.dart';
import '../widgets/group_logo.dart';
import '../widgets/ui.dart';

/// "Diffuser dans le réseau" (owner, 2026-11-04: "select who should
/// receive"): which groups of the network get a post or an event — below,
/// neighbours, twins — and whether everyone there or only their bureau.
/// Returns the choice (no group: not sent), or null when dismissed.
Future<NetworkReach?> pickNetworkReach(
  BuildContext context, {
  NetworkReach? current,
  bool allBelow = false,
}) => Navigator.of(context).push<NetworkReach>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => NetworkReachPicker(current: current, allBelow: allBelow),
  ),
);

/// One line under the "Diffuser dans le réseau" row: where it goes.
String reachSummary(AppLocalizations l, NetworkReach? r) {
  if (r == null || r.groups.isEmpty) return l.reachNone;
  final who = r.bureauOnly ? l.reachBureauOnly : l.reachEveryone;
  final where = r.groups.length == 1
      ? r.groups.first.name
      : l.reachGroupsCount(r.groups.length);
  return '$where · $who';
}

String reachRelationLabel(AppLocalizations l, ReachGroup g) =>
    switch (g.relation) {
      'neighbour' => l.reachNeighbour,
      'twin' => l.reachTwin,
      _ => g.depth <= 1 ? l.reachDirect : l.reachDeeper,
    };

class NetworkReachPicker extends StatefulWidget {
  const NetworkReachPicker({super.key, this.current, this.allBelow = false});
  final NetworkReach? current;

  /// Sent before build 48 to every group below: start with all of them.
  final bool allBelow;

  @override
  State<NetworkReachPicker> createState() => _NetworkReachPickerState();
}

class _NetworkReachPickerState extends State<NetworkReachPicker> {
  List<ReachGroup>? _groups;
  Object? _error;
  late final Set<int> _chosen = {...?widget.current?.ids};
  late String _audience = widget.current?.audience ?? 'all';
  int _filter = 0; // index into _filters
  String _query = '';

  static const _relations = [null, 'below', 'neighbour', 'twin'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final g = await RepositoryLocator.instance.profile.recipients();
      if (!mounted) return;
      setState(() {
        _groups = g;
        _error = null;
        if (widget.allBelow && _chosen.isEmpty) {
          _chosen.addAll([
            for (final x in g)
              if (x.relation == 'below') x.id,
          ]);
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  List<ReachGroup> get _shown {
    final rel = _relations[_filter];
    final q = _query.trim().toLowerCase();
    return [
      for (final g in _groups ?? const <ReachGroup>[])
        if ((rel == null || g.relation == rel) &&
            (q.isEmpty ||
                g.group.name.toLowerCase().contains(q) ||
                (g.parent ?? '').toLowerCase().contains(q)))
          g,
    ];
  }

  void _done({bool clear = false}) {
    final groups = _groups ?? const <ReachGroup>[];
    Navigator.of(context).pop(
      NetworkReach(
        groups: clear
            ? const []
            : [
                for (final g in groups)
                  if (_chosen.contains(g.id)) g.group,
              ],
        audience: _audience,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final groups = _groups;
    final count = {
      for (final r in _relations)
        r: (groups ?? const <ReachGroup>[])
            .where((g) => r == null || g.relation == r)
            .length,
    };
    final filters = [
      (null, l.reachFilterAll),
      ('below', l.reachFilterBelow),
      ('neighbour', l.reachFilterNeighbours),
      ('twin', l.reachFilterTwins),
    ];
    final shown = _shown;
    final allShownChosen =
        shown.isNotEmpty && shown.every((g) => _chosen.contains(g.id));

    // Sections: directly below, deeper (per level), neighbours, twins.
    final sections = <String, List<ReachGroup>>{};
    for (final g in shown) {
      final key = g.relation == 'below' && g.depth > 1 && g.levelName.isNotEmpty
          ? '${l.reachDeeper} · ${g.levelName}'
          : reachRelationLabel(l, g);
      (sections[key] ??= []).add(g);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.reachTitle, back: true, small: true),
            Expanded(
              child: groups == null
                  ? Center(
                      child: _error == null
                          ? const CircularProgressIndicator()
                          : EmptyState(
                              icon: Icons.cloud_off_outlined,
                              title: l.reachLoadError,
                              error: true,
                              action: TextButton(
                                onPressed: _load,
                                child: Text(l.retry),
                              ),
                            ),
                    )
                  : ListView(
                      key: const Key('reach-list'),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        Text(
                          l.reachAbout,
                          style: TextStyle(height: 1.5, color: c.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        SectionLabel(l.reachWho),
                        const SizedBox(height: 8),
                        Seg2(
                          key: const Key('reach-audience'),
                          options: [l.reachEveryone, l.reachBureauOnly],
                          selected: _audience == 'bureau' ? 1 : 0,
                          onChanged: (i) => setState(
                            () => _audience = i == 1 ? 'bureau' : 'all',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _audience == 'bureau'
                              ? l.reachBureauHint
                              : l.reachEveryoneHint,
                          style: TextStyle(
                            fontSize: 13,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SectionLabel(l.reachWhere),
                        const SizedBox(height: 8),
                        if (groups.length > 6) ...[
                          TextField(
                            key: const Key('reach-search'),
                            onChanged: (v) => setState(() => _query = v),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: l.reachSearch,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        FilterChips(
                          labels: [
                            for (final (r, label) in filters)
                              if (r == null || count[r]! > 0)
                                '$label (${count[r]})',
                          ],
                          selected: [
                            for (final (r, _) in filters)
                              if (r == null || count[r]! > 0) r,
                          ].indexOf(_relations[_filter]),
                          onSelected: (i) {
                            final visible = [
                              for (final (r, _) in filters)
                                if (r == null || count[r]! > 0) r,
                            ];
                            setState(
                              () => _filter = _relations.indexOf(visible[i]),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        if (shown.isEmpty)
                          EmptyState(
                            icon: Icons.hub_outlined,
                            title: groups.isEmpty
                                ? l.reachNoGroups
                                : l.reachNoMatch,
                          )
                        else ...[
                          GroupCard(
                            children: [
                              ListRow(
                                key: const Key('reach-all'),
                                title: Text(
                                  allShownChosen
                                      ? l.reachUnselectAll
                                      : l.reachSelectAll,
                                ),
                                subtitle: Text(
                                  l.reachChosenCount(_chosen.length),
                                ),
                                trailing: Checkbox(
                                  value: allShownChosen
                                      ? true
                                      : (shown.any(
                                              (g) => _chosen.contains(g.id),
                                            )
                                            ? null
                                            : false),
                                  tristate: true,
                                  onChanged: (_) => _toggleAll(shown),
                                ),
                                onTap: () => _toggleAll(shown),
                              ),
                            ],
                          ),
                          for (final MapEntry(key: title, value: rows)
                              in sections.entries) ...[
                            const SizedBox(height: 16),
                            SectionLabel(title),
                            const SizedBox(height: 8),
                            GroupCard(
                              children: [for (final g in rows) _row(l, c, g)],
                            ),
                          ],
                        ],
                      ],
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: c.surfaceCard,
                border: Border(top: BorderSide(color: c.borderSubtle)),
              ),
              child: Row(
                children: [
                  TextButton(
                    key: const Key('reach-none'),
                    onPressed: () => _done(clear: true),
                    child: Text(l.reachDontSend),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      key: const Key('reach-done'),
                      onPressed: groups == null ? null : _done,
                      child: Text(
                        _chosen.isEmpty
                            ? l.reachDontSend
                            : l.reachConfirm(_chosen.length),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleAll(List<ReachGroup> shown) {
    final all = shown.every((g) => _chosen.contains(g.id));
    setState(() {
      for (final g in shown) {
        all ? _chosen.remove(g.id) : _chosen.add(g.id);
      }
    });
  }

  Widget _row(AppLocalizations l, MsgColors c, ReachGroup g) {
    final on = _chosen.contains(g.id);
    void toggle() =>
        setState(() => on ? _chosen.remove(g.id) : _chosen.add(g.id));
    return ListRow(
      key: Key('reach-${g.id}'),
      lead: GroupLogo(group: g.group, size: 36),
      title: Text(g.group.name),
      subtitle: Text(
        [
          if (g.levelName.isNotEmpty) g.levelName,
          if (g.relation == 'below' && g.depth > 1 && g.parent != null)
            l.reachUnder(g.parent!),
        ].join(' · '),
      ),
      trailing: Checkbox(value: on, onChanged: (_) => toggle()),
      onTap: toggle,
    );
  }
}

/// The chosen groups as small chips, under the "Diffuser" row.
class ReachChips extends StatelessWidget {
  const ReachChips({super.key, required this.groups});
  final List<GroupInfo> groups;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final g in groups.take(12))
        Chip(
          avatar: GroupLogo(group: g, size: 22),
          label: Text(g.name),
          visualDensity: VisualDensity.compact,
        ),
      if (groups.length > 12)
        Chip(
          label: Text('+${groups.length - 12}'),
          visualDensity: VisualDensity.compact,
        ),
    ],
  );
}
