import 'package:flutter/material.dart';

import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/member.dart';
import 'ui.dart';

/// Bottom sheet to pick one member, with search.
Future<MemberSummary?> pickMember(BuildContext context) {
  return showModalBottomSheet<MemberSummary>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (context, scroll) => _Picker(scroll: scroll),
    ),
  );
}

class _Picker extends StatefulWidget {
  const _Picker({required this.scroll});
  final ScrollController scroll;

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
