import 'package:flutter/material.dart';

import '../data/repositories/profile_repository.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import '../widgets/dates.dart';
import '../widgets/errors.dart';
import '../widgets/group_logo.dart';
import '../widgets/money.dart';
import '../widgets/ui.dart';

String sharingKindLabel(AppLocalizations l, String kind) => switch (kind) {
  'members' => l.groupNetKindMembers,
  'finances' => l.groupNetKindFinances,
  'calendar' => l.groupNetKindCalendar,
  'announcements' => l.groupNetKindAnnouncements,
  'reports' => l.groupNetKindReports,
  _ => kind,
};

String sharingLevelLabel(AppLocalizations l, String level) => switch (level) {
  'summary' => l.groupNetLevelSummary,
  'detail' => l.groupNetLevelDetail,
  _ => l.groupNetLevelNone,
};

String _kindHint(AppLocalizations l, String kind) => switch (kind) {
  'members' => l.groupNetHintMembers,
  'finances' => l.groupNetHintFinances,
  'calendar' => l.groupNetHintCalendar,
  'announcements' => l.groupNetHintAnnouncements,
  'reports' => l.groupNetHintReports,
  _ => '',
};

/// "Ce que nous partageons" (owner, 2026-11-03): kind by kind, what the
/// groups above may see. Nothing until the président chooses; others read.
class SharingScreen extends StatefulWidget {
  const SharingScreen({super.key});

