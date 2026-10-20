import 'package:flutter/material.dart';

import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/me.dart';
import '../../models/planning.dart';
import '../../theme/tokens.dart';
import '../../widgets/dates.dart';
import '../../widgets/errors.dart';
import '../../widgets/ui.dart';

/// "Lavage des aubes · rotation" (design): 3-step status, next weeks,
/// 12-month fairness.
class AlbsScreen extends StatefulWidget {
  const AlbsScreen({super.key, required this.me});
  final Me me;

  @override
  State<AlbsScreen> createState() => _AlbsScreenState();
}

class _AlbsScreenState extends State<AlbsScreen> {
  Key _key = UniqueKey();

  Future<void> _advance(AlbWeek w) async {
    try {
      await RepositoryLocator.instance.planning.advanceAlbs(w.id);
      setState(() => _key = UniqueKey());
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _schedule() async {
    final l = AppLocalizations.of(context);
    final repo = RepositoryLocator.instance.planning;
    final groups = await repo.groups().catchError((Object e) {
      if (mounted) showErrorSnack(context, e);
      return <ServiceGroupInfo>[];
    });
    if (!mounted) return;
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final week = await showDatePicker(
      context: context,
      initialDate: monday.add(const Duration(days: 7)),
      firstDate: monday,
      lastDate: monday.add(const Duration(days: 365)),
    );
    if (week == null || !mounted) return;
    final g = await showModalBottomSheet<ServiceGroupInfo>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(l.group, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GroupCard(
            children: [
              for (final g in groups)
                ListRow(
                  key: Key('alb-group-${g.id}'),
                  title: Text(g.name),
                  onTap: () => Navigator.of(context).pop(g),
                ),
            ],
          ),
        ],
      ),
    );
    try {
      await repo.scheduleAlbs(week, groupId: g?.id);
      setState(() => _key = UniqueKey());
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final d = Dates(context);
    final canPlan = widget.me.can('calendar.planning', 'change');
    final steps = [
      ('a_laver', l.albToWash),
      ('lavees', l.albWashed),
      ('rendues', l.albReturned),
    ];
    return Scaffold(
      floatingActionButton: canPlan
          ? FloatingActionButton.extended(
              key: const Key('schedule-albs'),
              onPressed: _schedule,
              icon: const Icon(Icons.add),
              label: Text(l.scheduleAlbs),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.albs, back: true, small: true),
            Expanded(
              child: AsyncView<AlbOverview>(
                key: _key,
                load: RepositoryLocator.instance.planning.albs,
                builder: (context, data, reload) {
                  final now = DateTime.now();
                  final current = data.weeks
                      .where((w) => !w.weekStart.isAfter(now))
                      .toList();
                  final cur = current.isEmpty ? null : current.last;
                  final upcoming = data.weeks
                      .where((w) => w.weekStart.isAfter(now))
                      .toList();
                  final maxCount = data.fairness.fold<int>(
                    1,
                    (m, f) => f.$2 > m ? f.$2 : m,
                  );
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      if (cur == null)
                        EmptyState(
                          icon: Icons.checkroom_outlined,
                          title: l.noAlbs,
                        )
                      else
                        GroupCard(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  l
                                      .albsWeek(d.dayMonth(cur.weekStart))
                                      .toUpperCase(),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cur.group ?? cur.responsible ?? '—',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  [
                                    if (cur.responsible != null)
                                      l.responsible(cur.responsible!),
                                    l.albsCount(cur.albs),
                                  ].join(' · '),
                                  style: TextStyle(color: c.textSecondary),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    for (final (i, (key, label))
                                        in steps.indexed)
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            right: i < 2 ? 4 : 0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color:
                                                      steps.indexWhere(
                                                            (s) =>
                                                                s.$1 ==
                                                                cur.status,
                                                          ) >=
                                                          i
                                                      ? c.primary
                                                      : c.surfaceSunken,
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                label,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: cur.status == key
                                                      ? c.textPrimary
                                                      : c.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (cur.canAdvance &&
                                    cur.status != 'rendues') ...[
                                  const SizedBox(height: 12),
                                  FilledButton.tonal(
                                    key: const Key('alb-advance'),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      shape: const StadiumBorder(),
                                    ),
                                    onPressed: () => _advance(cur),
                                    child: Text(
                                      cur.status == 'a_laver'
                                          ? l.markWashed
                                          : l.markReturned,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      if (upcoming.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        SectionLabel(l.nextWeeks),
                        const SizedBox(height: 8),
                        GroupCard(
                          children: [
                            for (final w in upcoming)
                              ListRow(
                                title: Text(
                                  l.albsWeek(d.dayMonth(w.weekStart)),
                                ),
                                subtitle: Text(w.group ?? w.responsible ?? '—'),
                                trailing: Badge2(l.planned),
                              ),
                          ],
                        ),
                      ],
                      if (data.fairness.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        SectionLabel(l.fairness12),
                        const SizedBox(height: 8),
                        GroupCard(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Column(
                              children: [
                                for (final (name, n) in data.fairness)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 110,
                                          child: Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: n / maxCount,
                                              minHeight: 8,
                                              color: n < 2
                                                  ? c.borderStrong
                                                  : c.primary,
                                              backgroundColor: c.surfaceSunken,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: 24,
                                          child: Text(
                                            '$n',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
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
