import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/expense.dart';
import '../../models/me.dart';
import '../../theme/tokens.dart';
import '../../widgets/dates.dart';
import '../../widgets/errors.dart';
import '../../widgets/files.dart';
import '../../widgets/member_picker.dart';
import '../../widgets/money.dart';
import '../../widgets/notice.dart';
import '../../widgets/ui.dart';

/// Expense requests (owner, 2026-10-30), open to every member: "À traiter"
/// (waiting for me), "Mes demandes", and "Toutes" for the finance team.
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key, required this.me});
  final Me me;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  int _tab = 0;
  Key _reload = UniqueKey();

  List<String> get _boxes => [
    'todo',
    'mine',
    if (widget.me.can('finances.expenses', 'view')) 'all',
  ];

  Future<void> _new() async {
    final made = await Navigator.of(context).push<ExpenseRequest>(
      MaterialPageRoute(builder: (_) => const NewExpenseScreen()),
    );
    if (made != null && mounted) {
      setState(() {
        _tab = 1;
        _reload = UniqueKey();
      });
      await _open(made.id);
    }
  }

  Future<void> _open(int id) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expenseId: id)),
    );
    if (mounted) setState(() => _reload = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final labels = [l.expTodo, l.expMine, if (_boxes.length > 2) l.expAll];
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('new-expense'),
        onPressed: _new,
        icon: const Icon(Icons.add),
        label: Text(l.expNew),
        backgroundColor: c.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.expensesTitle, back: true, small: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Seg2(
                options: labels,
                selected: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            Expanded(
              child: AsyncView<List<ExpenseRequest>>(
                key: ValueKey((_reload, _tab)),
                load: () =>
                    RepositoryLocator.instance.finances.expenses(_boxes[_tab]),
                builder: (context, items, reload) => RefreshIndicator(
                  onRefresh: reload,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      if (items.isEmpty)
                        EmptyState(
                          icon: Icons.request_quote_outlined,
                          title: _tab == 0 ? l.expNothingTodo : l.expNone,
                        )
                      else
                        GroupCard(
                          children: [
                            for (final r in items)
                              ExpenseRow(request: r, onTap: () => _open(r.id)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String expenseStatusLabel(AppLocalizations l, String s) => switch (s) {
  'submitted' => l.expStatusSubmitted,
  'approved' => l.expStatusApproved,
  'to_pay' => l.expStatusToPay,
  'paid' => l.expStatusPaid,
  'refused' => l.expStatusRefused,
  'cancelled' => l.expStatusCancelled,
  _ => s,
};

Tone expenseStatusTone(String s) => switch (s) {
  'paid' => Tone.green,
  'refused' => Tone.red,
  'cancelled' => Tone.neutral,
  _ => Tone.amber,
};

class ExpenseRow extends StatelessWidget {
  const ExpenseRow({super.key, required this.request, this.onTap});
  final ExpenseRequest request;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = Dates(context);
    final r = request;
    return ListRow(
      key: Key('expense-${r.id}'),
      onTap: onTap,
      lead: const IconChip(Icons.request_quote_outlined, tone: Tone.neutral),
      title: Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${r.domainName} · ${r.requesterName} · ${d.dayMonth(r.createdAt)}',
          ),
          const SizedBox(height: 4),
          Badge2(
            expenseStatusLabel(l, r.status),
            tone: expenseStatusTone(r.status),
          ),
        ],
      ),
      trailing: Amount(r.paidAmount ?? r.amount),
      chevron: true,
    );
  }
}

/// A new request; with [replacing], the cancelled request it redoes (the
/// exact amount this time; the cancelled one stays on record).
class NewExpenseScreen extends StatefulWidget {
  const NewExpenseScreen({super.key, this.replacing});
  final ExpenseRequest? replacing;

  @override
  State<NewExpenseScreen> createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends State<NewExpenseScreen> {
  late final _title = TextEditingController(text: widget.replacing?.title);
  late final _description = TextEditingController(
    text: widget.replacing?.description,
  );
  final _amount = TextEditingController();
  List<ExpenseDomain> _domains = const [];
  ExpenseDomain? _domain;
  List<(int, String)> _tagged = [];
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    RepositoryLocator.instance.finances
        .expenseDomains()
        .then((ds) {
          if (!mounted) return;
          setState(() {
            _domains = ds;
            final want = widget.replacing?.domainId;
            _domain = ds.where((d) => d.id == want).firstOrNull;
          });
        })
        .catchError((Object e) {
          if (mounted) showErrorSnack(context, e);
        });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _tag() async {
    final ms = await pickMembers(
      context,
      selected: [for (final t in _tagged) t.$1],
    );
    if (ms != null && mounted) {
      setState(() => _tagged = [for (final m in ms) (m.id, m.fullName)]);
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final amount =
        int.tryParse(_amount.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    final error = _domain == null
        ? l.expDomainRequired
        : _title.text.trim().isEmpty
        ? l.expTitleRequired
        : amount <= 0
        ? l.amountRequired
        : null;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final made = await RepositoryLocator.instance.finances.newExpense(
        domainId: _domain!.id,
        title: _title.text.trim(),
        amount: amount,
        description: _description.text.trim(),
        tagged: [for (final t in _tagged) t.$1],
        replaces: widget.replacing?.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.expSent)));
      Navigator.of(context).pop(made);
    } catch (e) {
      if (mounted) setState(() => _error = describeError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.expNew, back: true, small: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (widget.replacing != null)
                    Notice(
                      key: const Key('exp-replaces'),
                      text: l.expReplaces(widget.replacing!.id),
                    ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ExpenseDomain>(
                    key: const Key('exp-domain'),
                    initialValue: _domain,
                    decoration: InputDecoration(labelText: l.expDomain),
                    items: [
                      for (final d in _domains)
                        DropdownMenuItem(value: d, child: Text(d.name)),
                    ],
                    onChanged: (d) => setState(() => _domain = d),
                  ),
                  if (_domain != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        _domain!.leadRole == null
                            ? l.expNoLeadHint
                            : l.expLeadHint(_domain!.leadRole!),
                        style: TextStyle(fontSize: 13, color: c.textSecondary),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('exp-title'),
                    controller: _title,
                    maxLength: 140,
                    decoration: InputDecoration(labelText: l.expTitle),
                  ),
                  TextField(
                    key: const Key('exp-amount'),
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l.expAmount,
                      suffixText: 'FCFA',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('exp-description'),
                    controller: _description,
                    maxLines: 3,
                    maxLength: 1000,
                    decoration: InputDecoration(labelText: l.expDescription),
                  ),
                  ListRow(
                    key: const Key('exp-tag'),
                    lead: const IconChip(
                      Icons.alternate_email,
                      tone: Tone.neutral,
                    ),
                    title: Text(l.expTagCoordinators),
                    subtitle: Text(
                      _tagged.isEmpty
                          ? l.expTagHint
                          : _tagged.map((t) => t.$2).join(', '),
                    ),
                    chevron: true,
                    onTap: _tag,
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _error!,
                        key: const Key('exp-error'),
                        style: TextStyle(color: c.alert),
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('exp-send'),
                    onPressed: _busy ? null : _save,
                    child: Text(l.expSend),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One request: its steps, what the viewer may do, and the thread.
class ExpenseDetailScreen extends StatefulWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});
  final int expenseId;

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  ExpenseRequest? _r;
  Object? _loadError;
  final _message = TextEditingController();
  PickedFile? _file;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await RepositoryLocator.instance.finances.expense(
        widget.expenseId,
      );
      if (mounted) setState(() => _r = r);
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  Future<void> _run(Future<ExpenseRequest> Function() call, String done) async {
    setState(() => _busy = true);
    try {
      final r = await call();
      if (!mounted) return;
      setState(() => _r = r);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _step(String step, bool approve) async {
    final l = AppLocalizations.of(context);
    var note = '';
    if (!approve || step == 'cancel') {
      final why = await showDialog<String>(
        context: context,
        builder: (_) => _ReasonDialog(
          title: step == 'cancel' ? l.expCancelTitle : l.expRefuseTitle,
        ),
      );
      if (why == null || !mounted) return;
      note = why;
    }
    await _run(
      () => RepositoryLocator.instance.finances.expenseStep(
        widget.expenseId,
        step,
        approve: approve,
        note: note,
      ),
      step == 'cancel'
          ? l.expCancelled
          : approve
          ? l.expApproved
          : l.expRefused,
    );
  }

  Future<void> _pay() async {
    final l = AppLocalizations.of(context);
    final paid = await Navigator.of(context).push<ExpenseRequest>(
      MaterialPageRoute(builder: (_) => PayExpenseScreen(request: _r!)),
    );
    if (paid != null && mounted) {
      setState(() => _r = paid);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.expPaid)));
    }
  }

  Future<void> _resubmit() async {
    final made = await Navigator.of(context).push<ExpenseRequest>(
      MaterialPageRoute(builder: (_) => NewExpenseScreen(replacing: _r)),
    );
    if (made != null && mounted) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ExpenseDetailScreen(expenseId: made.id),
        ),
      );
    }
  }

  Future<void> _attach() async {
    final f = await pickProof(context);
    if (f != null && mounted) setState(() => _file = f);
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context);
    final body = _message.text.trim();
    if (body.isEmpty && _file == null) return;
    final file = _file;
    await _run(
      () => RepositoryLocator.instance.finances.expenseMessage(
        widget.expenseId,
        body: body,
        file: file,
      ),
      l.expMessageSent,
    );
    if (mounted && !_busy) {
      _message.clear();
      setState(() => _file = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = _r;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.expDetailTitle, back: true, small: true),
            Expanded(
              child: r == null
                  ? Center(
                      child: _loadError != null
                          ? Text(describeError(context, _loadError!))
                          : const CircularProgressIndicator(),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        children: [
                          _Summary(request: r),
                          const SizedBox(height: 16),
                          _Steps(request: r),
                          const SizedBox(height: 16),
                          _actions(l, r),
                          SectionLabel(l.expThread),
                          const SizedBox(height: 8),
                          for (final m in r.messages) _Message(message: m),
                        ],
                      ),
                    ),
            ),
            if (r != null) _composer(l),
          ],
        ),
      ),
    );
  }

  Widget _actions(AppLocalizations l, ExpenseRequest r) {
    final a = r.actions;
    final buttons = <Widget>[
      if (a.contains('decide') || a.contains('audit')) ...[
        FilledButton.icon(
          key: const Key('exp-approve'),
          onPressed: _busy
              ? null
              : () => _step(a.contains('decide') ? 'decide' : 'review', true),
          icon: const Icon(Icons.check),
          label: Text(l.expApprove),
        ),
        OutlinedButton.icon(
          key: const Key('exp-refuse'),
          onPressed: _busy
              ? null
              : () => _step(a.contains('decide') ? 'decide' : 'review', false),
          icon: const Icon(Icons.close),
          label: Text(l.expRefuse),
        ),
      ],
      if (a.contains('pay'))
        FilledButton.icon(
          key: const Key('exp-pay'),
          onPressed: _busy ? null : _pay,
          icon: const Icon(Icons.payments_outlined),
          label: Text(l.expPayAction),
        ),
      if (a.contains('cancel'))
        OutlinedButton(
          key: const Key('exp-cancel'),
          onPressed: _busy ? null : () => _step('cancel', false),
          child: Text(l.expCancelAction),
        ),
      if (a.contains('resubmit'))
        FilledButton.icon(
          key: const Key('exp-resubmit'),
          onPressed: _busy ? null : _resubmit,
          icon: const Icon(Icons.replay),
          label: Text(l.expResubmit),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(spacing: 8, runSpacing: 8, children: buttons),
    );
  }

  Widget _composer(AppLocalizations l) {
    final c = context.msg;
    return Material(
      color: c.surfaceCard,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_file != null)
              Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.attach_file, size: 16),
                  Expanded(
                    child: Text(
                      _file!.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: l.cancel,
                    onPressed: () => setState(() => _file = null),
                  ),
                ],
              ),
            Row(
              children: [
                IconButton(
                  key: const Key('exp-attach'),
                  tooltip: l.expAttach,
                  icon: const Icon(Icons.attach_file),
                  onPressed: _busy ? null : _attach,
                ),
                Expanded(
                  child: TextField(
                    key: const Key('exp-message'),
                    controller: _message,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: l.expMessageHint,
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('exp-send-message'),
                  tooltip: l.expSendMessage,
                  icon: Icon(Icons.send, color: c.primary),
                  onPressed: _busy ? null : _send,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.request});
  final ExpenseRequest request;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final d = Dates(context);
    final r = request;
    return GroupCard(
      padding: const EdgeInsets.all(16),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Badge2(
              expenseStatusLabel(l, r.status),
              key: const Key('exp-status'),
              tone: expenseStatusTone(r.status),
            ),
            const SizedBox(height: 8),
            Text(r.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Amount(r.amount, size: 24, weight: FontWeight.w800),
            if (r.paidAmount != null)
              Text(
                l.expPaidAmount(fcfa(r.paidAmount!)),
                style: TextStyle(color: c.primaryText),
              ),
            const SizedBox(height: 8),
            Text(
              '${r.domainName} · ${l.expAskedBy(r.requesterName)} · '
              '${d.dayMonth(r.createdAt)}',
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
            if (r.taggedNames.isNotEmpty)
              Text(
                l.expTagged(r.taggedNames.join(', ')),
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
            if (r.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(r.description),
            ],
            if (r.closeReason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l.expReason(r.closeReason),
                style: TextStyle(color: c.alert),
              ),
            ],
            if (r.replaces != null)
              Text(
                l.expReplaces(r.replaces!),
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
            if (r.replacedBy != null)
              Text(
                l.expReplacedBy(r.replacedBy!),
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
          ],
        ),
      ],
    );
  }
}

/// Demande → responsable → commissaire → paiement.
class _Steps extends StatelessWidget {
  const _Steps({required this.request});
  final ExpenseRequest request;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final r = request;
    // The step it waits at: the lead (1), the commissaire (2), payment (3);
    // 4 = paid. A refused or cancelled one shows who acted.
    final at = const {
      'submitted': 1,
      'approved': 2,
      'to_pay': 3,
      'paid': 4,
    }[r.status];
    final steps = [
      (l.expStepAsked, r.requesterName),
      (l.expStepLead, r.leadByName),
      (l.expStepAuditor, r.auditByName),
      (l.expStepPaid, r.paidByName),
    ];
    bool done(int i, String? who) =>
        i == 0 || (at != null ? i < at : who != null);
    return GroupCard(
      children: [
        for (final (i, (label, who)) in steps.indexed)
          ListRow(
            key: Key('exp-step-$i'),
            lead: Icon(
              done(i, who)
                  ? Icons.check_circle
                  : r.open && i == at
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: done(i, who)
                  ? c.primary
                  : r.open && i == at
                  ? c.warnText
                  : c.textTertiary,
            ),
            title: Text(label),
            subtitle: who == null ? null : Text(who),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message});
  final ExpenseMessage message;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final d = Dates(context);
    final m = message;
    final meta =
        '${m.authorName ?? ''} · ${d.dayMonth(m.createdAt)}, ${d.time(m.createdAt)}';
    if (m.kind == 'step') {
      return Padding(
        key: Key('exp-msg-${m.id}'),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          '${m.body} — $meta',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: c.textSecondary),
        ),
      );
    }
    return Container(
      key: Key('exp-msg-${m.id}'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: m.kind == 'proof' ? c.primaryTint : c.surfaceCard,
        borderRadius: BorderRadius.circular(MsgRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (m.kind == 'proof')
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Badge2(l.expProof, tone: Tone.green),
            ),
          Text(meta, style: TextStyle(fontSize: 12, color: c.textSecondary)),
          if (m.body.isNotEmpty) ...[const SizedBox(height: 4), Text(m.body)],
          if (m.fileUrl != null) ...[
            const SizedBox(height: 8),
            if (m.isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(MsgRadius.sm),
                child: Image.network(
                  m.fileUrl!,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            TextButton.icon(
              key: Key('exp-file-${m.id}'),
              onPressed: () => openDocument(
                context,
                source: 'expense-${m.id}',
                name: m.fileName,
                mime: m.contentType,
                link: () async => m.fileUrl!,
              ),
              icon: Icon(
                m.isImage ? Icons.image_outlined : Icons.picture_as_pdf,
              ),
              label: Text(m.fileName, overflow: TextOverflow.ellipsis),
            ),
          ],
        ],
      ),
    );
  }
}

