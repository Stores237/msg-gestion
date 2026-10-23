import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/me.dart';
import '../../models/planning.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/dates.dart';
import '../../widgets/errors.dart';
import '../../widgets/labels.dart';
import '../../widgets/notice.dart';
import '../../widgets/ui.dart';
import 'albs_screen.dart';
import 'duty_widgets.dart';
import 'requests_screen.dart';

/// "Planning · semaine" (design): one column per service, horizontal
/// scroll; alerts on top; tap a free cell for candidates; publish.
class PlanningWeekView extends StatefulWidget {
  const PlanningWeekView({super.key, required this.me, required this.header});
  final Me me;
  final Widget header;

  @override
  State<PlanningWeekView> createState() => _PlanningWeekViewState();
}

class _PlanningWeekViewState extends State<PlanningWeekView> {
  DateTime _day = DateTime.now();
  PlanningWeek? _week;
  Object? _error;
  bool _busy = false;

  bool get _canEdit => widget.me.can('calendar.planning', 'change');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final w = await RepositoryLocator.instance.planning.week(_day);
      if (!mounted) return;
      setState(() {
        _week = w;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _shift(int days) {
    setState(() {
      _day = _day.add(Duration(days: days));
      _week = null;
    });
    _load();
  }

  Future<void> _tapSlot(PlannedService s, Slot slot) async {
    if (!_canEdit) return;
    final current = s.at(slot);
    final picked = await showModalBottomSheet<_SlotChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (context, scroll) => _CandidateSheet(
          service: s,
          slot: slot,
          current: current,
          scroll: scroll,
        ),
      ),
    );
    if (picked == null) return;
    await _assign(s, slot, picked.memberId, force: picked.force);
  }

