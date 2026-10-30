import 'package:flutter/material.dart';

import '../data/current_user.dart';
import '../data/group_controller.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/announcement.dart';
import '../models/event.dart';
import '../models/finance.dart';
import '../data/repositories/profile_repository.dart';
import '../models/planning.dart';
import '../models/me.dart';
import '../theme/tokens.dart';
import '../widgets/dates.dart';
import '../widgets/labels.dart';
import '../widgets/money.dart';
import '../widgets/home_header.dart';
import '../widgets/sync_widgets.dart';
import '../widgets/ui.dart';
import 'account_screen.dart';
import 'expenses/expenses_screen.dart';
import 'finances/finance_gate.dart';
import 'planning/my_duties_view.dart';
import 'announcements/announcement_detail_screen.dart';
import 'calendar/event_detail_screen.dart';
import 'splash_screen.dart';

class _HomeData {
  const _HomeData({
    this.nextEvent,
    this.latest = const [],
    this.unread = 0,
    this.dues,
    this.summary,
    this.nextDuty,
    this.bureau,
  });
  final DutyAssignment? nextDuty;
  final BureauHome? bureau;
  final CalendarEvent? nextEvent;
  final List<Announcement> latest;
  final int unread;
  final MyDues? dues;
  final FinanceSummary? summary;
}

Future<T?> _orNull<T>(Future<T> f) async {
  try {
    return await f;
  } catch (_) {
    return null; // one card failing shouldn't blank the whole home screen
  }
}

