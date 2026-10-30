import 'package:flutter/material.dart';

import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/announcement.dart';
import '../models/member.dart';
import '../theme/tokens.dart';
import 'errors.dart';
import 'ui.dart';

/// Bottom sheet to pick one member, with search. [activeOnly] leaves out
/// members on leave, retired or suspended (a chef de groupe must be active).
Future<MemberSummary?> pickMember(
  BuildContext context, {
  bool activeOnly = false,
}) {
  return showModalBottomSheet<MemberSummary>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (context, scroll) =>
          _Picker(scroll: scroll, activeOnly: activeOnly),
    ),
  );
}

class _Picker extends StatefulWidget {
  const _Picker({required this.scroll, this.activeOnly = false});
  final ScrollController scroll;
  final bool activeOnly;

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  List<MemberSummary>? _all;
  String _q = '';

  @override
  void initState() {
    super.initState();
    RepositoryLocator.instance.members
        .list()
        .then((p) {
          if (mounted) setState(() => _all = p.members);
        })
        .catchError((_) {
          if (mounted) setState(() => _all = const []);
        });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final shown = (_all ?? const <MemberSummary>[])
        .where((m) => !widget.activeOnly || m.status == 'actif')
        .where((m) => m.fullName.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    return ListView(
      controller: widget.scroll,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(l.chooseMember, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          key: const Key('picker-search'),
          autofocus: false,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l.membersSearchHint,
          ),
          onChanged: (v) => setState(() => _q = v),
        ),
        const SizedBox(height: 12),
        if (_all == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          GroupCard(
            children: [
              for (final m in shown)
                ListRow(
                  key: Key('pick-member-${m.id}'),
                  lead: MemberAvatar(
                    name: m.fullName,
                    status: m.status,
                    diaspora: m.isDiaspora,
                    size: 36,
                  ),
                  title: Text(m.fullName),
                  onTap: () => Navigator.of(context).pop(m),
                ),
            ],
          ),
      ],
    );
  }
}

/// "Qui notifier ?": tick the members an announcement is for (owner,
/// 2026-10-29). Returns the new choice, or null when dismissed; an empty
/// list means everyone.
Future<List<Recipient>?> pickRecipients(
  BuildContext context, {
  List<int> selected = const [],
}) {
  return showModalBottomSheet<List<Recipient>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (context, scroll) =>
          _RecipientPicker(scroll: scroll, selected: selected.toSet()),
    ),
  );
}

class _RecipientPicker extends StatefulWidget {
  const _RecipientPicker({required this.scroll, required this.selected});
  final ScrollController scroll;
  final Set<int> selected;

  @override
  State<_RecipientPicker> createState() => _RecipientPickerState();
}

class _RecipientPickerState extends State<_RecipientPicker> {
  List<Recipient>? _all;
  Object? _error;
  String _q = '';
  late final Set<int> _on = {...widget.selected};

  @override
  void initState() {
    super.initState();
    RepositoryLocator.instance.announcements
        .recipients()
        .then((r) {
          if (mounted) setState(() => _all = r);
        })
        .catchError((Object e) {
          if (mounted) setState(() => _error = e);
        });
  }