  Future<void> _assign(
    PlannedService s,
    Slot slot,
    int? member, {
    bool force = false,
  }) async {
    final l = AppLocalizations.of(context);
    try {
      await RepositoryLocator.instance.planning.setSlot(
        s.id,
        slot,
        member,
        force: force,
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'double_service') {
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(e.detail ?? l.flagBusy),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l.cancel),
              ),
              FilledButton(
                key: const Key('force-assign'),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l.assignAnyway),
              ),
            ],
          ),
        );
        if (ok == true) await _assign(s, slot, member, force: true);
      } else {
        showErrorSnack(context, e);
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  /// The chef de groupe is chosen for each service, among its guards
  /// (anyone can be chef). Only whoever makes the lineup sees this.
  Future<void> _chooseChef(PlannedService s) async {
    final l = AppLocalizations.of(context);
    final guards = s.assignments
        .where((a) => a.status != 'repl' && a.status != 'absent')
        .toList();
    if (guards.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.chefNeedsGuards)));
      return;
    }
    // Wrapped so "remove" (null) differs from dismissing the sheet.
    final choice = await showModalBottomSheet<({int? id})>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              l.designateChef,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(l.chefSheetHint),
            const SizedBox(height: 12),
            GroupCard(
              children: [
                for (final a in guards)
                  ListRow(
                    key: Key('chef-${a.memberId}'),
                    lead: MemberAvatar(name: a.memberName, size: 36),
                    title: Text(a.memberName),
                    subtitle: Text(
                      '${postLabel(l, a.slot.post)} · ${sideLabel(l, a.slot.side)}',
                    ),
                    trailing: a.memberId == s.chefId
                        ? const Icon(Icons.flag)
                        : null,
                    onTap: () => Navigator.of(context).pop((id: a.memberId)),
                  ),
              ],
            ),
            if (s.chefId != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('remove-chef'),
                onPressed: () => Navigator.of(context).pop((id: null)),
                icon: const Icon(Icons.outlined_flag),
                label: Text(l.removeChef),
              ),
            ],
          ],
        ),
      ),
    );
    if (choice == null || choice.id == s.chefId) return;
    try {
      await RepositoryLocator.instance.planning.setChef(s.id, choice.id);
      await _load();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _assignGroup(PlannedService s) async {
    final l = AppLocalizations.of(context);
    final groups = await RepositoryLocator.instance.planning
        .groups()
        .catchError((Object e) {
          if (mounted) showErrorSnack(context, e);
          return <ServiceGroupInfo>[];
        });
    if (!mounted || groups.isEmpty) return;
    final g = await showModalBottomSheet<ServiceGroupInfo>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(l.assignGroup, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GroupCard(
            children: [
              for (final g in groups)
                ListRow(
                  key: Key('group-${g.id}'),
                  title: Text(g.name),
                  subtitle: Text(
                    [l.groupMembersInfo(g.members, g.available)].join('\n'),
                  ),
                  onTap: () => Navigator.of(context).pop(g),
                ),
            ],
          ),
        ],
      ),
    );
    if (g == null) return;
    try {
      final (assigned, empty) = await RepositoryLocator.instance.planning
          .assignGroup(s.id, g.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.groupAssigned(assigned, empty))));
      _load();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _planEvent(UnplannedEvent e) async {
    final l = AppLocalizations.of(context);
    final size = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${l.serviceSize} · ${e.title}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final n in serviceSizes)
                  ChoiceChip(
                    key: Key('size-$n'),
                    label: Text('$n'),
                    selected: false,
                    onSelected: (_) => Navigator.of(context).pop(n),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    if (size == null) return;
    try {
      await RepositoryLocator.instance.planning.setServiceSize(e.eventId, size);
      _load();
    } catch (err) {
      if (mounted) showErrorSnack(context, err);
    }
  }

  Future<void> _publish() async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final n = await RepositoryLocator.instance.planning.publish(_day);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.publishedDone(n))));
      _load();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _alertText(AppLocalizations l, PlanningAlert a) {
    final w = _week!;
    switch (a.code) {
      case 'understaffed':
        final s = w.services.firstWhere((s) => s.id == a.serviceId);
        return l.alertUnderstaffed(s.title, a.filled ?? 0, a.size ?? s.size);
      case 'double_service':
        return l.alertDouble(a.member ?? '');
      default:
        return l.alertOnLeave(a.member ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final d = Dates(context);
    final w = _week;
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                widget.header,
                Row(
                  children: [
                    IconButton(
                      tooltip: l.previousWeek,
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _shift(-7),
                    ),
                    Expanded(
                      child: Text(
                        w == null
                            ? ''
                            : l.weekOf(d.dayMonth(w.start), d.dayMonth(w.end)),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l.nextWeek,
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _shift(7),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      key: const Key('open-requests'),
                      avatar: const Icon(Icons.swap_horiz, size: 18),
                      label: Text(l.requests),
                      onPressed: () => Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => RequestsScreen(me: widget.me),
                            ),
                          )
                          .then((_) => _load()),
                    ),
                    ActionChip(
                      key: const Key('open-albs'),
                      avatar: const Icon(Icons.checkroom_outlined, size: 18),
                      label: Text(l.albs),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AlbsScreen(me: widget.me),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (w == null && _error != null)
                  EmptyState(
                    icon: Icons.cloud_off_outlined,
                    error: true,
                    title: l.loadError,
                    text: describeError(context, _error!),
                    action: FilledButton(
                      onPressed: _load,
                      child: Text(l.retry),
                    ),
                  )
                else if (w == null)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  if (w.alerts.isNotEmpty) ...[
                    Notice(
                      tone: NoticeTone.warn,
                      text:
                          '${l.alertsCount(w.alerts.length)} · ${w.alerts.map((a) => _alertText(l, a)).join(' · ')}',
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (w.services.isEmpty && w.unplanned.isEmpty)
                    EmptyState(
                      icon: Icons.event_busy_outlined,
                      title: l.noServicesWeek,
                    ),
                  if (w.services.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final s in w.services)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _Column(
                                service: s,
                                onTap: (slot) => _tapSlot(s, slot),
                                onGroup: _canEdit
                                    ? () => _assignGroup(s)
                                    : null,
                                onChef: _canEdit ? () => _chooseChef(s) : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (_canEdit && w.unplanned.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SectionLabel(l.setServiceSize),
                    const SizedBox(height: 8),
                    GroupCard(
                      children: [
                        for (final e in w.unplanned)
                          ListRow(
                            key: Key('unplanned-${e.eventId}'),
                            title: Text(e.title),
                            subtitle: Text(d.fullDateTime(e.startsAt)),
                            trailing: const Icon(Icons.add),
                            onTap: () => _planEvent(e),
                          ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        if (_canEdit && w != null && w.services.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: c.surfaceCard,
              border: Border(top: BorderSide(color: c.borderSubtle)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: w.published
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check),
                      label: Text(l.published),
                    )
                  : FilledButton.icon(
                      key: const Key('publish'),
                      onPressed: _busy ? null : _publish,
                      icon: const Icon(Icons.send_outlined, size: 18),
                      label: Text(l.publishAndNotify),
                    ),
            ),
          ),
      ],
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.service,
    required this.onTap,
    this.onGroup,
    this.onChef,
  });
  final PlannedService service;
  final ValueChanged<Slot> onTap;
  final VoidCallback? onGroup;
  final VoidCallback? onChef;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final d = Dates(context);
    final s = service;
    final posts = <String>[];
    for (final slot in s.slots) {
      if (!posts.contains(slot.post)) posts.add(slot.post);
    }
    final under = s.filled < s.size;
    return Container(
      key: Key('service-${s.id}'),
      width: 180,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: BorderRadius.circular(MsgRadius.lg),
        border: Border.all(
          color: under ? c.warn : c.borderSubtle,
          width: under ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${d.weekdayShort(s.startsAt)} ${s.startsAt.day} · ${d.time(s.startsAt)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFeatures: tabular,
            ),
          ),
          Text(
            '${s.title} · ${l.filledOf(s.filled, s.size)}',
            style: TextStyle(fontSize: 12, color: c.textSecondary),
          ),
          if (s.chef != null || onChef != null)
            InkWell(
              key: Key('chef-btn-${s.id}'),
              onTap: onChef,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: onChef == null ? 0 : 40),
                child: Row(
                  children: [
                    Icon(
                      s.chef == null
                          ? Icons.outlined_flag
                          : Icons.flag_outlined,
                      size: 14,
                      color: s.chef == null ? c.warnText : c.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        s.chef != null ? l.chefLabel(s.chef!) : l.noChefYet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: s.chef == null ? c.warnText : c.textSecondary,
                          fontWeight: s.chef == null ? FontWeight.w600 : null,
                        ),
                      ),
                    ),
                    if (onChef != null)
                      Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: c.textTertiary,
                      ),
                  ],
                ),
              ),
            ),
          for (final post in posts) ...[
            const SizedBox(height: 8),
            Text(
              postLabel(l, post).toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            for (final idx
                in s.slots
                    .where((x) => x.post == post)
                    .map((x) => x.index)
                    .toSet())
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    for (final side in const ['pariso', 'yapoma']) ...[
                      Expanded(
                        child: PlanCell(
                          key: Key('cell-${s.id}-$post-$side-$idx'),
                          side: side,
                          assignment: s.at(Slot(post, side, idx)),
                          onTap: () => onTap(Slot(post, side, idx)),
                        ),
                      ),
                      if (side == 'pariso') const SizedBox(width: 4),
                    ],
                  ],
                ),
              ),
          ],
          if (onGroup != null) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              key: Key('group-btn-${s.id}'),
              onPressed: onGroup,
              icon: const Icon(Icons.groups_outlined, size: 18),
              label: Text(l.assignGroup),
            ),
          ],
        ],
      ),
    );
  }
}

