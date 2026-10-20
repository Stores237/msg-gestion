import 'package:flutter/material.dart';

import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/me.dart';
import '../../models/planning.dart';
import '../../widgets/dates.dart';
import '../../widgets/errors.dart';
import '../../widgets/labels.dart';
import '../../widgets/ui.dart';

/// "Demandes · échange et remplacement" (design): swaps proposed to me,
/// and — for chefs/censeurs — what waits for a decision.
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key, required this.me});
  final Me me;

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  Key _key = UniqueKey();

  void _reload() => setState(() => _key = UniqueKey());

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      _reload();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _replace(DutyRequest r) async {
    final l = AppLocalizations.of(context);
    final cands = await RepositoryLocator.instance.planning
        .replacementCandidates(r.id)
        .catchError((Object e) {
          if (mounted) showErrorSnack(context, e);
          return <Candidate>[];
        });
    if (!mounted || cands.isEmpty) return;
    final pick = await showModalBottomSheet<Candidate>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            l.chooseReplacement,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(l.leastSolicitedFirst),
          const SizedBox(height: 12),
          GroupCard(
            children: [
              for (final c in cands.where(
                (c) => c.flag != 'on_leave' && c.flag != 'busy_same_day',
              ))
                ListRow(
                  key: Key('repl-${c.memberId}'),
                  lead: MemberAvatar(name: c.fullName, size: 36),
                  title: Text(c.fullName),
                  subtitle: Text(l.servicesThisMonth(c.servicesThisMonth)),
                  onTap: () => Navigator.of(context).pop(c),
                ),
            ],
          ),
        ],
      ),
    );
    if (pick != null) {
      await _run(
        () => RepositoryLocator.instance.planning.decide(
          r.id,
          approve: true,
          replacement: pick.memberId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = Dates(context);
    final repo = RepositoryLocator.instance.planning;
    String where(DutyRequest r) =>
        '${d.dayMonth(r.startsAt)} · ${d.time(r.startsAt)} · ${postLabel(l, r.post)} (${sideLabel(l, r.side)})';
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.requests, back: true, small: true),
            Expanded(
              child: AsyncView<(List<DutyRequest>, List<DutyRequest>)>(
                key: _key,
                load: repo.requests,
                builder: (context, data, reload) {
                  final (forMe, toDecide) = data;
                  if (forMe.isEmpty && toDecide.isEmpty) {
                    return Center(
                      child: EmptyState(
                        icon: Icons.inbox_outlined,
                        title: l.noRequests,
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      for (final r in forMe)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GroupCard(
                            padding: const EdgeInsets.all(16),
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    l.swapForYou(r.requester),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(where(r)),
                                  if (r.reason.isNotEmpty)
                                    Text('« ${r.reason} »'),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton(
                                          key: Key('accept-${r.id}'),
                                          onPressed: () => _run(
                                            () =>
                                                repo.answer(r.id, accept: true),
                                          ),
                                          child: Text(l.accept),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          key: Key('decline-${r.id}'),
                                          onPressed: () => _run(
                                            () => repo.answer(
                                              r.id,
                                              accept: false,
                                            ),
                                          ),
                                          child: Text(l.refuse),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      for (final r in toDecide)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GroupCard(
                            padding: const EdgeInsets.all(16),
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SectionLabel(
                                    r.kind == 'swap'
                                        ? l.swapDuty
                                        : l.dutyAbsent,
                                  ),
                                  Text(
                                    r.kind == 'swap'
                                        ? l.swapLine(
                                            r.requester,
                                            r.target ?? '',
                                          )
                                        : l.absenceLine(r.requester),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(where(r)),
                                  if (r.reason.isNotEmpty)
                                    Text('« ${r.reason} »'),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton(
                                          key: Key('approve-${r.id}'),
                                          onPressed: () => r.kind == 'swap'
                                              ? _run(
                                                  () => repo.decide(
                                                    r.id,
                                                    approve: true,
                                                  ),
                                                )
                                              : _replace(r),
                                          child: Text(
                                            r.kind == 'swap'
                                                ? l.approve
                                                : l.chooseReplacement,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          key: Key('refuse-${r.id}'),
                                          onPressed: () => _run(
                                            () => repo.decide(
                                              r.id,
                                              approve: false,
                                            ),
                                          ),
                                          child: Text(l.refuse),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
