import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/finance.dart';
import '../../models/me.dart';
import '../../theme/tokens.dart';
import '../../widgets/errors.dart';
import '../../widgets/labels.dart';
import '../../widgets/money.dart';
import '../../widgets/ui.dart';

/// "Contribution de solidarité · qui a payé" (design): progress, thirds per
/// member; tick several members and save their next instalment at once.
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({
    super.key,
    required this.collectionId,
    required this.me,
  });
  final int collectionId;
  final Me me;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  Collection? _c;
  Object? _error;
  int _filter = 0; // 0 à payer, 1 payé, 2 tous
  final Map<int, int> _selected = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await RepositoryLocator.instance.finances.collection(
        widget.collectionId,
      );
      if (mounted) setState(() => _c = c);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await RepositoryLocator.instance.finances.pay(
        widget.collectionId,
        Map.of(_selected),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.paymentsSaved)));
      _selected.clear();
      await _load();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l.closeCollection} ?'),
        content: Text(l.closeCollectionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.confirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await RepositoryLocator.instance.finances.closeCollection(
        widget.collectionId,
      );
      await _load();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final col = _c;
    final canPay =
        widget.me.can('finances.solidarity', 'create') &&
        !(col?.closed ?? true);
    final rows = col?.rows ?? const <CollectionRow>[];
    final shown = switch (_filter) {
      0 => rows.where((r) => !r.done).toList(),
      1 => rows.where((r) => r.done).toList(),
      _ => rows,
    };
    final total = _selected.values.fold<int>(0, (a, b) => a + b);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: col?.title ?? '',
              subtitle: col == null
                  ? null
                  : '${fcfa(col.amountPerMember)} · ${collectionKindLabel(l, col.kind)}',
              back: true,
              small: true,
              actions: [
                if (canPay && widget.me.can('finances.solidarity', 'change'))
                  IconButton(
                    tooltip: l.closeCollection,
                    icon: const Icon(Icons.lock_outline),
                    onPressed: _close,
                  ),
              ],
            ),
            Expanded(
              child: col == null
                  ? (_error == null
                        ? const Center(child: CircularProgressIndicator())
                        : Center(
                            child: EmptyState(
                              icon: Icons.cloud_off_outlined,
                              error: true,
                              title: l.loadError,
                              text: describeError(context, _error!),
                            ),
                          ))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          GroupCard(
                            padding: const EdgeInsets.all(16),
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          l.paidFullOf(
                                            col.paidFull,
                                            col.members,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      Amount(col.collected),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: col.members == 0
                                          ? 0
                                          : col.paidFull / col.members,
                                      minHeight: 8,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    l.tranchesInfo(
                                      col.parts.map(groupDigits).join(' · '),
                                    ),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: c.textSecondary,
                                    ),
                                  ),
                                  if (col.closed) ...[
                                    const SizedBox(height: 8),
                                    Badge2(l.closed),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FilterChips(
                            labels: [
                              l.filterToPay(rows.where((r) => !r.done).length),
                              l.filterPaid(rows.where((r) => r.done).length),
                              l.filterAll(rows.length),
                            ],
                            selected: _filter,
                            onSelected: (i) => setState(() => _filter = i),
                          ),
                          const SizedBox(height: 12),
                          GroupCard(
                            children: [
                              for (final r in shown)
                                ListRow(
                                  key: Key('pay-${r.memberId}'),
                                  onTap: canPay && !r.done
                                      ? () => setState(
                                          () =>
                                              _selected.containsKey(r.memberId)
                                              ? _selected.remove(r.memberId)
                                              : _selected[r.memberId] =
                                                    r.nextAmount,
                                        )
                                      : null,
                                  lead: _Check(
                                    on: _selected.containsKey(r.memberId),
                                    done: r.done,
                                  ),
                                  title: Row(
                                    children: [
                                      Flexible(child: Text(r.fullName)),
                                      if (r.isDiaspora) ...[
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.public,
                                          size: 13,
                                          color: c.textSecondary,
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Row(
                                    children: [
                                      _Thirds(n: r.thirds),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          r.done
                                              ? l.paidInFull
                                              : l.thirdsOf3(r.thirds),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Amount(
                                    r.paid,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
            if (_selected.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: c.surfaceCard,
                  border: Border(top: BorderSide(color: c.borderSubtle)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('save-payments'),
                    onPressed: _busy ? null : _save,
                    child: Text(l.savePayments(_selected.length, fcfa(total))),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.on, required this.done});
  final bool on;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: on ? c.primary : (done ? c.surfaceSunken : null),
        borderRadius: BorderRadius.circular(8),
        border: on || done ? null : Border.all(color: c.borderStrong, width: 2),
      ),
      child: on || done
          ? Icon(
              Icons.check,
              size: 16,
              color: on ? Colors.white : c.primaryText,
            )
          : null,
    );
  }
}

class _Thirds extends StatelessWidget {
  const _Thirds({required this.n});
  final int n;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            margin: const EdgeInsets.only(right: 3),
            width: 16,
            height: 6,
            decoration: BoxDecoration(
              color: i < n ? c.primary : c.surfaceSunken,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

/// Opens a collection: kind, title, amount per member.
Future<Collection?> showNewCollectionSheet(BuildContext context) {
  return showModalBottomSheet<Collection>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _NewCollection(),
  );
}

class _NewCollection extends StatefulWidget {
  const _NewCollection();

  @override
  State<_NewCollection> createState() => _NewCollectionState();
}

class _NewCollectionState extends State<_NewCollection> {
  String _kind = 'deces';
  final _title = TextEditingController();
  final _amount = TextEditingController(text: '2500');
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l = AppLocalizations.of(context);
    final amount = int.tryParse(_amount.text) ?? 0;
    if (_title.text.trim().isEmpty || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.required)));
      return;
    }
    setState(() => _busy = true);
    try {
      final c = await RepositoryLocator.instance.finances.openCollection(
        kind: _kind,
        title: _title.text.trim(),
        amountPerMember: amount,
      );
      if (mounted) Navigator.of(context).pop(c);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.newCollection, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _kind,
            decoration: InputDecoration(labelText: l.collectionKind),
            items: [
              for (final k in collectionKinds)
                DropdownMenuItem(
                  value: k,
                  child: Text(collectionKindLabel(l, k)),
                ),
            ],
            onChanged: (v) => setState(() => _kind = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('c-title'),
            controller: _title,
            decoration: InputDecoration(labelText: l.eventTitle),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('c-amount'),
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l.amountPerMember,
              suffixText: 'FCFA',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('c-create'),
            onPressed: _busy ? null : _create,
            child: Text(l.save),
          ),
        ],
      ),
    );
  }
}