class _SlotChoice {
  const _SlotChoice(this.memberId, {this.force = false});
  final int? memberId;
  final bool force;
}

/// "Affecter un poste" (design): least-solicited first; on leave locked;
/// already busy that day → "Quand même".
class _CandidateSheet extends StatelessWidget {
  const _CandidateSheet({
    required this.service,
    required this.slot,
    this.current,
    required this.scroll,
  });
  final PlannedService service;
  final Slot slot;
  final DutyAssignment? current;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    return AsyncView<List<Candidate>>(
      load: () => RepositoryLocator.instance.planning.candidates(service.id),
      builder: (context, cands, _) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            '${postLabel(l, slot.post)} · ${sideLabel(l, slot.side)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            l.leastSolicitedFirst,
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
          const SizedBox(height: 12),
          if (current != null)
            OutlinedButton.icon(
              key: const Key('clear-slot'),
              onPressed: () =>
                  Navigator.of(context).pop(const _SlotChoice(null)),
              icon: const Icon(Icons.person_remove_outlined),
              label: Text('${l.clearSlot} (${current!.memberName})'),
            ),
          const SizedBox(height: 8),
          GroupCard(
            children: [
              for (final cand in cands)
                Opacity(
                  opacity: cand.flag == 'on_leave' ? 0.55 : 1,
                  child: ListRow(
                    key: Key('cand-${cand.memberId}'),
                    lead: MemberAvatar(
                      name: cand.fullName,
                      size: 36,
                      status: cand.flag == 'on_leave' ? 'conge' : 'actif',
                    ),
                    title: Text(cand.fullName),
                    subtitle: Text(
                      switch (cand.flag) {
                        'busy_same_day' => l.flagBusy,
                        'on_leave' => l.flagLeave,
                        'many_this_month' => l.flagMany,
                        _ => l.servicesThisMonth(cand.servicesThisMonth),
                      },
                      style: TextStyle(
                        color: cand.flag == null ? null : c.warnText,
                        fontWeight: cand.flag == null ? null : FontWeight.w600,
                      ),
                    ),
                    trailing: cand.flag == 'on_leave'
                        ? Icon(
                            Icons.lock_outline,
                            size: 18,
                            color: c.textTertiary,
                          )
                        : FilledButton.tonal(
                            key: Key('assign-${cand.memberId}'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(48, 40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(
                              _SlotChoice(
                                cand.memberId,
                                force: cand.flag == 'busy_same_day',
                              ),
                            ),
                            child: Text(
                              cand.flag == 'busy_same_day'
                                  ? l.assignAnyway
                                  : l.assign,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
