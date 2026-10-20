import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/finance.dart';
import '../../models/member.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/dates.dart';
import '../../widgets/errors.dart';
import '../../widgets/labels.dart';
import '../../widgets/member_picker.dart';
import '../../widgets/money.dart';
import '../../widgets/ui.dart';

/// "Nouvelle opération" (design): big amount with shortcuts to the official
/// amounts, category, member, date. Saved as "à valider".
class EntryFormScreen extends StatefulWidget {
  const EntryFormScreen({super.key});

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  static const _quick = [500, 1000, 2000, 2500];
  final _amount = TextEditingController();
  final _label = TextEditingController();
  int _direction = 0; // 0 in, 1 out
  String _category = 'solidarite';
  MemberSummary? _member;
  DateTime _date = DateTime.now();
  bool _busy = false;
  String? _amountError;
  // One key per form: a retry after a timeout is the same entry.
  final _draftUuid = uuidV4();

  @override
  void dispose() {
    _amount.dispose();
    _label.dispose();
    super.dispose();
  }

  int get _value =>
      int.tryParse(_amount.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (_value <= 0) {
      setState(() => _amountError = l.amountRequired);
      return;
    }
    setState(() {
      _busy = true;
      _amountError = null;
    });
    final out = _direction == 1;
    final category = out ? 'depense' : _category;
    try {
      final saved = await RepositoryLocator.instance.finances.createEntry(
        NewEntry(
          direction: out ? 'out' : 'in',
          amount: _value,
          category: category,
          label: _label.text.trim().isEmpty
              ? financeCategoryLabel(l, category)
              : _label.text.trim(),
          memberId: _member?.id,
          memberName: _member?.fullName,
          date: _date,
          clientUuid: _draftUuid,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saved.local ? l.savedOnPhone : l.entrySaved)),
      );
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
    final d = Dates(context);
    Widget label(String t) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        t,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.newEntry, back: true, small: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Seg2(
                    options: [l.directionIn, l.directionOut],
                    selected: _direction,
                    onChanged: (i) => setState(() => _direction = i),
                  ),
                  label(l.amount),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: c.surfaceCard,
                      borderRadius: BorderRadius.circular(MsgRadius.md),
                      border: Border.all(
                        color: _amountError != null ? c.alert : c.primary,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('e-amount'),
                            controller: _amount,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) =>
                                setState(() => _amountError = null),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              fontFeatures: tabular,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '0',
                            ),
                          ),
                        ),
                        Text(
                          'FCFA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_amountError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _amountError!,
                        style: TextStyle(
                          color: c.alert,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final q in _quick)
                        ChoiceChip(
                          key: Key('quick-$q'),
                          label: Text(groupDigits(q)),
                          selected: _value == q,
                          onSelected: (_) => setState(() {
                            _amount.text = '$q';
                            _amountError = null;
                          }),
                        ),
                    ],
                  ),
                  if (_direction == 0) ...[
                    label(l.category),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      key: const Key('e-category'),
                      initialValue: _category,
                      items: [
                        for (final k in incomeCategories)
                          DropdownMenuItem(
                            value: k,
                            child: Text(financeCategoryLabel(l, k)),
                          ),
                      ],
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                  ],
                  label(l.description),
                  TextField(
                    key: const Key('e-label'),
                    controller: _label,
                    decoration: InputDecoration(
                      hintText: _direction == 1
                          ? l.catExpense
                          : financeCategoryLabel(l, _category),
                    ),
                  ),
                  label(l.memberOptional),
                  GroupCard(
                    children: [
                      ListRow(
                        key: const Key('e-member'),
                        lead: const Icon(Icons.person_outline),
                        title: Text(_member?.fullName ?? l.chooseMember),
                        chevron: true,
                        onTap: () async {
                          final m = await pickMember(context);
                          if (m != null) setState(() => _member = m);
                        },
                      ),
                      ListRow(
                        lead: const Icon(Icons.calendar_today_outlined),
                        title: Text(d.fullDate(_date)),
                        onTap: () async {
                          final p = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (p != null) setState(() => _date = p);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: c.surfaceCard,
                border: Border(top: BorderSide(color: c.borderSubtle)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 14,
                        color: c.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l.willBeValidated,
                          style: TextStyle(
                            fontSize: 13,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const Key('e-save'),
                    onPressed: _busy ? null : _save,
                    child: Text(l.save),
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
