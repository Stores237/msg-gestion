import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/current_user.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../../models/me.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/dates.dart';
import '../../widgets/errors.dart';
import '../../widgets/labels.dart';
import '../../widgets/ui.dart';
import 'attendance_screen.dart';

/// Event detail (design: "Détail d’un événement"): when, where, dress,
/// my attendance and "report an absence"; roll call for censors.
class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.eventId, required this.me});
  final int eventId;
  final Me me;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Key _reloadKey = UniqueKey();

  void _refresh() => setState(() => _reloadKey = UniqueKey());

  Future<void> _excuse(CalendarEvent e) async {
    final l = AppLocalizations.of(context);
    final reason = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
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
            Text(l.warnAbsence, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              key: const Key('absence-reason'),
              controller: reason,
              maxLength: 240,
              decoration: InputDecoration(labelText: l.absenceReason),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('send-absence'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await RepositoryLocator.instance.events.excuse(
        e.id,
        reason: reason.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.absenceSent)));
      _refresh();
    } on ApiException catch (err) {
      if (!mounted) return;
      if (err.code == 'already_marked') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.alreadyMarked)));
      } else {
        showErrorSnack(context, err);
      }
    } catch (err) {
      if (mounted) showErrorSnack(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: '', back: true, small: true),
            Expanded(
              child: AsyncView<CalendarEvent>(
                key: _reloadKey,
                load: () =>
                    RepositoryLocator.instance.events.get(widget.eventId),
                builder: (context, e, reload) {
                  final c = context.msg;
                  final d = Dates(context);
                  final overnight =
                      e.endsAt != null && e.endsAt!.day != e.startsAt.day;
                  final canRoll = widget.me.can(
                    'calendar.attendance',
                    'change',
                  );
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    children: [
                      Text(
                        eventKindLabel(l, e.kind, e.kindName).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: c.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GroupCard(
                        children: [
                          ListRow(
                            lead: const Icon(Icons.calendar_today_outlined),
                            title: Text(d.fullDate(e.startsAt)),
                            subtitle: Text(
                              e.endsAt == null
                                  ? d.time(e.startsAt)
                                  : overnight
                                  ? '${d.time(e.startsAt)} ${l.nightUntil('${d.dayMonth(e.endsAt!)} ${d.time(e.endsAt!)}')}'
                                  : '${d.time(e.startsAt)} → ${d.time(e.endsAt!)}',
                              style: const TextStyle(fontFeatures: tabular),
                            ),
                          ),
                          if (e.place.isNotEmpty)
                            ListRow(
                              lead: const Icon(Icons.place_outlined),
                              title: Text(e.place),
                            ),
                          if (e.dress.isNotEmpty)
                            ListRow(
                              lead: const Icon(Icons.checkroom_outlined),
                              title: Text(dressLabel(l, e.dress, e.dressName)),
                            ),
                          if (e.createdByName != null)
                            ListRow(
                              key: const Key('event-author'),
                              lead: const Icon(Icons.person_outline),
                              title: Text(l.addedBy),
                              subtitle: AuthorLine(
                                name: e.createdByName!,
                                role: e.createdByRole,
                              ),
                            ),
                        ],
                      ),
                      if (e.notes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          e.notes,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SectionLabel(l.myPresence),
                      const SizedBox(height: 8),
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
                                      presenceLabel(l, e.myAttendance ?? ''),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (e.myAttendance != null)
                                    Badge2(
                                      presenceLabel(l, e.myAttendance!),
                                      tone: switch (e.myAttendance) {
                                        'present' => Tone.green,
                                        'absent' => Tone.red,
                                        _ => Tone.amber,
                                      },
                                    ),
                                ],
                              ),
                              if (e.myAttendance == null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  l.presenceNotMarkedSub,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                              if (e.myAttendance == null &&
                                  e.startsAt.isAfter(
                                    DateTime.now().subtract(
                                      const Duration(hours: 1),
                                    ),
                                  )) ...[
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  key: const Key('warn-absence'),
                                  onPressed: () => _excuse(e),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    shape: const StadiumBorder(),
                                  ),
                                  child: Text(l.warnAbsence),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SectionLabel(l.reminders),
                      const SizedBox(height: 8),
                      const _Reminders(),
                      if (canRoll) ...[
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          key: const Key('roll-call'),
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AttendanceScreen(event: e),
                              ),
                            );
                            _refresh();
                          },
                          icon: const Icon(Icons.fact_check_outlined),
                          label: Text(l.takeRollCall),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Rappels" (design): the member's own reminder preferences, applied to
/// every event (the server sends them).
class _Reminders extends StatefulWidget {
  const _Reminders();

  @override
  State<_Reminders> createState() => _RemindersState();
}

class _RemindersState extends State<_Reminders> {
  late bool _eve = currentUser.value?.remindEve ?? true;
  late bool _twoHours = currentUser.value?.remind2h ?? false;

  Future<void> _set({bool? eve, bool? twoHours}) async {
    final before = (_eve, _twoHours);
    setState(() {
      _eve = eve ?? _eve;
      _twoHours = twoHours ?? _twoHours;
    });
    try {
      await RepositoryLocator.instance.profile.setReminders(
        eve: eve,
        twoHours: twoHours,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _eve = before.$1;
        _twoHours = before.$2;
      });
      showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GroupCard(
      children: [
        ListRow(
          title: Text(l.remindEve),
          trailing: Switch(
            key: const Key('remind-eve'),
            value: _eve,
            onChanged: (v) => _set(eve: v),
          ),
        ),
        ListRow(
          title: Text(l.remind2h),
          trailing: Switch(
            key: const Key('remind-2h'),
            value: _twoHours,
            onChanged: (v) => _set(twoHours: v),
          ),
        ),
      ],
    );
  }
}
