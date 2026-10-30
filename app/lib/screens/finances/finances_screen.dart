import 'package:flutter/material.dart';

import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/finance.dart';
import '../../models/me.dart';
import '../../theme/tokens.dart';
import '../../widgets/dates.dart';
import '../../widgets/errors.dart';
import '../../widgets/files.dart';
import '../../widgets/labels.dart';
import '../../widgets/money.dart';
import '../../widgets/ui.dart';
import 'collection_screen.dart';
import 'entry_form_screen.dart';
import 'report_screen.dart';

/// Finances tab (design: "Finances · livre de caisse"): balance, then the
/// cash book, solidarity collections, and the quarterly report.
class FinancesScreen extends StatefulWidget {
  const FinancesScreen({super.key, required this.me});
  final Me me;

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> {
  int _tab = 0;
  Key _reload = UniqueKey();

  bool get _canReport => widget.me.can('finances.report', 'view');

  void _refresh() => setState(() => _reload = UniqueKey());

  /// The PDF is downloaded, kept for offline and opened (files.dart).
  Future<void> _export(
    String source,
    String name,
    Future<String> Function() link,
  ) => openDocument(context, source: source, name: name, link: link);

  Future<void> _newEntry() async {
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const EntryFormScreen()));
    if (saved == true) _refresh();
  }

  Future<void> _newCollection() async {
    final created = await showNewCollectionSheet(context);
    if (created != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              CollectionScreen(collectionId: created.id, me: widget.me),
        ),
      );
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final tabs = [l.cashBook, l.solidarity, if (_canReport) l.report];
    final canEntry = widget.me.can('finances.cashbook', 'create');
    final canCollect = widget.me.can('finances.solidarity', 'create');
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _tab == 0 && canEntry
          ? FloatingActionButton.extended(
              key: const Key('new-entry'),
              onPressed: _newEntry,
              icon: const Icon(Icons.add),
              label: Text(l.entryButton),
              backgroundColor: c.primary,
              foregroundColor: Colors.white,
            )
          : _tab == 1 && canCollect
          ? FloatingActionButton.extended(
              key: const Key('new-collection'),
              onPressed: _newCollection,
              icon: const Icon(Icons.add),
              label: Text(l.newCollection),
              backgroundColor: c.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          ScreenHeader(
            title: l.tabFinances,
            sync: true,
            actions: [
              if (widget.me.can('finances.cashbook', 'export'))
                IconButton(
                  key: const Key('export-statement'),
                  tooltip: l.statementPdf,
                  icon: const Icon(Icons.summarize_outlined),
                  onPressed: () => _export(
                    'fin-statement',
                    l.pdfStatementName(fileDate()),
                    RepositoryLocator.instance.finances.statementPdf,
                  ),
                ),
              if (_tab == 0 && widget.me.can('finances.cashbook', 'export'))
                IconButton(
                  key: const Key('export-cashbook'),
                  tooltip: l.exportPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: () => _export(
                    'fin-cashbook',
                    l.pdfCashbookName(fileDate()),
                    RepositoryLocator.instance.finances.cashbookPdf,
                  ),
                ),
            ],
          ),
          Expanded(
            child: KeyedSubtree(
              key: _reload,
              child: switch (_tab) {
                0 => _CashBook(
                  me: widget.me,
                  header: _header(tabs),
                  onChanged: _refresh,
                ),
                1 => _Collections(me: widget.me, header: _header(tabs)),
                _ => ReportView(me: widget.me, header: _header(tabs)),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(List<String> tabs) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Balance(key: ValueKey(_reload)),
      const SizedBox(height: 16),
      Seg2(
        options: tabs,
        selected: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
      const SizedBox(height: 12),
    ],
  );
}

class _Balance extends StatelessWidget {
  const _Balance({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    return FutureBuilder<FinanceSummary>(
      future: RepositoryLocator.instance.finances.summary(),
      builder: (context, snap) {
        final s = snap.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.cashBalance.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            if (s == null)
              const SizedBox(
                height: 38,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else ...[
              Amount(
                s.balance,
                size: 32,
                weight: FontWeight.w800,
                key: const Key('balance'),
              ),
              if (s.validatedUntil != null)
                Text(
                  l.validatedUntil(Dates(context).fullDate(s.validatedUntil!)),
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                ),
              if (s.pending > 0)
                Text(
                  l.withPending(fcfa(s.balanceWithPending)),
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                ),
            ],
          ],
        );
      },
    );
  }
}

/// One cash-book line (design: BookRow): who entered, when, who validated.
class EntryRow extends StatelessWidget {
  const EntryRow({super.key, required this.entry, this.onTap});
  final FinanceEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final d = Dates(context);
    final e = entry;
    return ListRow(
      key: Key('entry-${e.id}'),
      onTap: onTap,
      lead: IconChip(
        e.isIn ? Icons.south_west : Icons.north_east,
        tone: e.isIn ? Tone.green : Tone.neutral,
      ),
      title: Text('${financeCategoryLabel(l, e.category)} · ${e.label}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (e.memberName != null) Text(e.memberName!),
          Text(
            [
              l.enteredBy(
                e.createdByName,
                '${d.dayMonth(e.createdAt)}, ${d.time(e.createdAt)}',
              ),
              if (e.editedByName != null) l.editedBy(e.editedByName!),
              if (e.validatedByName != null) l.validatedBy(e.validatedByName!),
            ].join(' · '),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          if (e.local)
            Row(
              children: [
                Icon(Icons.cloud_off, size: 13, color: c.textSecondary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    l.notSentYet,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else if (e.pending || e.toConfirm || e.edited)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (e.pending) Badge2(l.toValidate, tone: Tone.amber),
                if (e.toConfirm)
                  Badge2(
                    l.toConfirmBadge,
                    key: Key('to-confirm-${e.id}'),
                    tone: Tone.amber,
                  ),
                if (e.edited) Badge2(l.editedBadge, key: Key('edited-${e.id}')),
              ],
            ),
        ],
      ),
      trailing: Amount(
        e.isIn ? e.amount : -e.amount,
        sign: true,
        color: e.isIn ? c.primaryText : c.textPrimary,
      ),
    );
  }
}

class _CashBook extends StatelessWidget {
  const _CashBook({
    required this.me,
    required this.header,
    required this.onChanged,
  });
  final Me me;
  final Widget header;
  final VoidCallback onChanged;

  /// The trésorier: validate, or correct it first (owner, 2026-10-30).
  Future<void> _validate(BuildContext context, FinanceEntry e) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.validateEntryTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GroupCard(
              children: [
                ListRow(
                  title: Text(e.label),
                  subtitle: Text(e.memberName ?? e.createdByName),
                  trailing: Amount(e.amount),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(e.edited ? l.validateEditedNote : l.validateEntryBody),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel),
          ),
          OutlinedButton(
            key: const Key('edit-entry'),
            onPressed: () => Navigator.of(context).pop('edit'),
            child: Text(l.editAction),
          ),
          FilledButton(
            key: const Key('validate-confirm'),
            onPressed: () => Navigator.of(context).pop('validate'),
            child: Text(l.validate),
          ),
        ],
      ),
    );
    if (ok == null || !context.mounted) return;
    if (ok == 'edit') {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => EntryFormScreen(editing: e)),
      );
      if (saved == true) onChanged();
      return;
    }
    try {
      await RepositoryLocator.instance.finances.validate(e.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.entryValidated)));
      onChanged();
    } catch (err) {
      if (context.mounted) showErrorSnack(context, err);
    }
  }

  /// The commissaire who entered it: finalise the trésorier's correction,
  /// or send it back with the reason.
  Future<void> _finalise(BuildContext context, FinanceEntry e) async {
    final l = AppLocalizations.of(context);
    final answer = await showDialog<(bool, String)>(
      context: context,
      builder: (context) => _FinaliseDialog(entry: e),
    );
    if (answer == null || !context.mounted) return;
    final (choice, why) = answer;
    try {
      await RepositoryLocator.instance.finances.confirmEntry(
        e.id,
        accept: choice,
        reason: why,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(choice ? l.entryFinalised : l.entrySentBack)),
      );
      onChanged();
    } catch (err) {
      if (context.mounted) showErrorSnack(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final canValidate = me.can('finances.cashbook', 'validate');
    final canEnter = me.can('finances.cashbook', 'create');
    return AsyncView<List<FinanceEntry>>(
      load: RepositoryLocator.instance.finances.entries,
      builder: (context, entries, reload) => RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            header,
            if (entries.isEmpty)
              EmptyState(icon: Icons.receipt_long_outlined, title: l.noEntries)
            else
              GroupCard(
                children: [
                  for (final e in entries)
                    EntryRow(
                      entry: e,
                      onTap: canValidate && e.pending && !e.local
                          ? () => _validate(context, e)
                          : canEnter && e.toConfirm
                          ? () => _finalise(context, e)
                          : null,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// "Finaliser l'opération ?": owns the reason box, so it outlives the
/// dialog's closing animation.
class _FinaliseDialog extends StatefulWidget {
  const _FinaliseDialog({required this.entry});
  final FinanceEntry entry;

  @override
  State<_FinaliseDialog> createState() => _FinaliseDialogState();
}

class _FinaliseDialogState extends State<_FinaliseDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final e = widget.entry;
    return AlertDialog(
      title: Text(l.confirmEntryTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GroupCard(
              children: [
                ListRow(
                  title: Text(e.label),
                  subtitle: Text(e.memberName ?? e.createdByName),
                  trailing: Amount(e.amount),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(l.confirmEntryBody(e.editedByName ?? e.validatedByName ?? '')),
            const SizedBox(height: 12),
            TextField(
              key: const Key('send-back-reason'),
              controller: _reason,
              decoration: InputDecoration(labelText: l.sendBackReason),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('send-back'),
          onPressed: () =>
              Navigator.of(context).pop((false, _reason.text.trim())),
          child: Text(l.sendBack),
        ),
        FilledButton(
          key: const Key('finalise'),
          onPressed: () => Navigator.of(context).pop((true, '')),
          child: Text(l.finalise),
        ),
      ],
    );
  }
}

class _Collections extends StatelessWidget {
  const _Collections({required this.me, required this.header});
  final Me me;
  final Widget header;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AsyncView<List<Collection>>(
      load: RepositoryLocator.instance.finances.collections,
      builder: (context, items, reload) => RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            header,
            if (items.isEmpty)
              EmptyState(
                icon: Icons.volunteer_activism_outlined,
                title: l.noCollections,
              )
            else
              GroupCard(
                children: [
                  for (final c in items)
                    ListRow(
                      key: Key('collection-${c.id}'),
                      lead: IconChip(
                        Icons.volunteer_activism_outlined,
                        tone: c.closed ? Tone.neutral : Tone.green,
                      ),
                      title: Text(c.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.paidFullOf(c.paidFull, c.members)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: c.members == 0
                                  ? 0
                                  : c.paidFull / c.members,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                      trailing: c.closed ? Badge2(l.closed) : null,
                      chevron: true,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CollectionScreen(collectionId: c.id, me: me),
                          ),
                        );
                        reload();
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
