import 'package:flutter/material.dart';

import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/announcement.dart';
import '../models/event.dart';
import '../models/finance.dart';
import '../models/planning.dart';
import '../models/me.dart';
import '../theme/tokens.dart';
import '../widgets/labels.dart';
import '../widgets/money.dart';
import '../widgets/msg_logo.dart';
import '../widgets/notification_bell.dart';
import '../widgets/ui.dart';
import 'account_screen.dart';
import 'planning/my_duties_view.dart';
import 'announcements/announcement_detail_screen.dart';
import 'calendar/event_detail_screen.dart';

class _HomeData {
  const _HomeData({
    this.nextEvent,
    this.lastAnnouncement,
    this.unread = 0,
    this.dues,
    this.summary,
    this.nextDuty,
  });
  final DutyAssignment? nextDuty;
  final CalendarEvent? nextEvent;
  final Announcement? lastAnnouncement;
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

/// Accueil (design: "Accueil · membre"): greeting, next meeting, latest
/// announcement. Contributions and duties arrive with their modules.
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
    final summary = me.can('finances.cashbook', 'view')
        ? _orNull(repos.finances.summary())
        : Future<FinanceSummary?>.value();
    final f = await feed;
    return _HomeData(
      nextEvent: upcoming.isEmpty ? null : upcoming.first,
      lastAnnouncement: f.items.isEmpty ? null : f.items.first,
      unread: f.unread,
      dues: await dues,
      summary: await summary,
      nextDuty: ((await duties) ?? const []).firstOrNull,
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
        ScreenHeader(
          title: l.helloName(me.firstName),
          sync: true,
          subtitle: sub,
          leading: const MsgLogo(size: 40),
          actions: [
            const NotificationBell(),
            Semantics(
              button: true,
              label: l.openAccount,
              child: InkWell(
                key: const Key('open-account'),
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AccountScreen(me: me)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: MemberAvatar(name: me.fullName, size: 40),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        Expanded(
          child: AsyncView<_HomeData>(
            load: _load,
            builder: (context, data, reload) => RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  if (data.nextDuty != null) ...[
                    SectionLabel(l.myNextDuty),
                    const SizedBox(height: 8),
                    DutyCard(duty: data.nextDuty!, onChanged: reload),
                    const SizedBox(height: 24),
                  ],
                  if (data.summary != null) ...[
                    _Stats(
                      summary: data.summary!,
                      onOpen: () => onOpenTab?.call(AppTab.finances),
                    ),
                    const SizedBox(height: 24),
                  ],
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
                    if (data.lastAnnouncement == null)
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
                      AnnouncementCard(
                        item: data.lastAnnouncement!,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AnnouncementDetailScreen(
                                item: data.lastAnnouncement!,
                              ),
                            ),
                          );
                          reload();
                        },
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
