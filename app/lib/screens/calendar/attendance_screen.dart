import 'package:flutter/material.dart';

import '../../data/repositories/events_repository.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../../theme/tokens.dart';
import '../../widgets/errors.dart';
import '../../widgets/ui.dart';

/// Roll call (design: "Appel · présences"): three 44 dp buttons per row,
/// letter + colour + spoken label. Marks are kept locally and saved in one go.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, required this.event});
  final CalendarEvent event;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  AttendanceSheet? _sheet;
  Object? _error;
  final Map<int, String> _changes = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await RepositoryLocator.instance.events.attendance(
        widget.event.id,
      );
      if (mounted) setState(() => _sheet = s);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _mark(AttendanceRow row, String status) {
    setState(() {
      final next = row.status == status ? '' : status;
      row.status = next;
      _changes[row.member] = next;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final s = await RepositoryLocator.instance.events.saveAttendance(
        widget.event.id,
        Map.of(_changes),
      );
      if (!mounted) return;
      setState(() {
        _sheet = s;
        _changes.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).rollCallSaved)),
      );
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final rows = _sheet?.rows ?? const <AttendanceRow>[];
    int count(String s) => rows.where((r) => r.status == s).length;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: l.rollCallTitle(widget.event.title),
              back: true,
              small: true,
            ),
            Expanded(
              child: _sheet == null
                  ? (_error == null
                        ? const Center(child: CircularProgressIndicator())
                        : Center(
                            child: EmptyState(
                              icon: Icons.cloud_off_outlined,
                              error: true,
                              title: l.loadError,
                              text: describeError(context, _error!),
                              action: FilledButton(
                                onPressed: _load,
                                child: Text(l.retry),
                              ),
                            ),
                          ))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        GroupCard(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          children: [
                            Row(
                              children: [
                                for (final (n, label) in [
                                  (count('present'), l.statPresent),
                                  (count('absent'), l.statAbsent),
                                  (count('excuse'), l.statExcused),
                                  (count(''), l.statRemaining),
                                ])
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          '$n',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: c.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GroupCard(
                          children: [
                            for (final r in rows)
                              ListRow(
                                key: Key('att-${r.member}'),
                                lead: MemberAvatar(
                                  name: r.fullName,
                                  diaspora: r.isDiaspora,
                                  size: 36,
                                ),
                                title: Text(r.fullName),
                                subtitle: r.isDiaspora
                                    ? Text(l.remote)
                                    : (r.reason.isNotEmpty
                                          ? Text(r.reason)
                                          : null),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (final (key, letter, label, color) in [
                                      (
                                        'present',
                                        l.presencePresent.substring(0, 1),
                                        l.presencePresent,
                                        c.primary,
                                      ),
                                      (
                                        'absent',
                                        l.presenceAbsent.substring(0, 1),
                                        l.presenceAbsent,
                                        c.alert,
                                      ),
                                      (
                                        'excuse',
                                        l.presenceExcused.substring(0, 1),
                                        l.presenceExcused,
                                        c.warn,
                                      ),
                                    ])
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Semantics(
                                          button: true,
                                          selected: r.status == key,
                                          label: '$label, ${r.fullName}',
                                          child: InkWell(
                                            key: Key('att-${r.member}-$key'),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () => _mark(r, key),
                                            child: Container(
                                              width: 44,
                                              height: 44,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: r.status == key
                                                    ? color
                                                    : c.surfaceSunken,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: ExcludeSemantics(
                                                child: Text(
                                                  letter,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14,
                                                    color: r.status == key
                                                        ? Colors.white
                                                        : c.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
            ),
            if (_changes.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: c.surfaceCard,
                  border: Border(top: BorderSide(color: c.borderSubtle)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.unsavedChanges(_changes.length),
                      style: TextStyle(fontSize: 13, color: c.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      key: const Key('save-attendance'),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(l.save),
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
