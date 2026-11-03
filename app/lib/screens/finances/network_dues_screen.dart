import 'package:flutter/material.dart';

import '../../data/repositories/finances_repository.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/tokens.dart';
import '../../widgets/dates.dart';
import '../../widgets/errors.dart';
import '../../widgets/group_logo.dart';
import '../../widgets/money.dart';
import '../../widgets/ui.dart';

/// Finances → Réseau (owner, 2026-11-03: money between levels). What this
/// group owes the group above, and what it asked of the groups below.
/// Paying records a line in both cash books, approved there as usual.
class NetworkDuesScreen extends StatefulWidget {
  const NetworkDuesScreen({super.key});

  @override
  State<NetworkDuesScreen> createState() => _NetworkDuesScreenState();
}

class _NetworkDuesScreenState extends State<NetworkDuesScreen> {
  NetworkDues? _d;
  Object? _error;
  bool _busy = false;

  FinancesRepository get _repo => RepositoryLocator.instance.finances;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await _repo.networkDues();
      if (mounted) setState(() => _d = d);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _run(Future<NetworkDues> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      final d = await action();
      if (!mounted) return;
      setState(() => _d = d);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _money(NetworkDueItem d) => '${groupDigits(d.amount)} ${d.currency}';

  Future<void> _pay(NetworkDueItem d) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.netDuePayTitle(_money(d))),
        content: Text(l.netDuePayBody(d.group.name, d.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('due-pay-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.netDuePay),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _run(() => _repo.payNetworkDue(d.id), l.netDuePaid);
    }
  }

  Future<void> _cancel(NetworkDueItem d) async {
    final l = AppLocalizations.of(context);
    final reason = TextEditingController();
    final r = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.netDueCancelTitle(d.group.name)),
        content: TextField(
          key: const Key('due-cancel-reason'),
          controller: reason,
          maxLength: 300,
          decoration: InputDecoration(labelText: l.reasonRequired),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('due-cancel-confirm'),
            onPressed: () => Navigator.of(context).pop(reason.text.trim()),
            child: Text(l.netDueCancel),
          ),
        ],
      ),
    );
    reason.dispose();
    if (r != null && r.isNotEmpty) {
      await _run(() => _repo.cancelNetworkDue(d.id, r), l.netDueCancelled);
    }
  }

  Future<void> _ask() async {
    final l = AppLocalizations.of(context);
    final res = await showDialog<(String, int, DateTime?)>(
      context: context,
      builder: (_) => const _AskDialog(),
    );
    if (res == null) return;
    await _run(
      () => _repo.askNetworkDue(title: res.$1, amount: res.$2, dueOn: res.$3),
      l.netDueAsked,
    );
  }

  Widget _status(AppLocalizations l, NetworkDueItem d) => switch (d.status) {
    'received' => Badge2(l.netDueReceived, tone: Tone.green),
    'sent' => Badge2(l.netDueSent, tone: Tone.amber),
    'cancelled' => Badge2(l.netDueCancelledBadge, tone: Tone.neutral),
    _ =>
      d.late
          ? Badge2(l.netDueLate, tone: Tone.red)
          : Badge2(l.netDueOpen, tone: Tone.neutral),
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final dates = Dates(context);
    final d = _d;
    Widget item(NetworkDueItem x, {required bool owed, required bool can}) =>
        ListRow(
          key: Key('${owed ? 'owed' : 'asked'}-${x.id}'),
          lead: GroupLogo(group: x.group, size: 36),
          title: Text(x.title),
          subtitle: Text(
            [
              x.group.name,
              _money(x),
              if (x.dueOn != null) l.netDueBefore(dates.shortDate(x.dueOn!)),
              if (x.cancelReason.isNotEmpty) x.cancelReason,
            ].join(' · '),
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _status(l, x),
              if (can && x.status == 'open')
                owed
                    ? TextButton(
                        key: Key('pay-${x.id}'),
                        onPressed: _busy ? null : () => _pay(x),
                        child: Text(l.netDuePay),
                      )
                    : TextButton(
                        key: Key('cancel-due-${x.id}'),
                        onPressed: _busy ? null : () => _cancel(x),
                        child: Text(l.netDueCancel),
                      ),
            ],
          ),
        );
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.netDuesTitle, back: true, small: true),
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: d == null
                  ? Center(
                      child: _error == null
                          ? const CircularProgressIndicator()
                          : Text(describeError(context, _error!)),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        children: [
                          Text(
                            l.netDuesAbout,
                            style: TextStyle(
                              height: 1.5,
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SectionLabel(l.netDuesOwed),
                          const SizedBox(height: 8),
                          if (d.owed.isEmpty)
                            Text(
                              l.netDuesNothingOwed,
                              style: TextStyle(color: c.textSecondary),
                            )
                          else
                            GroupCard(
                              children: [
                                for (final x in d.owed)
                                  item(x, owed: true, can: d.canPay),
                              ],
                            ),
                          if (d.canAsk || d.asked.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            SectionLabel(l.netDuesAsked),
                            const SizedBox(height: 8),
                            if (d.asked.isEmpty)
                              Text(
                                l.netDuesNothingAsked,
                                style: TextStyle(color: c.textSecondary),
                              )
                            else
                              GroupCard(
                                children: [
                                  for (final x in d.asked)
                                    item(x, owed: false, can: d.canAsk),
                                ],
                              ),
                          ],
                          if (d.canAsk) ...[
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              key: const Key('ask-due'),
                              onPressed: _busy ? null : _ask,
                              icon: const Icon(Icons.add),
                              label: Text(l.netDueNew),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ],
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

class _AskDialog extends StatefulWidget {
  const _AskDialog();

  @override
  State<_AskDialog> createState() => _AskDialogState();
}

class _AskDialogState extends State<_AskDialog> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  DateTime? _due;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.netDueNew),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.netDueNewHint),
            const SizedBox(height: 12),
            TextField(
              key: const Key('due-title'),
              controller: _title,
              maxLength: 120,
              decoration: InputDecoration(labelText: l.netDueTitleLabel),
            ),
            TextField(
              key: const Key('due-amount'),
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l.netDueAmountLabel,
                suffixText: Currency.code,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              key: const Key('due-date'),
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  firstDate: now,
                  lastDate: DateTime(now.year + 2),
                  initialDate: _due ?? now.add(const Duration(days: 30)),
                );
                if (d != null) setState(() => _due = d);
              },
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _due == null
                    ? l.netDueNoDate
                    : l.netDueBefore(Dates(context).shortDate(_due!)),
              ),
            ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: context.msg.alert)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('due-send'),
          onPressed: () {
            final amount = int.tryParse(
              _amount.text.replaceAll(RegExp(r'\D'), ''),
            );
            if (_title.text.trim().length < 3 ||
                amount == null ||
                amount <= 0) {
              setState(() => _error = l.netDueFormError);
              return;
            }
            Navigator.of(context).pop((_title.text.trim(), amount, _due));
          },
          child: Text(l.netDueSend),
        ),
      ],
    );
  }
}
