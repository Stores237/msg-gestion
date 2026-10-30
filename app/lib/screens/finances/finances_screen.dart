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
import '../expenses/expenses_screen.dart';
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
  bool _picking = false;

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
      floatingActionButton: _picking
          ? null
          : _tab == 0 && canEntry
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
                  onSelecting: (on) => setState(() => _picking = on),
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
      // The finance team's way into expense requests (with what waits).
      if (widget.me.can('finances.expenses', 'view')) ...[
        const SizedBox(height: 12),
        ExpensesEntryRow(key: ValueKey(('exp', _reload)), me: widget.me),
      ],
      const SizedBox(height: 16),
      Seg2(
        options: tabs,
        selected: _tab,
        onChanged: (i) => setState(() {
          _tab = i;
          _picking = false;
        }),
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

/// One cash-book line (design: BookRow), reworked for the owner (2026-10-30):
/// who first (the member, else the description) with the amount on the same
/// line, the category below only when it adds something, who entered and
/// validated, then the actions the viewer may take, as buttons.
class EntryRow extends StatelessWidget {
  const EntryRow({
    super.key,
    required this.entry,
    this.onTap,
    this.onEdit,
    this.onValidate,
    this.onFinalise,
    this.onLongPress,
    this.selected,
  });
  final FinanceEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onValidate;
  final VoidCallback? onFinalise;
  final VoidCallback? onLongPress;

  /// While several lines are being picked: ticked or not; null for a line
  /// that can't be picked (shown as usual).
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final d = Dates(context);
    final e = entry;
    final category = financeCategoryLabel(l, e.category);
    final title = e.memberName ?? e.label;
    final detail = [
      category,
      if (e.memberName != null && e.label != category) e.label,
    ].join(' · ');
    final compact = ButtonStyle(
      visualDensity: VisualDensity.compact,
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12),
      ),
    );
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selected != null)
            SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                selected! ? Icons.check_circle : Icons.radio_button_unchecked,
                key: Key('pick-${e.id}'),
                color: selected! ? c.primary : c.textTertiary,
              ),
            )
          else
            IconChip(
              e.isIn ? Icons.south_west : Icons.north_east,
              tone: e.isIn ? Tone.green : Tone.neutral,
              size: 36,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.4,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Amount(
                          e.isIn ? e.amount : -e.amount,
                          sign: true,
                          color: e.isIn ? c.primaryText : c.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (e.expenseId != null)
                  Text(
                    l.fromExpense(e.expenseId!),
                    key: Key('from-expense-${e.id}'),
                    style: TextStyle(fontSize: 13, color: c.primaryText),
                  ),
                if (detail != title)
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                const SizedBox(height: 2),
                Text(
                  [
                    l.enteredBy(
                      e.createdByName,
                      '${d.dayMonth(e.createdAt)}, ${d.time(e.createdAt)}',
                    ),
                    if (e.editedByName != null) l.editedBy(e.editedByName!),
                    if (e.validatedByName != null)
                      l.validatedBy(e.validatedByName!),
                  ].join(' · '),
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
                if (e.local) ...[
                  const SizedBox(height: 6),
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
                  ),
                ] else if (e.pending || e.toConfirm || e.edited) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (e.pending && e.awaitingOther)
                        Badge2(
                          l.awaitingOtherBadge,
                          key: Key('awaiting-${e.id}'),
                        )
                      else if (e.pending)
                        Badge2(l.toValidate, tone: Tone.amber),
                      if (e.toConfirm)
                        Badge2(
                          l.toConfirmBadge,
                          key: Key('to-confirm-${e.id}'),
                          tone: Tone.amber,
                        ),
                      if (e.edited)
                        Badge2(l.editedBadge, key: Key('edited-${e.id}')),
                    ],
                  ),
                ],
                if (onEdit != null || onValidate != null || onFinalise != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (onEdit != null)
                          OutlinedButton.icon(
                            key: Key('edit-${e.id}'),
                            style: compact,
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: Text(l.editAction),
                          ),
                        if (onValidate != null)
                          FilledButton.icon(
                            key: Key('validate-${e.id}'),
                            style: compact,
                            onPressed: onValidate,
                            icon: const Icon(Icons.check, size: 16),
                            label: Text(l.validate),
                          ),
                        if (onFinalise != null)
                          FilledButton.icon(
                            key: Key('finalise-${e.id}'),
                            style: compact,
                            onPressed: onFinalise,
                            icon: const Icon(Icons.task_alt, size: 16),
                            label: Text(l.finalise),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    return KeyedSubtree(
      key: Key('entry-${e.id}'),
      child: onTap == null && onLongPress == null
          ? row
          : InkWell(onTap: onTap, onLongPress: onLongPress, child: row),
    );
  }
}