  @override
  State<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  SharingSettings? _s;
  Map<String, String> _values = {};
  Object? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    RepositoryLocator.instance.profile
        .sharing()
        .then((s) {
          if (mounted) {
            setState(() {
              _s = s;
              _values = {...s.values};
            });
          }
        })
        .catchError((Object e) {
          if (mounted) setState(() => _error = e);
        });
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await RepositoryLocator.instance.profile.saveSharing(_values);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.groupNetSharingSaved)));
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
    final s = _s;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: l.groupNetSharingTitle,
              back: true,
              small: true,
            ),
            Expanded(
              child: s == null
                  ? Center(
                      child: _error == null
                          ? const CircularProgressIndicator()
                          : Text(describeError(context, _error!)),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        Text(
                          l.groupNetSharingAbout,
                          style: TextStyle(height: 1.5, color: c.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        for (final kind in SharingSettings.kinds)
                          if (s.options[kind] case final options?) ...[
                            Text(
                              sharingKindLabel(l, kind),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _kindHint(l, kind),
                              style: TextStyle(
                                fontSize: 13,
                                color: c.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<String>(
                              key: Key('share-$kind'),
                              showSelectedIcon: false,
                              segments: [
                                for (final o in options)
                                  ButtonSegment(
                                    value: o,
                                    label: Text(
                                      sharingLevelLabel(l, o),
                                      key: Key('share-$kind-$o'),
                                    ),
                                  ),
                              ],
                              selected: {_values[kind] ?? 'none'},
                              onSelectionChanged: s.canManage
                                  ? (v) =>
                                        setState(() => _values[kind] = v.first)
                                  : null,
                            ),
                            const SizedBox(height: 20),
                          ],
                        Text(
                          l.groupNetNeverShared,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: c.textSecondary,
                          ),
                        ),
                        if (s.canManage) ...[
                          const SizedBox(height: 16),
                          FilledButton(
                            key: const Key('sharing-save'),
                            onPressed: _busy ? null : _save,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: const StadiumBorder(),
                            ),
                            child: Text(l.save),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A group below, as it shares itself (owner, 2026-11-03). A kind the
/// viewer's role up here doesn't cover says so instead of showing it.
class SharedGroupScreen extends StatelessWidget {
  const SharedGroupScreen({super.key, required this.groupId});
  final int groupId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.groupNetTitle, back: true, small: true),
            Expanded(
              child: AsyncView<SharedGroup>(
                load: () =>
                    RepositoryLocator.instance.profile.sharedGroup(groupId),
                builder: (context, g, reload) => ListView(
                  key: const Key('shared-group'),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Row(
                      children: [
                        GroupLogo(group: g.group, size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.group.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                [
                                  g.levelName,
                                  ?g.parent,
                                ].where((s) => s.isNotEmpty).join(' · '),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (g.shared.isEmpty)
                      EmptyState(
                        icon: Icons.visibility_off_outlined,
                        title: l.groupNetSharesNothing,
                        text: l.groupNetSharesNothingBody,
                      )
                    else
                      for (final kind in SharingSettings.kinds)
                        if (g.shared[kind] case final k?) ...[
                          SectionLabel(
                            '${sharingKindLabel(l, kind)} · ${sharingLevelLabel(l, k.level)}',
                          ),
                          const SizedBox(height: 8),
                          KeyedSubtree(
                            key: Key('shared-$kind'),
                            child: k.hidden || k.data == null
                                ? Text(
                                    l.groupNetNotYourRole,
                                    style: TextStyle(
                                      color: context.msg.textSecondary,
                                    ),
                                  )
                                : _SharedKindView(kind: kind, data: k.data!),
                          ),
                          const SizedBox(height: 24),
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

class _SharedKindView extends StatelessWidget {
  const _SharedKindView({required this.kind, required this.data});
  final String kind;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = Dates(context);
    final c = context.msg;
    Widget line(String a, String b) => ListRow(
      title: Text(a),
      trailing: Text(b, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
    String money(int n) =>
        '${n < 0 ? '− ' : ''}${groupDigits(n)} ${data['currency'] ?? Currency.code}';
    DateTime when(String s) => DateTime.parse(s).toLocal();
    switch (kind) {
      case 'members':
        final people = (data['people'] as List?) ?? const [];
        return GroupCard(
          children: [
            line(l.groupNetMembersActive, '${data['total']}'),
            for (final p in people)
              ListRow(
                title: Text(p['name'] as String),
                subtitle: (p['roles'] as List).isEmpty
                    ? null
                    : Text((p['roles'] as List).join(', ')),
              ),
          ],
        );
      case 'finances':
        final entries = (data['entries'] as List?) ?? const [];
        return GroupCard(
          children: [
            line(l.groupNetBalance, money(data['balance'] as int)),
            line(l.groupNetYearIn, money(data['year_in'] as int)),
            line(l.groupNetYearOut, money(data['year_out'] as int)),
            for (final e in entries)
              ListRow(
                title: Text(e['label'] as String),
                subtitle: Text(
                  '${d.shortDate(DateTime.parse(e['date'] as String))} · ${e['category']}',
                ),
                trailing: Text(
                  '${e['direction'] == 'out' ? '− ' : '+ '}${money(e['amount'] as int)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: e['direction'] == 'out' ? c.alert : null,
                  ),
                ),
              ),
          ],
        );
      case 'calendar':
        final events = (data['events'] as List?) ?? const [];
        return GroupCard(
          children: [
            line(l.groupNetUpcoming, '${data['upcoming']}'),
            for (final e in events)
              ListRow(
                title: Text(e['title'] as String),
                subtitle: Text(
                  [
                    d.fullDateTime(when(e['starts_at'] as String)),
                    e['place'] as String,
                  ].where((s) => s.isNotEmpty).join(' · '),
                ),
              ),
          ],
        );
      case 'announcements':
        final items = (data['items'] as List?) ?? const [];
        if (items.isEmpty) return Text(l.groupNetNoneYet);
        return GroupCard(
          children: [
            for (final a in items)
              ListRow(
                title: Text(a['title'] as String),
                subtitle: Text(
                  '${d.shortDate(when(a['created_at'] as String))} · ${a['body']}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        );
      case 'reports':
        final rows = (data['rows'] as List?) ?? const [];
        final rate = data['presence_rate'] as int?;
        return GroupCard(
          children: [
            line(l.groupNetEvents90, '${data['events']}'),
            line(l.groupNetPresenceRate, rate == null ? '—' : '$rate %'),
            for (final r in rows)
              ListRow(
                title: Text(r['title'] as String),
                subtitle: Text(
                  '${d.shortDate(when(r['date'] as String))} · ${l.groupNetAttendance(r['present'] as int, r['absent'] as int, r['excused'] as int)}',
                ),
                trailing: r['report'] == true
                    ? Badge2(l.groupNetReportIn, tone: Tone.green)
                    : null,
              ),
          ],
        );
    }
    return const SizedBox.shrink();
  }
}
