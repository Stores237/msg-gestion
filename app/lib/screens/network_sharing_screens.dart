import 'package:flutter/material.dart';

import '../data/repositories/profile_repository.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/announcement.dart';
import '../theme/tokens.dart';
import '../widgets/attachments.dart';
import '../widgets/dates.dart';
import '../widgets/errors.dart';
import '../widgets/group_logo.dart';
import '../widgets/money.dart';
import '../widgets/ui.dart';

String sharingKindLabel(AppLocalizations l, String kind) => switch (kind) {
  'members' => l.groupNetKindMembers,
  'finances' => l.groupNetKindFinances,
  'calendar' => l.groupNetKindCalendar,
  'announcements' => l.groupNetKindAnnouncements,
  'reports' => l.groupNetKindReports,
  _ => kind,
};

String sharingLevelLabel(AppLocalizations l, String level) => switch (level) {
  'summary' => l.groupNetLevelSummary,
  'detail' => l.groupNetLevelDetail,
  _ => l.groupNetLevelNone,
};

IconData sharingKindIcon(String kind) => switch (kind) {
  'members' => Icons.groups_outlined,
  'finances' => Icons.account_balance_wallet_outlined,
  'calendar' => Icons.event_outlined,
  'announcements' => Icons.campaign_outlined,
  'reports' => Icons.fact_check_outlined,
  _ => Icons.visibility_outlined,
};

/// Exactly what a level shows (owner, 2026-11-04: "the details on what to
/// share" were too vague). Each level adds to the one before.
String sharingIncludes(AppLocalizations l, String kind, String level) =>
    switch ((kind, level)) {
      ('members', 'summary') => l.shareIncMembersSummary,
      ('members', 'detail') => l.shareIncMembersDetail,
      ('finances', 'summary') => l.shareIncFinancesSummary,
      ('finances', 'detail') => l.shareIncFinancesDetail,
      ('calendar', 'summary') => l.shareIncCalendarSummary,
      ('calendar', 'detail') => l.shareIncCalendarDetail,
      ('announcements', 'summary') => l.shareIncAnnouncementsSummary,
      ('announcements', 'detail') => l.shareIncAnnouncementsDetail,
      ('reports', 'summary') => l.shareIncReportsSummary,
      ('reports', 'detail') => l.shareIncReportsDetail,
      _ => l.shareIncNone,
    };

/// Who reads it in the other group.
String sharingReader(AppLocalizations l, String kind) => switch (kind) {
  'members' => l.shareReaderMembers,
  'finances' => l.shareReaderFinances,
  'calendar' => l.shareReaderCalendar,
  'announcements' => l.shareReaderAnnouncements,
  _ => l.shareReaderReports,
};

String sharingAudience(AppLocalizations l, String audience) =>
    switch (audience) {
      'neighbours' => l.shareAudienceNeighbours,
      'twins' => l.shareAudienceTwins,
      _ => l.shareAudienceUp,
    };

/// "Ce que nous partageons" (owner, 2026-11-03; detailed in build 48): kind
/// by kind, what the chosen audience may see, each level spelled out, with a
/// preview before saving. Nothing until the président chooses; others read.
class SharingScreen extends StatefulWidget {
  const SharingScreen({super.key, this.audience = 'up'});

  /// up | neighbours | twins (build 43).
  final String audience;

  @override
  State<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  SharingSettings? _s;
  Map<String, String> _values = {};
  int _waiting = 0;
  Object? _error;
  bool _busy = false;