  /// Accents ignored, so "esso" finds "Éssomba".
  static String _fold(String s) {
    const from = 'àâäáãçéèêëíìîïñóòôöõúùûüýÿœ';
    const to = 'aaaaaceeeeiiiinooooouuuuyyo';
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = from.indexOf(ch);
      b.write(i < 0 ? ch : to[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final all = _all ?? const <Recipient>[];
    final shown = all.where((r) => _fold(r.name).contains(_fold(_q))).toList();
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: widget.scroll,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                l.chooseRecipients,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                l.chooseRecipientsHint,
                style: TextStyle(fontSize: 14, color: c.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('recipients-search'),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l.searchName,
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Text(
                  describeError(context, _error!),
                  style: TextStyle(color: c.alert),
                )
              else if (_all == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                GroupCard(
                  children: [
                    for (final r in shown)
                      ListRow(
                        key: Key('recipient-${r.id}'),
                        lead: MemberAvatar(
                          name: r.name,
                          status: r.status,
                          size: 36,
                        ),
                        title: Text(r.name),
                        subtitle: r.status == 'conge'
                            ? Text(l.statusLeave)
                            : null,
                        trailing: Checkbox(
                          value: _on.contains(r.id),
                          onChanged: (_) => _toggle(r.id),
                        ),
                        onTap: () => _toggle(r.id),
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
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('recipients-everyone'),
                    onPressed: () =>
                        Navigator.of(context).pop(const <Recipient>[]),
                    child: Text(l.notifyEveryone),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('recipients-done'),
                    onPressed: _all == null
                        ? null
                        : () => Navigator.of(context).pop([
                            for (final r in all)
                              if (_on.contains(r.id)) r,
                          ]),
                    child: Text(l.doneCount(_on.length)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _toggle(int id) =>
      setState(() => _on.contains(id) ? _on.remove(id) : _on.add(id));
}

/// Tick several members, with "Tout cocher" (owner, 2026-10-30: finances).
/// Returns the ticked members in list order, or null when dismissed.
Future<List<MemberSummary>?> pickMembers(
  BuildContext context, {
  List<int> selected = const [],
}) {
  return showModalBottomSheet<List<MemberSummary>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (context, scroll) =>
          _MultiPicker(scroll: scroll, selected: selected.toSet()),
    ),
  );
}

class _MultiPicker extends StatefulWidget {
  const _MultiPicker({required this.scroll, required this.selected});
  final ScrollController scroll;
  final Set<int> selected;

  @override
  State<_MultiPicker> createState() => _MultiPickerState();
}

class _MultiPickerState extends State<_MultiPicker> {
  List<MemberSummary>? _all;
  Object? _error;
  String _q = '';
  late final Set<int> _on = {...widget.selected};

  @override
  void initState() {
    super.initState();
    RepositoryLocator.instance.members
        .list()
        .then((p) {
          if (mounted) setState(() => _all = p.members);
        })
        .catchError((Object e) {
          if (mounted) setState(() => _error = e);
        });
  }

  void _toggle(int id) =>
      setState(() => _on.contains(id) ? _on.remove(id) : _on.add(id));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final all = _all ?? const <MemberSummary>[];
    final q = _RecipientPickerState._fold(_q);
    final shown = all
        .where((m) => _RecipientPickerState._fold(m.fullName).contains(q))
        .toList();
    // "Tout cocher" works on what the search shows.
    final allOn = shown.isNotEmpty && shown.every((m) => _on.contains(m.id));
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: widget.scroll,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                l.chooseMembers,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('members-search'),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l.searchName,
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Text(
                  describeError(context, _error!),
                  style: TextStyle(color: c.alert),
                )
              else if (_all == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                GroupCard(
                  children: [
                    ListRow(
                      key: const Key('check-all'),
                      title: Text(
                        l.checkAll,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      trailing: Checkbox(
                        key: const Key('check-all-box'),
                        value: allOn,
                        onChanged: shown.isEmpty
                            ? null
                            : (_) => setState(
                                () => allOn
                                    ? _on.removeAll(shown.map((m) => m.id))
                                    : _on.addAll(shown.map((m) => m.id)),
                              ),
                      ),
                      onTap: shown.isEmpty
                          ? null
                          : () => setState(
                              () => allOn
                                  ? _on.removeAll(shown.map((m) => m.id))
                                  : _on.addAll(shown.map((m) => m.id)),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GroupCard(
                  children: [
                    for (final m in shown)
                      ListRow(
                        key: Key('pick-many-${m.id}'),
                        lead: MemberAvatar(
                          name: m.fullName,
                          status: m.status,
                          diaspora: m.isDiaspora,
                          size: 36,
                        ),
                        title: Text(m.fullName),
                        trailing: Checkbox(
                          value: _on.contains(m.id),
                          onChanged: (_) => _toggle(m.id),
                        ),
                        onTap: () => _toggle(m.id),
                      ),
                  ],
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
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('members-done'),
                onPressed: _all == null
                    ? null
                    : () => Navigator.of(context).pop([
                        for (final m in all)
                          if (_on.contains(m.id)) m,
                      ]),
                child: Text(l.doneCount(_on.length)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