/// How the cash book is grouped (owner, 2026-10-30): by day (who paid on
/// that date), by type, by status, by member.
enum CashBookGrouping { day, type, status, member }

/// One group of lines: a header (title, count, net total) over its card.
typedef EntryGroup = ({String key, String title, List<FinanceEntry> items});

List<EntryGroup> groupEntries(
  List<FinanceEntry> entries,
  CashBookGrouping by, {
  required String Function(DateTime) dayTitle,
  required String Function(String) categoryTitle,
  required String Function(FinanceEntry) statusTitle,
  required String noMember,
}) {
  final groups = <String, EntryGroup>{};
  final order = <String, Object>{};
  for (final e in entries) {
    final (String key, String title, Object rank) = switch (by) {
      CashBookGrouping.day => (
        'day-${e.date.year}-${e.date.month}-${e.date.day}',
        dayTitle(e.date),
        -DateTime(e.date.year, e.date.month, e.date.day).millisecondsSinceEpoch,
      ),
      CashBookGrouping.type => (
        'type-${e.category}',
        categoryTitle(e.category),
        _categoryRank(e.category),
      ),
      CashBookGrouping.status => (
        'status-${_statusKey(e)}',
        statusTitle(e),
        _statusOrder.indexOf(_statusKey(e)),
      ),
      CashBookGrouping.member => (
        'member-${e.memberId ?? 0}',
        e.memberName ?? noMember,
        e.memberName == null ? '￿' : e.memberName!.toLowerCase(),
      ),
    };
    groups.putIfAbsent(key, () => (key: key, title: title, items: []));
    groups[key]!.items.add(e);
    order[key] = rank;
  }
  final keys = groups.keys.toList()
    ..sort(
      (a, b) =>
          Comparable.compare(order[a]! as Comparable, order[b]! as Comparable),
    );
  return [for (final k in keys) groups[k]!];
}

const _statusOrder = ['local', 'pending', 'to_confirm', 'validated'];

String _statusKey(FinanceEntry e) => e.local ? 'local' : e.status;

int _categoryRank(String c) {
  final all = [...incomeCategories, 'depense'];
  final i = all.indexOf(c);
  return i < 0 ? all.length : i;
}

class _CashBook extends StatefulWidget {
  const _CashBook({
    required this.me,
    required this.header,
    required this.onChanged,
    required this.onSelecting,
  });
  final Me me;
  final Widget header;
  final VoidCallback onChanged;

  /// Picking several lines: the screen hides its "+ Opération" button.
  final ValueChanged<bool> onSelecting;

  @override
  State<_CashBook> createState() => _CashBookState();
}

class _CashBookState extends State<_CashBook> {
  // Kept across refreshes (the tab is rebuilt after each change).
  static CashBookGrouping _lastGrouping = CashBookGrouping.day;
  static final _folded = <String>{};

  CashBookGrouping _by = _lastGrouping;

  /// Lines picked by a long press, to validate at once (owner, 2026-10-30).
  final _picked = <int>{};
  List<FinanceEntry> _shown = const [];

  /// Picking lines: by a long press on one, or the "Sélectionner" button.
  bool _picking = false;