/// Accueil (design: "Accueil · membre"): greeting, next meeting, the
/// latest announcements. Contributions and duties arrive with their modules.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.me, this.onOpenTab});

  final Me me;
  final ValueChanged<AppTab>? onOpenTab;

  Future<_HomeData> _load() async {
    final repos = RepositoryLocator.instance;
    final now = DateTime.now();
    final events = me.can('calendar.events', 'view')
        ? repos.events.list(from: now, to: now.add(const Duration(days: 60)))
        : Future.value(const <CalendarEvent>[]);
    final feed = me.can('announcements.posts', 'view')
        ? repos.announcements.feed()
        : Future.value(const AnnouncementFeed(unread: 0, items: []));
    final upcoming = (await events)
        .where((e) => (e.endsAt ?? e.startsAt).isAfter(now))
        .toList();
    final dues = _orNull(repos.finances.mine());
    final duties = _orNull(repos.planning.mine());
    final bureau = _orNull(repos.profile.bureauHome());
    final summary = me.can('finances.cashbook', 'view')
        ? _orNull(repos.finances.summary())
        : Future<FinanceSummary?>.value();
    final f = await feed;
    return _HomeData(
      nextEvent: upcoming.isEmpty ? null : upcoming.first,
      // Pinned ones on top, then the three newest others (owner,
      // 2026-10-29).
      latest: () {
        final newest = [...f.items]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return [
          ...newest.where((a) => a.pinned),
          ...newest.where((a) => !a.pinned).take(3),
        ];
      }(),
      unread: f.unread,
      dues: await dues,
      summary: await summary,
      nextDuty: ((await duties) ?? const []).firstOrNull,
      bureau: await bureau,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final main = me.roles
        .where((r) => r.slug != 'membre')
        .map((r) => roleLabel(l, r.slug, r.name))
        .toList();
    final sub = [
      main.isEmpty ? l.roleGuard : main.first,
      if (me.age != null && me.age! < 18) l.ageYears(me.age!),
    ].join(' · ');
    return Column(
      children: [
        ValueListenableBuilder(
          valueListenable: currentUser,
          builder: (context, cur, _) => HomeHeader(
            firstName: me.firstName,
            fullName: me.fullName,
            photo: (cur ?? me).photo,
            role: sub,
            onOpenAccount: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => AccountScreen(me: me))),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SyncLine(),
        ),
        Expanded(
          child: AsyncView<_HomeData>(
            load: _load,
            builder: (context, data, reload) => RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  if (me.groups.length > 1) ...[
                    _GroupSwitch(me: me),
                    const SizedBox(height: 12),
                  ],
                  if ((me.group?.welcomeMessage ?? '').isNotEmpty) ...[
                    _Welcome(group: me.group!),
                    const SizedBox(height: 24),
                  ],
                  if (data.nextDuty != null) ...[
                    SectionLabel(l.myNextDuty),
                    const SizedBox(height: 8),
                    DutyCard(duty: data.nextDuty!, onChanged: reload),
                    const SizedBox(height: 24),
                  ],
                  if (data.bureau != null && !data.bureau!.isEmpty) ...[
                    _ToFollow(b: data.bureau!, onOpen: onOpenTab),
                    const SizedBox(height: 24),
                  ],
                  // Behind the finance code when the group requires it.
                  if (data.summary != null && FinanceGate.showsFigures(me)) ...[
                    _Stats(
                      summary: data.summary!,
                      onOpen: () => onOpenTab?.call(AppTab.finances),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Expense requests, for every member (owner, 2026-10-30).
                  ExpensesEntryRow(me: me),
                  const SizedBox(height: 24),
                  if (data.dues != null && data.dues!.dues.isNotEmpty) ...[
                    SectionLabel(l.myContributions),
                    const SizedBox(height: 8),
                    GroupCard(
                      children: [
                        for (final d in data.dues!.dues)
                          ListRow(
                            key: Key('due-${d.id}'),
                            title: Text(
                              d.kind == 'amende'
                                  ? '${l.fine} · ${d.label}'
                                  : d.label,
                            ),
                            subtitle: d.paid > 0 && d.remaining > 0
                                ? Text(
                                    l.remainingOf(
                                      fcfa(d.remaining),
                                      fcfa(d.amount),
                                    ),
                                  )
                                : null,
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Amount(
                                  d.remaining > 0 ? d.remaining : d.amount,
                                ),
                                const SizedBox(height: 4),
                                d.remaining > 0
                                    ? Badge2(l.toPayLabel, tone: Tone.amber)
                                    : Badge2(l.paidInFull, tone: Tone.green),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (me.can('calendar.events', 'view')) ...[
                    SectionLabel(
                      l.nextMeeting,
                      action: l.calendarLink,
                      onAction: () => onOpenTab?.call(AppTab.calendrier),
                    ),
                    const SizedBox(height: 8),
                    if (data.nextEvent == null)
                      GroupCard(
                        children: [
                          ListRow(
                            title: Text(
                              l.nothingPlanned,
                              style: TextStyle(color: c.textSecondary),
                            ),
                          ),
                        ],
                      )
                    else
                      EventCard(
                        event: data.nextEvent!,
                        fullDate: true,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EventDetailScreen(
                                eventId: data.nextEvent!.id,
                                me: me,
                              ),
                            ),
                          );
                          reload();
                        },
                      ),
                    const SizedBox(height: 24),
                  ],
                  if (me.can('announcements.posts', 'view')) ...[
                    SectionLabel(
                      l.lastAnnouncement,
                      action: l.allAnnouncements,
                      onAction: () => onOpenTab?.call(AppTab.annonces),
                    ),
                    const SizedBox(height: 8),
                    if (data.latest.isEmpty)
                      GroupCard(
                        children: [
                          ListRow(
                            title: Text(
                              l.noAnnouncements,
                              style: TextStyle(color: c.textSecondary),
                            ),
                          ),
                        ],
                      )
                    else
                      GroupCard(
                        key: const Key('home-latest'),
                        children: [
                          for (final a in data.latest)
                            _AnnouncementRow(
                              item: a,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AnnouncementDetailScreen(item: a),
                                  ),
                                );
                                reload();
                              },
                            ),
                        ],
                      ),
                    if (data.unread > 1) ...[
                      const SizedBox(height: 8),
                      Text(
                        l.unreadCount(data.unread),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: c.textSecondary),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One announcement on Accueil: short, so three fit on the screen.
class _AnnouncementRow extends StatelessWidget {
  const _AnnouncementRow({required this.item, required this.onTap});
  final Announcement item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final d = Dates(context);
    final a = item;
    return ListRow(
      key: Key('home-announcement-${a.id}'),
      lead: IconChip(
        a.isConvocation ? Icons.event_note_outlined : Icons.campaign_outlined,
        tone: a.isConvocation ? Tone.green : Tone.neutral,
      ),
      title: Row(
        children: [
          if (a.unread)
            Container(
              margin: const EdgeInsets.only(right: 6),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: c.primary,
                shape: BoxShape.circle,
              ),
            ),
          Expanded(
            child: Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (a.pinned)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(
                Icons.push_pin_outlined,
                key: Key('home-pinned-${a.id}'),
                size: 16,
                color: c.textSecondary,
                semanticLabel: l.pinned,
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (a.forMe) const ForYouMark(),
          Text(
            [
              a.isConvocation ? l.kindConvocation : l.kindAnnouncement,
              d.dayMonth(a.createdAt),
              ?a.authorName,
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      chevron: true,
      onTap: onTap,
    );
  }
}

/// Bureau view (design: "Accueil · trésorière"): balance and what awaits validation.
class _Stats extends StatelessWidget {
  const _Stats({required this.summary, this.onOpen});
  final FinanceSummary summary;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    return GroupCard(
      padding: EdgeInsets.zero,
      children: [
        InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.cashBalance,
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Amount(
                        summary.balance,
                        size: 20,
                        weight: FontWeight.w800,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${summary.pending}',
                      key: const Key('stat-pending'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l.toValidate,
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "À suivre" (design: "Accueil · trésorière"): open collections, entries
/// awaiting the auditor, unfilled duty posts this week.
class _ToFollow extends StatelessWidget {
  const _ToFollow({required this.b, this.onOpen});
  final BureauHome b;
  final ValueChanged<AppTab>? onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = Dates(context);
    final rows = <Widget>[
      if (b.membersActive != null)
        ListRow(
          key: const Key('follow-members'),
          lead: const IconChip(Icons.people_outline, tone: Tone.neutral),
          title: Text('${b.membersActive} · ${l.activeMembers}'),
          chevron: true,
          onTap: () => onOpen?.call(AppTab.membres),
        ),
      for (final (_, title, paid, members) in b.collections)
        ListRow(
          lead: const IconChip(Icons.volunteer_activism_outlined),
          title: Text(title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.paidFullOf(paid, members)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: members == 0 ? 0 : paid / members,
                  minHeight: 8,
                ),
              ),
            ],
          ),
          chevron: true,
          onTap: () => onOpen?.call(AppTab.finances),
        ),
      if ((b.toValidate ?? 0) > 0)
        ListRow(
          key: const Key('follow-validate'),
          lead: const IconChip(Icons.hourglass_empty, tone: Tone.amber),
          title: Text(l.entriesToValidate(b.toValidate!)),
          subtitle: Text(l.awaitingAuditor),
          chevron: true,
          onTap: () => onOpen?.call(AppTab.finances),
        ),
      if ((b.toConfirm ?? 0) > 0)
        ListRow(
          key: const Key('follow-confirm'),
          lead: const IconChip(Icons.fact_check_outlined, tone: Tone.amber),
          title: Text(l.entriesToConfirm(b.toConfirm!)),
          chevron: true,
          onTap: () => onOpen?.call(AppTab.finances),
        ),
      for (final (title, at, missing) in b.unfilled)
        ListRow(
          lead: const IconChip(Icons.event_busy_outlined, tone: Tone.red),
          title: Text(l.unfilledSlots(missing, title)),
          subtitle: Text(d.fullDateTime(at)),
          chevron: true,
          onTap: () => onOpen?.call(AppTab.calendrier),
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(l.toFollow),
        const SizedBox(height: 8),
        GroupCard(children: rows),
      ],
    );
  }
}

/// The group's welcome message, written by the MSG partner (owner,
/// 2026-10-23).
class _Welcome extends StatelessWidget {
  const _Welcome({required this.group});
  final GroupInfo group;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    return Container(
      key: const Key('welcome-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.primaryTint,
        borderRadius: BorderRadius.circular(MsgRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: c.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            group.welcomeMessage,
            style: const TextStyle(fontSize: 15, height: 1.45),
          ),
        ],
      ),
    );
  }
}

/// One account in several groups: which group the app shows.
class _GroupSwitch extends StatelessWidget {
  const _GroupSwitch({required this.me});
  final Me me;

  Future<void> _choose(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(l.chooseGroup, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final g in me.groups)
              ListTile(
                key: Key('group-${g.id}'),
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  g.id == me.group?.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(g.name),
                onTap: () => Navigator.of(context).pop(g.id),
              ),
          ],
        ),
      ),
    );
    if (picked == null || picked == me.group?.id || !context.mounted) return;
    await GroupController.instance.select(picked);
    if (!context.mounted) return;
    // Start again in the chosen group: its roles, tabs and data.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    return Material(
      color: c.surfaceCard,
      borderRadius: BorderRadius.circular(MsgRadius.md),
      child: InkWell(
        key: const Key('switch-group'),
        borderRadius: BorderRadius.circular(MsgRadius.md),
        onTap: () => _choose(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.groups_outlined, color: c.primaryText),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  me.group?.name ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.swap_horiz,
                color: c.primaryText,
                semanticLabel: l.switchGroup,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
