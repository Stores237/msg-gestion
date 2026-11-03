import 'package:flutter/material.dart';

import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../../theme/tokens.dart';
import '../../widgets/errors.dart';
import '../../widgets/group_logo.dart';
import '../../widgets/member_picker.dart';
import '../../widgets/ui.dart';

/// Joint planning, the asking side (owner, 2026-11-03): how many people
/// each group attached below should send, and whom each one named. The
/// groups below choose the people themselves.
class ContingentsScreen extends StatefulWidget {
  const ContingentsScreen({super.key, required this.event});
  final CalendarEvent event;

  @override
  State<ContingentsScreen> createState() => _ContingentsScreenState();
}

class _ContingentsScreenState extends State<ContingentsScreen> {
  ContingentBoard? _board;
  final _wanted = <int, int>{};
  Object? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final b = await RepositoryLocator.instance.events.contingents(
        widget.event.id,
      );
      if (!mounted) return;
      setState(() {
        _board = b;
        _wanted
          ..clear()
          ..addAll({for (final r in b.groups) r.group.id: r.requested});
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  bool get _dirty =>
      _board?.groups.any((r) => _wanted[r.group.id] != r.requested) ?? false;

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final b = _board!;
    setState(() => _busy = true);
    try {
      final saved = await RepositoryLocator.instance.events
          .askContingents(widget.event.id, [
            for (final r in b.groups)
              if (_wanted[r.group.id] != r.requested)
                (
                  group: r.group.id,
                  requested: _wanted[r.group.id]!,
                  note: r.note,
                ),
          ]);
      if (!mounted) return;
      setState(() => _board = saved);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.contingentAsked)));
      await _load();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final b = _board;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.contingentsTitle, back: true, small: true),
            Expanded(
              child: b == null
                  ? Center(
                      child: _error == null
                          ? const CircularProgressIndicator()
                          : Text(describeError(context, _error!)),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        Text(
                          widget.event.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.contingentsAbout,
                          style: TextStyle(height: 1.5, color: c.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        if (b.groups.isEmpty)
                          Text(l.groupNetNoChildren)
                        else
                          GroupCard(
                            children: [
                              for (final r in b.groups)
                                Padding(
                                  key: Key('contingent-${r.group.id}'),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          GroupLogo(group: r.group, size: 32),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              r.group.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (b.canPlan) ...[
                                            IconButton(
                                              key: Key('less-${r.group.id}'),
                                              tooltip: l.contingentLess,
                                              onPressed:
                                                  (_wanted[r.group.id] ?? 0) > 0
                                                  ? () => setState(
                                                      () =>
                                                          _wanted[r.group.id] =
                                                              _wanted[r
                                                                  .group
                                                                  .id]! -
                                                              1,
                                                    )
                                                  : null,
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                              ),
                                            ),
                                            Text(
                                              '${_wanted[r.group.id] ?? 0}',
                                              key: Key('wanted-${r.group.id}'),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            IconButton(
                                              key: Key('more-${r.group.id}'),
                                              tooltip: l.contingentMore,
                                              onPressed: () => setState(
                                                () => _wanted[r.group.id] =
                                                    (_wanted[r.group.id] ?? 0) +
                                                    1,
                                              ),
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                              ),
                                            ),
                                          ] else
                                            Text('${r.requested}'),
                                        ],
                                      ),
                                      if (r.requested > 0) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          r.members.isEmpty
                                              ? l.contingentWaiting
                                              : l.contingentNamed(
                                                  r.members.length,
                                                  r.requested,
                                                  r.members
                                                      .map((m) => m.name)
                                                      .join(', '),
                                                ),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: c.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        if (b.canPlan) ...[
                          const SizedBox(height: 16),
                          FilledButton(
                            key: const Key('contingents-save'),
                            onPressed: _busy || !_dirty ? null : _save,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: const StadiumBorder(),
                            ),
                            child: Text(l.contingentSend),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Joint planning, the asked side: the group above wants N people; the
/// planning officer here names them (from this group only).
class MyContingentScreen extends StatefulWidget {
  const MyContingentScreen({super.key, required this.event});
  final CalendarEvent event;

  @override
  State<MyContingentScreen> createState() => _MyContingentScreenState();
}

class _MyContingentScreenState extends State<MyContingentScreen> {
  MyContingent? _c;
  Object? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    RepositoryLocator.instance.events
        .myContingent(widget.event.id)
        .then((c) {
          if (mounted) setState(() => _c = c);
        })
        .catchError((Object e) {
          if (mounted) setState(() => _error = e);
        });
  }

  Future<void> _name() async {
    final l = AppLocalizations.of(context);
    final picked = await pickMembers(
      context,
      selected: [for (final m in _c!.members) m.id],
      withRoles: true,
    );
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final c = await RepositoryLocator.instance.events.answerContingent(
        widget.event.id,
        [for (final m in picked) m.id],
      );
      if (!mounted) return;
      setState(() => _c = c);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.contingentSaved)));
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final m = _c;
    final from = widget.event.fromGroup?.name ?? '';
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.contingentTitle, back: true, small: true),
            Expanded(
              child: m == null
                  ? Center(
                      child: _error == null
                          ? const CircularProgressIndicator()
                          : Text(describeError(context, _error!)),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        Text(
                          widget.event.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.contingentAsk(from, m.requested),
                          key: const Key('contingent-ask'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (m.note.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            m.note,
                            style: TextStyle(color: c.textSecondary),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SectionLabel(
                          l.contingentNamedLabel(m.members.length, m.requested),
                        ),
                        const SizedBox(height: 8),
                        if (m.members.isEmpty)
                          Text(
                            l.contingentNobody,
                            style: TextStyle(color: c.textSecondary),
                          )
                        else
                          GroupCard(
                            children: [
                              for (final p in m.members)
                                ListRow(
                                  key: Key('named-${p.id}'),
                                  lead: const Icon(Icons.person_outline),
                                  title: Text(p.name),
                                ),
                            ],
                          ),
                        if (m.canAnswer) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            key: const Key('contingent-name'),
                            onPressed: _busy ? null : _name,
                            icon: const Icon(Icons.group_add_outlined),
                            label: Text(l.contingentChoose),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: const StadiumBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l.contingentChooseHint,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