/// The trésorier pays: amount (at most the approved one), the transaction's
/// screenshot (required), a note.
class PayExpenseScreen extends StatefulWidget {
  const PayExpenseScreen({super.key, required this.request});
  final ExpenseRequest request;

  @override
  State<PayExpenseScreen> createState() => _PayExpenseScreenState();
}

class _PayExpenseScreenState extends State<PayExpenseScreen> {
  late final _amount = TextEditingController(text: '${widget.request.amount}');
  final _note = TextEditingController();
  PickedFile? _proof;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final f = await pickProof(context);
    if (f != null && mounted) {
      setState(() {
        _proof = f;
        _error = null;
      });
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final amount =
        int.tryParse(_amount.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    final error = amount <= 0 || amount > widget.request.amount
        ? l.expAmountMax(fcfa(widget.request.amount))
        : _proof == null
        ? l.expProofRequired
        : null;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await RepositoryLocator.instance.finances.payExpense(
        widget.request.id,
        amount: amount,
        proof: _proof!,
        note: _note.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(r);
    } catch (e) {
      if (mounted) setState(() => _error = describeError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final r = widget.request;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.expPayTitle, back: true, small: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(
                    '${r.title} · ${r.requesterName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.expApprovedAmount(fcfa(r.amount)),
                    style: TextStyle(color: c.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('pay-amount'),
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l.expAmountPaid,
                      suffixText: 'FCFA',
                      helperText: l.expAmountMaxHint,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    key: const Key('pay-proof'),
                    onPressed: _busy ? null : _pick,
                    icon: Icon(
                      _proof == null ? Icons.add_photo_alternate : Icons.check,
                    ),
                    label: Text(_proof?.name ?? l.expAddProof),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('pay-note'),
                    controller: _note,
                    decoration: InputDecoration(labelText: l.expPayNote),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.expPayCashbook,
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _error!,
                        key: const Key('pay-error'),
                        style: TextStyle(color: c.alert),
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('pay-save'),
                    onPressed: _busy ? null : _save,
                    child: Text(l.expPayConfirm),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An image (screenshot, photo) or a PDF, 10 MB at most.
Future<PickedFile?> pickProof(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final List<PlatformFile> picked;
  try {
    picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
  } catch (e) {
    if (context.mounted) showErrorSnack(context, e);
    return null;
  }
  if (picked.isEmpty) return null;
  final p = picked.first;
  if ((await p.length() ?? 0) > 10 * 1024 * 1024) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.fileTooLarge)));
    }
    return null;
  }
  return (name: p.name, bytes: await p.readAsBytes());
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title});
  final String title;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('exp-reason'),
        controller: _reason,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(labelText: l.expReasonLabel),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('exp-reason-ok'),
          onPressed: () {
            final why = _reason.text.trim();
            if (why.isNotEmpty) Navigator.of(context).pop(why);
          },
          child: Text(l.confirm),
        ),
      ],
    );
  }
}
