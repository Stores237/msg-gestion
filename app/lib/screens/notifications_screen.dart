import 'package:flutter/material.dart';

import '../data/current_user.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/planning.dart';
import '../theme/tokens.dart';
import '../widgets/dates.dart';
import '../widgets/errors.dart';
import '../widgets/ui.dart';
import 'announcements/announcement_detail_screen.dart';
import 'members/access_requests_screen.dart';
import 'calendar/event_detail_screen.dart';
import 'planning/my_duties_view.dart';
import 'planning/requests_screen.dart';
import 'expenses/expenses_screen.dart';

/// Notifications (design): grouped by day; the green dot goes when opened.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Key _key = UniqueKey();

  Future<void> _readAll() async {
    try {
      await RepositoryLocator.instance.notifications.markRead();
      setState(() => _key = UniqueKey());
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _open(AppNotification n) async {
    RepositoryLocator.instance.notifications
        .markRead(ids: [n.id])
        .catchError((_) {});
    final me = currentUser.value;
    final type = n.target['type'];
    Widget? page;
    if (type == 'event' && me != null) {
      page = EventDetailScreen(eventId: n.target['id'] as int, me: me);
    } else if (type == 'duty') {
      page = Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: AppLocalizations.of(context).myDutiesView,
                back: true,
                small: true,
              ),
              const Expanded(child: MyDutiesView(header: SizedBox())),
            ],
          ),
        ),
      );
    } else if (type == 'request' && me != null) {
      page = RequestsScreen(me: me);
    } else if (type == 'expense') {
      page = ExpenseDetailScreen(expenseId: n.target['id'] as int);
    } else if (type == 'access_request') {
      page = const AccessRequestsScreen();
    } else if (type == 'announcement') {
      // Opens the announcement itself (owner, 2026-10-29).
      try {
        final item = await RepositoryLocator.instance.announcements.get(
          n.target['id'] as int,
        );
        page = AnnouncementDetailScreen(item: item);
      } catch (e) {
        if (mounted) showErrorSnack(context, e);
      }
    }
    if (!mounted) return;
    if (page != null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => page!));
    }
    if (mounted) setState(() => _key = UniqueKey());
  }

  IconData _icon(String kind) => switch (kind) {
    'duty' => Icons.event_available_outlined,
    'announcement' || 'convocation' => Icons.campaign_outlined,
    'payment' => Icons.check_circle_outline,
    'member' => Icons.person_add_alt,
    'request' => Icons.swap_horiz,
    'report' => Icons.assignment_outlined,
    _ => Icons.notifications_outlined,
  };

  Tone _tone(String kind) => switch (kind) {
    'reminder' || 'request' || 'report' => Tone.amber,
    'member' => Tone.neutral,
    _ => Tone.green,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final d = Dates(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: l.notifications,
              back: true,
              small: true,
              actions: [
                TextButton(
                  key: const Key('read-all'),
                  onPressed: _readAll,
                  child: Text(l.markAllRead),
                ),
              ],
            ),
            Expanded(
              child: AsyncView<(int, List<AppNotification>)>(
                key: _key,
                load: RepositoryLocator.instance.notifications.list,
                builder: (context, data, reload) {
                  final items = data.$2;
                  if (items.isEmpty) {
                    return Center(
                      child: EmptyState(
                        icon: Icons.notifications_none,
                        title: l.notificationsEmpty,
                      ),
                    );
                  }
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final groups = <String, List<AppNotification>>{};
                  for (final n in items) {
                    final key = !n.createdAt.isBefore(today)
                        ? l.today
                        : n.createdAt.isAfter(
                            today.subtract(const Duration(days: 7)),
                          )
                        ? l.thisWeek
                        : l.earlier;
                    groups.putIfAbsent(key, () => []).add(n);
                  }
                  return RefreshIndicator(
                    onRefresh: reload,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        for (final e in groups.entries) ...[
                          SectionLabel(e.key),
                          const SizedBox(height: 8),
                          GroupCard(
                            children: [
                              for (final n in e.value)
                                ListRow(
                                  key: Key('notif-${n.id}'),
                                  lead: IconChip(
                                    _icon(n.kind),
                                    tone: _tone(n.kind),
                                  ),
                                  title: Row(
                                    children: [
                                      if (n.unread)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: c.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      Expanded(child: Text(n.title)),
                                    ],
                                  ),
                                  // Tagged: a small mark, not the title.
                                  subtitle:
                                      n.body.isEmpty &&
                                          n.target['for_me'] != true
                                      ? null
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (n.target['for_me'] == true)
                                              ForYouMark(
                                                key: Key(
                                                  'notif-for-me-${n.id}',
                                                ),
                                              ),
                                            if (n.body.isNotEmpty)
                                              Text(
                                                n.body,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                  trailing: Text(
                                    e.key == l.today
                                        ? d.time(n.createdAt)
                                        : d.weekdayShort(n.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: c.textSecondary,
                                    ),
                                  ),
                                  onTap: () => _open(n),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