  ProfileRepository get _repo => RepositoryLocator.instance.profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await _repo.sharing(audience: widget.audience);
      var waiting = 0;
      if (s.canManage) {
        try {
          final r = await _repo.shareRequests();
          waiting = r.incoming
              .where((x) => x.pending && x.audience == widget.audience)
              .length;
        } catch (_) {
          // The list of requests is a convenience here.
        }
      }
      if (!mounted) return;
      setState(() {
        _s = s;
        _values = {...s.values};
        _waiting = waiting;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  bool get _changed =>
      _s != null &&
      SharingSettings.kinds.any(
        (k) => (_values[k] ?? 'none') != (_s!.values[k] ?? 'none'),
      );

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await _repo.saveSharing(_values, audience: widget.audience);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.groupNetSharingSaved)));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _preview() async {
    final l = AppLocalizations.of(context);
    final values = {..._values};
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, scroll) => AsyncView<Map<String, SharedKind>>(
          load: () => _repo.previewSharing(values),
          builder: (context, shown, _) => ListView(
            key: const Key('sharing-preview'),
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              Text(
                l.sharingPreviewTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                l.sharingPreviewHint(sharingAudience(l, widget.audience)),
                style: TextStyle(color: context.msg.textSecondary),
              ),
              const SizedBox(height: 16),
              if (shown.isEmpty)
                EmptyState(
                  icon: Icons.visibility_off_outlined,
                  title: l.sharingPreviewEmpty,
                )
              else
                for (final kind in SharingSettings.kinds)
                  if (shown[kind] case final k?) ...[
                    SectionLabel(
                      '${sharingKindLabel(l, kind)} · ${sharingLevelLabel(l, k.level)}',
                    ),
                    const SizedBox(height: 8),
                    k.hidden || k.data == null
                        ? Text(
                            l.sharingPreviewHidden,
                            style: TextStyle(color: context.msg.textSecondary),
                          )
                        : SharedKindView(kind: kind, data: k.data!),
                    const SizedBox(height: 20),
                  ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openRequests() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ShareRequestsScreen()));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final s = _s;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: switch (widget.audience) {
                'neighbours' => l.groupNetSharingNeighbours,
                'twins' => l.groupNetSharingTwins,
                _ => l.groupNetSharingTitle,
              },
              back: true,
              small: true,
              actions: [
                if (s != null)
                  TextButton.icon(
                    key: const Key('sharing-preview-open'),
                    onPressed: _preview,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: Text(l.sharingPreview),
                  ),
              ],
            ),
            Expanded(
              child: s == null
                  ? Center(
                      child: _error == null
                          ? const CircularProgressIndicator()
                          : Text(describeError(context, _error!)),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        Text(
                          l.sharingAboutAudience(
                            sharingAudience(l, widget.audience),
                          ),
                          style: TextStyle(height: 1.5, color: c.textSecondary),
                        ),
                        if (_waiting > 0) ...[
                          const SizedBox(height: 12),
                          GroupCard(
                            children: [
                              ListRow(
                                key: const Key('sharing-requests'),
                                lead: const IconChip(
                                  Icons.mark_email_unread_outlined,
                                  tone: Tone.amber,
                                ),
                                title: Text(l.sharingWaiting(_waiting)),
                                chevron: true,
                                onTap: _openRequests,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        for (final kind in SharingSettings.kinds)
                          if (s.options[kind] case final options?) ...[
                            _KindChoice(
                              key: Key('share-$kind'),
                              kind: kind,
                              options: options,
                              value: _values[kind] ?? 'none',
                              saved: s.values[kind] ?? 'none',
                              enabled: s.canManage && !_busy,
                              onChanged: (v) =>
                                  setState(() => _values[kind] = v),
                            ),
                            const SizedBox(height: 16),
                          ],
                        GroupCard(
                          children: [
                            ListRow(
                              lead: const IconChip(
                                Icons.lock_outline,
                                tone: Tone.neutral,
                              ),
                              title: Text(l.sharingAlwaysPrivate),
                              subtitle: Text(l.groupNetNeverShared),
                            ),
                          ],
                        ),
                        if (s.canManage) ...[
                          const SizedBox(height: 16),
                          FilledButton(
                            key: const Key('sharing-save'),
                            onPressed: _busy || !_changed ? null : _save,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: const StadiumBorder(),
                            ),
                            child: Text(l.save),
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          Text(
                            l.sharingOnlyPresident,
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

/// One kind: its levels as cards that say exactly what each shows.
class _KindChoice extends StatelessWidget {
  const _KindChoice({
    super.key,
    required this.kind,
    required this.options,
    required this.value,
    required this.saved,
    required this.enabled,
    required this.onChanged,
  });
  final String kind;
  final List<String> options;
  final String value;
  final String saved;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    return GroupCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconChip(
                  sharingKindIcon(kind),
                  tone: value == 'none' ? Tone.neutral : Tone.green,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sharingKindLabel(l, kind),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (value != saved) Badge2(l.sharingChanged, tone: Tone.amber),
              ],
            ),
            const SizedBox(height: 12),
            for (final o in options) ...[
              _LevelTile(
                key: Key('share-$kind-$o'),
                title: sharingLevelLabel(l, o),
                text: o == 'none'
                    ? l.shareIncNone
                    : (o == 'detail' && options.contains('summary')
                          ? '${sharingIncludes(l, kind, 'summary')} ${sharingIncludes(l, kind, o)}'
                          : sharingIncludes(l, kind, o)),
                selected: value == o,
                onTap: enabled ? () => onChanged(o) : null,
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(Icons.badge_outlined, size: 16, color: c.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sharingReader(l, kind),
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    super.key,
    required this.title,
    required this.text,
    required this.selected,
    this.onTap,
  });
  final String title;
  final String text;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    return Semantics(
      selected: selected,
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: selected ? c.primaryTint : c.surfaceSunken,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? c.primaryText : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 20,
                color: selected ? c.primaryText : c.textTertiary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? c.primaryText : c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A linked group, as it shares itself (owner, 2026-11-03; build 48: "a real
/// interface with filters that shows what is visible, what is not, how to
/// request visibility"). Kinds the viewer's role doesn't cover say so; kinds
/// not shared can be asked for.
class SharedGroupScreen extends StatefulWidget {
  const SharedGroupScreen({super.key, required this.groupId});
  final int groupId;

  @override
  State<SharedGroupScreen> createState() => _SharedGroupScreenState();
}

class _SharedGroupScreenState extends State<SharedGroupScreen> {
  SharedGroup? _g;
  Object? _error;
  int _filter = 0; // 0 all, 1 visible, 2 reserved, 3 not shared
  bool _busy = false;

  ProfileRepository get _repo => RepositoryLocator.instance.profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final g = await _repo.sharedGroup(widget.groupId);
      if (mounted) {
        setState(() {
          _g = g;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  /// The server's list (build 48), or one made from what is shared.
  List<KindStatus> _kinds(SharedGroup g) => g.kinds.isNotEmpty
      ? g.kinds
      : [
          for (final k in SharingSettings.kinds)
            if (g.shared[k] case final s?)
              KindStatus(
                kind: k,
                level: s.level,
                state: s.hidden || s.data == null ? 'hidden' : 'shared',
                data: s.data,
              )
            else
              KindStatus(kind: k),
        ];

  static const _states = [null, 'shared', 'hidden', 'none'];

  Future<void> _ask(SharedGroup g, KindStatus k) async {
    final l = AppLocalizations.of(context);
    final res = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AskSheet(group: g, kind: k),
    );
    if (res == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repo.askShare(
        g.group.id,
        kind: k.kind,
        level: res.$1,
        note: res.$2,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.sgAsked)));
      await _load();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(ShareRequestInfo r) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await _repo.cancelShareRequest(r.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.sgRequestCancelled)));
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
    final g = _g;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.groupNetTitle, back: true, small: true),
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: g == null
                  ? Center(
                      child: _error == null
                          ? const CircularProgressIndicator()
                          : EmptyState(
                              icon: Icons.cloud_off_outlined,
                              title: describeError(context, _error!),
                              error: true,
                              action: TextButton(
                                onPressed: _load,
                                child: Text(l.retry),
                              ),
                            ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _body(context, l, c, g),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l,
    MsgColors c,
    SharedGroup g,
  ) {
    final kinds = _kinds(g);
    int n(String s) => kinds.where((k) => k.state == s).length;
    final shown = [
      for (final k in kinds)
        if (_states[_filter] == null || k.state == _states[_filter]) k,
    ];
    Widget stat(int i, String label, int value, Tone tone) => Expanded(
      child: InkWell(
        key: Key('sg-stat-$i'),
        borderRadius: BorderRadius.circular(MsgRadius.lg),
        onTap: () => setState(() => _filter = _filter == i ? 0 : i),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: _filter == i ? c.primaryTint : c.surfaceCard,
            borderRadius: BorderRadius.circular(MsgRadius.lg),
            border: Border.all(color: c.borderSubtle),
          ),
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: switch (tone) {
                    Tone.green => c.primaryText,
                    Tone.amber => c.warnText,
                    _ => c.textSecondary,
                  },
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
    return ListView(
      key: const Key('shared-group'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        GroupCard(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                GroupLogo(group: g.group, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.group.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          g.levelName,
                          ?g.parent,
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: TextStyle(color: c.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Badge2(switch (g.relation) {
                        'neighbours' => l.sgRelationNeighbours,
                        'twins' => l.sgRelationTwins,
                        _ => l.sgRelationUp,
                      }, tone: Tone.green),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            stat(1, l.sgVisible, n('shared'), Tone.green),
            const SizedBox(width: 8),
            stat(2, l.sgReserved, n('hidden'), Tone.amber),
            const SizedBox(width: 8),
            stat(3, l.sgNotShared, n('none'), Tone.neutral),
          ],
        ),
        const SizedBox(height: 16),
        FilterChips(
          labels: [
            l.sgFilterAll,
            l.sgFilterVisible,
            l.sgFilterReserved,
            l.sgFilterNotShared,
          ],
          selected: _filter,
          onSelected: (i) => setState(() => _filter = i),
        ),
        const SizedBox(height: 16),
        if (kinds.every((k) => k.state == 'none') && _filter == 0) ...[
          EmptyState(
            icon: Icons.visibility_off_outlined,
            title: l.groupNetSharesNothing,
            text: l.sgNothingAskHint,
          ),
          const SizedBox(height: 8),
        ],
        if (shown.isEmpty)
          EmptyState(
            icon: Icons.filter_alt_off_outlined,
            title: l.sgNothingInFilter,
          )
        else
          for (final k in shown) ...[
            _KindCard(
              key: Key('sg-kind-${k.kind}'),
              group: g,
              status: k,
              busy: _busy,
              onAsk: () => _ask(g, k),
              onCancel: k.request == null ? null : () => _cancel(k.request!),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _KindCard extends StatelessWidget {
  const _KindCard({
    super.key,
    required this.group,
    required this.status,
    required this.busy,
    required this.onAsk,
    this.onCancel,
  });
  final SharedGroup group;
  final KindStatus status;
  final bool busy;
  final VoidCallback onAsk;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final d = Dates(context);
    final k = status;
    final (badge, tone) = switch (k.state) {
      'shared' => (sharingLevelLabel(l, k.level), Tone.green),
      'hidden' => (l.sgFilterReserved, Tone.amber),
      _ => (l.sgFilterNotShared, Tone.neutral),
    };
    final pending = k.request;
    final declined = k.lastAnswer?.status == 'declined' ? k.lastAnswer : null;
    return GroupCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconChip(sharingKindIcon(k.kind), tone: tone, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sharingKindLabel(l, k.kind),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                Badge2(badge, tone: tone),
              ],
            ),
            const SizedBox(height: 10),
            KeyedSubtree(
              key: Key('shared-${k.kind}'),
              child: switch (k.state) {
                'shared' when k.data != null => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sharingIncludes(l, k.kind, k.level),
                      style: TextStyle(fontSize: 13, color: c.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    SharedKindView(kind: k.kind, data: k.data!),
                  ],
                ),
                'hidden' => Text(
                  '${l.groupNetNotYourRole} ${sharingReader(l, k.kind)}',
                  style: TextStyle(color: c.textSecondary, height: 1.4),
                ),
                _ => Text(
                  l.sgNoneBody,
                  style: TextStyle(color: c.textSecondary, height: 1.4),
                ),
              },
            ),
            if (pending != null) ...[
              const SizedBox(height: 12),
              Container(
                key: Key('sg-pending-${k.kind}'),
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                decoration: BoxDecoration(
                  color: c.warnTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 18, color: c.warnText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.sgPending(
                          sharingLevelLabel(l, pending.level).toLowerCase(),
                          d.shortDate(pending.createdAt),
                        ),
                        style: TextStyle(fontSize: 13, color: c.warnText),
                      ),
                    ),
                    TextButton(
                      key: Key('sg-cancel-${k.kind}'),
                      onPressed: busy ? null : onCancel,
                      child: Text(l.sgCancelRequest),
                    ),
                  ],
                ),
              ),
            ] else if (declined != null && k.canRequest) ...[
              const SizedBox(height: 10),
              Text(
                [
                  l.sgDeclined(
                    d.shortDate(declined.answeredAt ?? declined.createdAt),
                  ),
                  if (declined.answerNote.isNotEmpty)
                    '« ${declined.answerNote} »',
                ].join(' '),
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
            ],
            if (k.canRequest && pending == null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: Key('sg-ask-${k.kind}'),
                onPressed: busy ? null : onAsk,
                icon: const Icon(Icons.lock_open_outlined, size: 18),
                label: Text(
                  k.nextLevel == 'detail' && k.state == 'shared'
                      ? l.sgAskDetail
                      : l.sgAskAccess,
                ),
                style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Which level to ask for, and a word for the président.
class _AskSheet extends StatefulWidget {
  const _AskSheet({required this.group, required this.kind});
  final SharedGroup group;
  final KindStatus kind;

  @override
  State<_AskSheet> createState() => _AskSheetState();
}

class _AskSheetState extends State<_AskSheet> {
  final _note = TextEditingController();
  late String _level = widget.kind.nextLevel ?? 'summary';

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  List<String> get _above {
    const rank = {'none': 0, 'summary': 1, 'detail': 2};
    final levels = widget.kind.levels.isEmpty
        ? const ['summary', 'detail']
        : widget.kind.levels;
    return [
      for (final lv in levels)
        if (rank[lv]! > rank[widget.kind.level]!) lv,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final k = widget.kind;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.sgAskTitle(sharingKindLabel(l, k.kind)),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              l.sgAskBody(
                widget.group.group.name,
                sharingAudience(l, widget.group.relation),
              ),
              style: TextStyle(height: 1.5, color: c.textSecondary),
            ),
            const SizedBox(height: 16),
            for (final lv in _above) ...[
              _LevelTile(
                key: Key('ask-level-$lv'),
                title: sharingLevelLabel(l, lv),
                text: sharingIncludes(l, k.kind, lv),
                selected: _level == lv,
                onTap: () => setState(() => _level = lv),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            TextField(
              key: const Key('ask-note'),
              controller: _note,
              maxLength: 300,
              maxLines: 2,
              decoration: InputDecoration(labelText: l.sgAskNote),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('ask-send'),
              onPressed: () =>
                  Navigator.of(context).pop((_level, _note.text.trim())),
              icon: const Icon(Icons.send_outlined, size: 18),
              label: Text(l.sgAskSend),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Demandes de partage" (build 48): what other groups ask this one to
/// share — the président accepts or declines — and what this group asked.
class ShareRequestsScreen extends StatefulWidget {
  const ShareRequestsScreen({super.key});

  @override
  State<ShareRequestsScreen> createState() => _ShareRequestsScreenState();
}

class _ShareRequestsScreenState extends State<ShareRequestsScreen> {
  ShareRequests? _r;
  Object? _error;
  int _tab = 0;
  bool _busy = false;

  ProfileRepository get _repo => RepositoryLocator.instance.profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await _repo.shareRequests();
      if (mounted) {
        setState(() {
          _r = r;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
      await _load();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _what(AppLocalizations l, ShareRequestInfo r) =>
      '${sharingKindLabel(l, r.kind)} · ${sharingLevelLabel(l, r.level).toLowerCase()}';

  Future<void> _accept(ShareRequestInfo r) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.srAcceptTitle),
        content: Text(
          '${sharingIncludes(l, r.kind, r.level)}\n\n${l.srAcceptBody(_what(l, r), sharingAudience(l, r.audience))}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('sr-accept-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.srAccept),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _run(
        () => _repo.answerShareRequest(r.id, accept: true),
        l.srAccepted,
      );
    }
  }

  Future<void> _decline(ShareRequestInfo r) async {
    final l = AppLocalizations.of(context);
    final res = await showDialog<String>(
      context: context,
      builder: (_) => const _DeclineDialog(),
    );
    if (res != null) {
      await _run(
        () => _repo.answerShareRequest(r.id, accept: false, note: res),
        l.srDeclined,
      );
    }
  }

  Widget _status(AppLocalizations l, ShareRequestInfo r) => switch (r.status) {
    'accepted' => Badge2(l.srStatusAccepted, tone: Tone.green),
    'declined' => Badge2(l.srStatusDeclined, tone: Tone.red),
    'cancelled' => Badge2(l.srStatusCancelled),
    _ => Badge2(l.srStatusPending, tone: Tone.amber),
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final d = Dates(context);
    final r = _r;
    Widget card(ShareRequestInfo x, {required bool incoming}) {
      final other = incoming ? x.fromGroup : x.target;
      return GroupCard(
        key: Key('sr-${x.id}'),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GroupLogo(group: other, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          other.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          l.srBy(
                            x.by.isEmpty ? '—' : x.by,
                            d.shortDate(x.createdAt),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _status(l, x),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(sharingKindIcon(x.kind), size: 18, color: c.primaryText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _what(l, x),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                sharingIncludes(l, x.kind, x.level),
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
              if (x.note.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '« ${x.note} »',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
              if (x.answerNote.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  l.srAnswerNote(x.answerNote),
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                ),
              ],
              if (incoming && x.pending && x.current != null) ...[
                const SizedBox(height: 6),
                Text(
                  l.srCurrently(sharingLevelLabel(l, x.current!).toLowerCase()),
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
              ],
              if (x.pending) ...[
                const SizedBox(height: 12),
                if (incoming && r!.canAnswer)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: Key('sr-decline-${x.id}'),
                          onPressed: _busy ? null : () => _decline(x),
                          child: Text(l.srDecline),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          key: Key('sr-accept-${x.id}'),
                          onPressed: _busy ? null : () => _accept(x),
                          child: Text(l.srAccept),
                        ),
                      ),
                    ],
                  )
                else if (incoming)
                  Text(
                    l.srOnlyPresident,
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: Key('sr-cancel-${x.id}'),
                      onPressed: _busy
                          ? null
                          : () => _run(
                              () => _repo.cancelShareRequest(x.id),
                              l.sgRequestCancelled,
                            ),
                      child: Text(l.sgCancelRequest),
                    ),
                  ),
              ],
            ],
          ),
        ],
      );
    }

    List<Widget> section(
      List<ShareRequestInfo> rows, {
      required bool incoming,
    }) {
      final waiting = rows.where((x) => x.pending).toList();
      final done = rows.where((x) => !x.pending).toList();
      if (rows.isEmpty) {
        return [
          EmptyState(
            icon: Icons.mark_email_read_outlined,
            title: incoming ? l.srNoneReceived : l.srNoneSent,
            text: incoming ? l.srNoneReceivedHint : l.srNoneSentHint,
          ),
        ];
      }
      return [
        if (waiting.isNotEmpty) ...[
          SectionLabel(l.srWaiting),
          const SizedBox(height: 8),
          for (final x in waiting) ...[
            card(x, incoming: incoming),
            const SizedBox(height: 12),
          ],
        ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel(l.srHistory),
          const SizedBox(height: 8),
          for (final x in done) ...[
            card(x, incoming: incoming),
            const SizedBox(height: 12),
          ],
        ],
      ];
    }

    final waitingIn = r?.incoming.where((x) => x.pending).length ?? 0;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.srTitle, back: true, small: true),
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: r == null
                  ? Center(
                      child: _error == null
                          ? const CircularProgressIndicator()
                          : Text(describeError(context, _error!)),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        key: const Key('share-requests'),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        children: [
                          Seg2(
                            options: [
                              waitingIn > 0
                                  ? '${l.srReceived} ($waitingIn)'
                                  : l.srReceived,
                              l.srSent,
                            ],
                            selected: _tab,
                            onChanged: (i) => setState(() => _tab = i),
                          ),
                          const SizedBox(height: 16),
                          ...section(
                            _tab == 0 ? r.incoming : r.outgoing,
                            incoming: _tab == 0,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The reason for declining; owns its text field (freed once closed).
class _DeclineDialog extends StatefulWidget {
  const _DeclineDialog();

  @override
  State<_DeclineDialog> createState() => _DeclineDialogState();
}

class _DeclineDialogState extends State<_DeclineDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.srDeclineTitle),
      content: TextField(
        key: const Key('sr-decline-note'),
        controller: _note,
        maxLength: 300,
        decoration: InputDecoration(labelText: l.srDeclineNote),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('sr-decline-confirm'),
          onPressed: () => Navigator.of(context).pop(_note.text.trim()),
          child: Text(l.srDecline),
        ),
      ],
    );
  }
}

/// What a group shares of one kind (members, finances…), as data.
class SharedKindView extends StatelessWidget {
  const SharedKindView({super.key, required this.kind, required this.data});
  final String kind;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = Dates(context);
    final c = context.msg;
    Widget line(String a, String b) => ListRow(
      title: Text(a),
      trailing: Text(b, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
    String money(int n) =>
        '${n < 0 ? '− ' : ''}${groupDigits(n)} ${data['currency'] ?? Currency.code}';
    DateTime when(String s) => DateTime.parse(s).toLocal();
    switch (kind) {
      case 'members':
        final people = (data['people'] as List?) ?? const [];
        return GroupCard(
          children: [
            line(l.groupNetMembersActive, '${data['total']}'),
            for (final p in people)
              ListRow(
                title: Text(p['name'] as String),
                subtitle: (p['roles'] as List).isEmpty
                    ? null
                    : Text((p['roles'] as List).join(', ')),
              ),
          ],
        );
      case 'finances':
        final entries = (data['entries'] as List?) ?? const [];
        return GroupCard(
          children: [
            line(l.groupNetBalance, money(data['balance'] as int)),
            line(l.groupNetYearIn, money(data['year_in'] as int)),
            line(l.groupNetYearOut, money(data['year_out'] as int)),
            for (final e in entries)
              ListRow(
                title: Text(e['label'] as String),
                subtitle: Text(
                  '${d.shortDate(DateTime.parse(e['date'] as String))} · ${e['category']}',
                ),
                trailing: Text(
                  '${e['direction'] == 'out' ? '− ' : '+ '}${money(e['amount'] as int)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: e['direction'] == 'out' ? c.alert : null,
                  ),
                ),
              ),
          ],
        );
      case 'calendar':
        final events = (data['events'] as List?) ?? const [];
        return GroupCard(
          children: [
            line(l.groupNetUpcoming, '${data['upcoming']}'),
            for (final e in events)
              ListRow(
                title: Text(e['title'] as String),
                subtitle: Text(
                  [
                    d.fullDateTime(when(e['starts_at'] as String)),
                    e['place'] as String,
                  ].where((s) => s.isNotEmpty).join(' · '),
                ),
              ),
          ],
        );
      case 'announcements':
        final items = (data['items'] as List?) ?? const [];
        if (items.isEmpty) return Text(l.groupNetNoneYet);
        return GroupCard(
          children: [
            for (final a in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${d.shortDate(when(a['created_at'] as String))} · ${a['body']}',
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: c.textSecondary),
                    ),
                    if ((a['attachments'] as List?)?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 8),
                      AttachmentList(
                        items: [
                          for (final f in a['attachments'] as List)
                            AttachmentInfo.fromJson(f as Map<String, dynamic>),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      case 'reports':
        final rows = (data['rows'] as List?) ?? const [];
        final rate = data['presence_rate'] as int?;
        return GroupCard(
          children: [
            line(l.groupNetEvents90, '${data['events']}'),
            line(l.groupNetPresenceRate, rate == null ? '—' : '$rate %'),
            for (final r in rows)
              ListRow(
                title: Text(r['title'] as String),
                subtitle: Text(
                  '${d.shortDate(when(r['date'] as String))} · ${l.groupNetAttendance(r['present'] as int, r['absent'] as int, r['excused'] as int)}',
                ),
                trailing: r['report'] == true
                    ? Badge2(l.groupNetReportIn, tone: Tone.green)
                    : null,
              ),
          ],
        );
    }
    return const SizedBox.shrink();
  }
}