  void _startPicking() {
    setState(() => _picking = true);
    widget.onSelecting(true);
  }

  void _pick(FinanceEntry e) {
    if (!_picking) _startPicking();
    setState(
      () => _picked.contains(e.id) ? _picked.remove(e.id) : _picked.add(e.id),
    );
  }

  void _pickAll() {
    setState(() {
      _picked.addAll([
        for (final e in _shown)
          if (e.canApprove && !e.local) e.id,
      ]);
    });
    widget.onSelecting(true);
  }

  void _stopPicking() {
    setState(() {
      _picked.clear();
      _picking = false;
    });
    widget.onSelecting(false);
  }

  Future<void> _validatePicked() async {
    final l = AppLocalizations.of(context);
    final lines = [
      for (final e in _shown)
        if (_picked.contains(e.id)) e,
    ];
    final total = lines.fold<int>(
      0,
      (s, e) => s + (e.isIn ? e.amount : -e.amount),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.validateManyTitle(lines.length)),
        content: Text(l.validateManyBody(fcfa(total))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('validate-many-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.validate),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final r = await RepositoryLocator.instance.finances.validateMany([
        for (final e in lines) e.id,
      ]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            [
              l.validatedMany(r.validated.length),
              if (r.skipped > 0) l.skippedMany(r.skipped),
            ].join(' '),
          ),
        ),
      );
      _picked.clear();
      _picking = false;
      widget.onSelecting(false);
      widget.onChanged();
    } catch (err) {
      if (mounted) showErrorSnack(context, err);
    }
  }

  Widget _pickBar(AppLocalizations l) {
    final c = context.msg;
    return Material(
      color: c.surfaceCard,
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: Row(
          children: [
            IconButton(
              key: const Key('pick-cancel'),
              tooltip: l.cancel,
              icon: const Icon(Icons.close),
              onPressed: _stopPicking,
            ),
            Expanded(
              child: Text(
                l.selectedCount(_picked.length),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              key: const Key('pick-all'),
              onPressed: _pickAll,
              child: Text(l.selectAll),
            ),
            const SizedBox(width: 4),
            FilledButton(
              key: const Key('validate-selected'),
              onPressed: _picked.isEmpty ? null : _validatePicked,
              child: Text(l.validateSelected(_picked.length)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(FinanceEntry e) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EntryFormScreen(editing: e)),
    );
    if (saved == true) widget.onChanged();
  }

  /// The trésorier: validate, or correct it first (owner, 2026-10-30).
  Future<void> _validate(FinanceEntry e) async {
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
    if (ok == null || !mounted) return;
    if (ok == 'edit') return _edit(e);
    try {
      await RepositoryLocator.instance.finances.validate(e.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.entryValidated)));
      widget.onChanged();
    } catch (err) {
      if (mounted) showErrorSnack(context, err);
    }
  }

  /// The commissaire who entered it: finalise the trésorier's correction,
  /// or send it back with the reason.
  Future<void> _finalise(FinanceEntry e) async {
    final l = AppLocalizations.of(context);
    final answer = await showDialog<(bool, String)>(
      context: context,
      builder: (context) => _FinaliseDialog(entry: e),
    );
    if (answer == null || !mounted) return;
    final (choice, why) = answer;
    try {
      await RepositoryLocator.instance.finances.confirmEntry(
        e.id,
        accept: choice,
        reason: why,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(choice ? l.entryFinalised : l.entrySentBack)),
      );
      widget.onChanged();
    } catch (err) {
      if (mounted) showErrorSnack(context, err);
    }
  }

  void _group(CashBookGrouping by) => setState(() => _by = _lastGrouping = by);

  void _fold(String key) => setState(
    () => _folded.contains(key) ? _folded.remove(key) : _folded.add(key),
  );

  Widget _groupingBar(AppLocalizations l) {
    final options = {
      CashBookGrouping.day: l.groupByDay,
      CashBookGrouping.type: l.groupByType,
      CashBookGrouping.status: l.groupByStatus,
      CashBookGrouping.member: l.groupByMember,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      // One scrolling line, whatever the phone's text size.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              l.groupBy,
              style: TextStyle(fontSize: 13, color: context.msg.textSecondary),
            ),
            for (final MapEntry(key: by, value: name) in options.entries) ...[
              const SizedBox(width: 8),
              ChoiceChip(
                key: Key('group-by-${by.name}'),
                label: Text(name),
                selected: _by == by,
                onSelected: (_) => _group(by),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _groupHeader(AppLocalizations l, EntryGroup g) {
    final c = context.msg;
    final net = g.items.fold<int>(
      0,
      (s, e) => s + (e.isIn ? e.amount : -e.amount),
    );
    final folded = _folded.contains(g.key);
    return InkWell(
      key: Key('group-${g.key}'),
      onTap: () => _fold(g.key),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    g.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    l.entriesCount(g.items.length),
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Amount(net, sign: true, size: 14),
            Icon(
              folded ? Icons.expand_more : Icons.expand_less,
              size: 20,
              color: c.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  String _statusTitle(AppLocalizations l, FinanceEntry e) =>
      switch (_statusKey(e)) {
        'local' => l.notSentYet,
        'pending' => l.toValidate,
        'to_confirm' => l.toConfirmBadge,
        _ => l.validated,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = Dates(context);
    final canEnter = widget.me.can('finances.cashbook', 'create');
    return AsyncView<List<FinanceEntry>>(
      load: RepositoryLocator.instance.finances.entries,
      builder: (context, entries, reload) {
        _shown = entries;
        final approvable = entries.any((e) => e.canApprove && !e.local);
        final groups = groupEntries(
          entries,
          _by,
          dayTitle: (day) {
            final t = d.fullDate(day);
            return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
          },
          categoryTitle: (cat) => financeCategoryLabel(l, cat),
          statusTitle: (e) => _statusTitle(l, e),
          noMember: l.noMemberGroup,
        );
        final list = RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              widget.header,
              if (entries.isEmpty)
                EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: l.noEntries,
                )
              else ...[
                _groupingBar(l),
                if (approvable && !_picking)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.longPressHint,
                            key: const Key('long-press-hint'),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.msg.textSecondary,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          key: const Key('select-mode'),
                          onPressed: _startPicking,
                          icon: const Icon(Icons.checklist, size: 18),
                          label: Text(l.selectLines),
                        ),
                      ],
                    ),
                  ),
                for (final g in groups) ...[
                  _groupHeader(l, g),
                  if (!_folded.contains(g.key))
                    GroupCard(
                      children: [
                        for (final e in g.items) _row(e, canEnter: canEnter),
                      ],
                    ),
                ],
              ],
            ],
          ),
        );
        if (!_picking) return list;
        return Column(
          children: [
            Expanded(child: list),
            _pickBar(l),
          ],
        );
      },
    );
  }

  Widget _row(FinanceEntry e, {required bool canEnter}) {
    // What the viewer may do comes from the server, per line: approve it
    // (they neither entered nor last changed it), correct it.
    final approving = e.canApprove && !e.local;
    final editing = e.canEdit && e.pending && !e.local;
    final finalising = canEnter && e.toConfirm;
    if (_picking) {
      return EntryRow(
        entry: e,
        selected: approving ? _picked.contains(e.id) : null,
        onTap: approving ? () => _pick(e) : null,
      );
    }
    return EntryRow(
      entry: e,
      onTap: approving
          ? () => _validate(e)
          : editing
          ? () => _edit(e)
          : finalising
          ? () => _finalise(e)
          : e.expenseId != null
          ? () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExpenseDetailScreen(expenseId: e.expenseId!),
              ),
            )
          : null,
      onLongPress: approving ? () => _pick(e) : null,
      onEdit: editing ? () => _edit(e) : null,
      onValidate: approving ? () => _validate(e) : null,
      onFinalise: finalising ? () => _finalise(e) : null,
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
