import 'package:flutter/material.dart';

import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/planning.dart';
import '../../theme/tokens.dart';
import '../../widgets/dates.dart';
import '../../widgets/errors.dart';
import '../../widgets/labels.dart';
import '../../widgets/ui.dart';
import 'duty_widgets.dart';

/// One duty card (design: "Mes services"): when, post, chef, dress;
/// Confirmer / Échanger.
class DutyCard extends StatelessWidget {
  const DutyCard({super.key, required this.duty, required this.onChanged});
  final DutyAssignment duty;
  final VoidCallback onChanged;

  Future<void> _confirm(BuildContext context) async {
    try {
      await RepositoryLocator.instance.planning.confirm(duty.id);
      onChanged();
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final d = Dates(context);
    final a = duty;
    return GroupCard(
      padding: const EdgeInsets.all(16),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    a.startsAt == null
                        ? ''
                        : '${d.dayMonth(a.startsAt!)} · ${d.time(a.startsAt!)}'
                              .toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: c.primaryText,
                    ),
                  ),
                ),
                DutyChip(status: a.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${postLabel(l, a.slot.post)} · ${sideLabel(l, a.slot.side)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            if (a.title != null)
              Text(
                a.title!,
                style: TextStyle(fontSize: 14, color: c.textSecondary),
              ),
            if (a.isChef) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  key: const Key('you-are-chef'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.primaryTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag, size: 14, color: c.primaryText),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l.youAreChef,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: c.primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (a.chef != null || (a.dress ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              if (a.chef != null)
                Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 16, color: c.textTertiary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l.chefLabel(a.chef!))),
                  ],
                ),
              if ((a.dress ?? '').isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.checkroom_outlined,
                      size: 16,
                      color: c.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(dressLabel(l, a.dress!))),
                  ],
                ),
            ],
            if (a.status == 'pend') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      key: Key('confirm-${a.id}'),
                      onPressed: () => _confirm(context),
                      child: FitText(l.confirmDuty),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonal(
                      key: Key('swap-${a.id}'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 52),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () async {
                        final sent = await showSwapSheet(context, a);
                        if (sent == true) onChanged();
                      },
                      child: FitText(l.swapDuty),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class MyDutiesView extends StatelessWidget {
  const MyDutiesView({super.key, required this.header});
  final Widget header;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AsyncView<List<DutyAssignment>>(
      load: RepositoryLocator.instance.planning.mine,
      builder: (context, duties, reload) => RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            header,
            if (duties.isEmpty)
              EmptyState(
                icon: Icons.event_available_outlined,
                title: l.noDuties,
              )
            else
              for (final a in duties)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DutyCard(duty: a, onChanged: reload),
                ),
          ],
        ),
      ),
    );
  }
}

/// "Échanger mon service" (design): pick a free colleague + reason; or say
/// you can't come (absence → the chef finds a replacement).
Future<bool?> showSwapSheet(BuildContext context, DutyAssignment duty) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (context, scroll) => _SwapSheet(duty: duty, scroll: scroll),
    ),
  );
}

class _SwapSheet extends StatefulWidget {
  const _SwapSheet({required this.duty, required this.scroll});
  final DutyAssignment duty;
  final ScrollController scroll;

  @override
  State<_SwapSheet> createState() => _SwapSheetState();
}

class _SwapSheetState extends State<_SwapSheet> {
  Candidate? _target;
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _send({required bool absence}) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final repo = RepositoryLocator.instance.planning;
      if (absence) {
        await repo.declareAbsence(widget.duty.id, reason: _reason.text.trim());
      } else {
        await repo.requestSwap(
          widget.duty.id,
          target: _target!.memberId,
          reason: _reason.text.trim(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.requestSent)));
      Navigator.of(context).pop(true);
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
    return AsyncView<List<Candidate>>(
      load: () =>
          RepositoryLocator.instance.planning.swapCandidates(widget.duty.id),
      builder: (context, cands, _) => ListView(
        controller: widget.scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(l.swapTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${postLabel(l, widget.duty.slot.post)} · ${sideLabel(l, widget.duty.slot.side)}',
            style: TextStyle(color: c.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('swap-reason'),
            controller: _reason,
            decoration: InputDecoration(labelText: l.reasonOptional),
          ),
          const SizedBox(height: 12),
          SectionLabel(l.withWhom),
          const SizedBox(height: 8),
          GroupCard(
            children: [
              for (final cand in cands)
                ListRow(
                  key: Key('swap-to-${cand.memberId}'),
                  lead: Icon(
                    _target?.memberId == cand.memberId
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: c.primary,
                  ),
                  title: Text(cand.fullName),
                  onTap: () => setState(() => _target = cand),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('swap-send'),
            onPressed: _busy || _target == null
                ? null
                : () => _send(absence: false),
            child: Text(l.sendRequest),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('absence-send'),
            onPressed: _busy ? null : () => _send(absence: true),
            child: Text(l.declareAbsence),
          ),
        ],
      ),
    );
  }
}
