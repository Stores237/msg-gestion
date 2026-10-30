import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/repositories/profile_repository.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/finance.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/dates.dart';
import '../../widgets/errors.dart';
import '../../widgets/labels.dart';
import '../../widgets/member_picker.dart';
import '../../widgets/money.dart';
import '../../widgets/notice.dart';
import '../../widgets/ui.dart';

/// "Nouvelle opération" (design): big amount with shortcuts to the official
/// amounts, category, member, date. Saved as "à valider".
/// Owner, 2026-10-30: money in names at least one member, several can be
/// ticked ("Tout cocher": one line each, same amount); "Autre" needs a
/// description. With [editing], the trésorier corrects a line not yet
/// validated.
class EntryFormScreen extends StatefulWidget {
  const EntryFormScreen({super.key, this.editing});
  final FinanceEntry? editing;

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  List<int> _quick = AppSettings.fallback.quickAmounts;
  final _amount = TextEditingController();
  final _label = TextEditingController();
  int _direction = 0; // 0 in, 1 out
  String _category = 'solidarite';

  /// (id, name): the ticked members (money in), or the one concerned by a
  /// dépense (optional).
  List<(int, String)> _people = [];
  DateTime _date = DateTime.now();
  bool _busy = false;
  String? _amountError;
  String? _memberError;
  String? _labelError;

  FinanceEntry? get _editing => widget.editing;
  bool get _linked => _editing?.linked ?? false;
  // One key per form: a retry after a timeout is the same entry.
  final _draftUuid = uuidV4();

  @override
  void initState() {
    super.initState();
    final e = _editing;
    if (e != null) {
      _direction = e.isIn ? 0 : 1;
      if (e.isIn) _category = e.category;
      _amount.text = '${e.amount}';
      _label.text = e.label;
      _date = e.date;
      if (e.memberId != null) _people = [(e.memberId!, e.memberName ?? '')];
    }
    RepositoryLocator.instance.profile
        .settings()
        .then((st) {
          if (mounted) setState(() => _quick = st.quickAmounts);
        })
        .catchError((_) {});
  }

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
    final out = _direction == 1;
    final category = out ? 'depense' : _category;
    final text = _label.text.trim();
    setState(() {
      _amountError = _value <= 0 ? l.amountRequired : null;
      _memberError = !out && _people.isEmpty ? l.memberRequiredError : null;
      _labelError = category == 'autre' && text.isEmpty
          ? l.descriptionRequired
          : null;
    });
    if (_amountError != null || _memberError != null || _labelError != null) {
      return;
    }
    setState(() => _busy = true);
    final entry = NewEntry(
      direction: out ? 'out' : 'in',
      amount: _value,
      category: category,
      label: text.isEmpty ? financeCategoryLabel(l, category) : text,
      memberId: _people.isEmpty ? null : _people.first.$1,
      memberName: _people.isEmpty ? null : _people.first.$2,
      memberIds: [for (final p in _people) p.$1],
      memberNames: [for (final p in _people) p.$2],
      date: _date,
      clientUuid: _draftUuid,
    );
    try {
      final finances = RepositoryLocator.instance.finances;
      final String done;
      if (_editing != null) {
        await finances.editEntry(_editing!.id, entry);
        done = l.entryEdited;
      } else {
        final saved = await finances.createEntry(entry);
        done = saved.local ? l.savedOnPhone : l.entrySaved;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Money in: tick one or more members ("Tout cocher"); editing a line or
  /// a dépense: one member.
  Future<void> _choosePeople() async {
    if (_direction == 0 && _editing == null) {
      final ms = await pickMembers(
        context,
        selected: [for (final p in _people) p.$1],
      );
      if (ms == null) return;
      setState(() {
        _people = [for (final m in ms) (m.id, m.fullName)];
        _memberError = null;
      });
      return;
    }
    final m = await pickMember(context);
    if (m != null) {
      setState(() {
        _people = [(m.id, m.fullName)];
        _memberError = null;
      });
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
            ScreenHeader(
              title: _editing == null ? l.newEntry : l.editEntryTitle,
              back: true,
              small: true,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (_linked) ...[
                    Notice(key: const Key('e-linked'), text: l.linkedEntryNote),
                    const SizedBox(height: 12),
                  ],
                  IgnorePointer(
                    ignoring: _linked,
                    child: Seg2(
                      options: [l.directionIn, l.directionOut],
                      selected: _direction,
                      onChanged: (i) => setState(() {
                        _direction = i;
                        // A dépense names one member at most.
                        if (i == 1 && _people.length > 1) _people = [];
                        _memberError = null;
                      }),
                    ),
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
                      onChanged: _linked
                          ? null
                          : (v) => setState(() {
                              _category = v!;
                              _labelError = null;
                            }),
                    ),
                  ],
                  label(
                    _direction == 0 && _category == 'autre'
                        ? l.otherDescription
                        : l.description,
                  ),
                  TextField(
                    key: const Key('e-label'),
                    controller: _label,
                    onChanged: (_) {
                      if (_labelError != null) {
                        setState(() => _labelError = null);
                      }
                    },
                    decoration: InputDecoration(
                      errorText: _labelError,
                      hintText: _direction == 1
                          ? l.catExpense
                          : _category == 'autre'
                          ? null
                          : financeCategoryLabel(l, _category),
                    ),
                  ),
                  label(_direction == 0 ? l.membersLabel : l.memberOptional),
                  GroupCard(
                    children: [
                      ListRow(
                        key: const Key('e-member'),
                        lead: Icon(
                          _people.length > 1
                              ? Icons.groups_outlined
                              : Icons.person_outline,
                          color: _memberError != null ? c.alert : null,
                        ),
                        title: Text(switch (_people.length) {
                          0 when _direction == 0 => l.chooseMembers,
                          0 => l.chooseMember,
                          1 => _people.single.$2,
                          final n => l.membersChosen(n),
                        }),
                        subtitle: _people.length > 1
                            ? Text(
                                _people.map((p) => p.$2).join(', '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        chevron: !_linked,
                        onTap: _linked ? null : _choosePeople,
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
                  if (_memberError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _memberError!,
                        key: const Key('e-member-error'),
                        style: TextStyle(
                          color: c.alert,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (_people.length > 1) ...[
                    const SizedBox(height: 8),
                    Notice(
                      key: const Key('e-per-member'),
                      text:
                          '${l.perMemberTotal(_people.length, fcfa(_value), fcfa(_value * _people.length))}. ${l.perMemberHint}',
                    ),
                  ],
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
