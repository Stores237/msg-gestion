import 'package:flutter/material.dart';

import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../../theme/tokens.dart';
import '../../widgets/dates.dart';
import '../../widgets/errors.dart';
import '../../widgets/labels.dart';
import '../../widgets/ui.dart';

/// "Nouvel événement" for roles allowed to create events.
class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key, required this.initialDay});
  final DateTime initialDay;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _place = TextEditingController();
  final _notes = TextEditingController();
  String _kind = 'assise';
  String _dress = 'interieure';
  late DateTime _day;
  TimeOfDay _start = const TimeOfDay(hour: 15, minute: 0);
  TimeOfDay? _end;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _day = widget.initialDay;
  }

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    _notes.dispose();
    super.dispose();
  }

  DateTime _at(TimeOfDay t) =>
      DateTime(_day.year, _day.month, _day.day, t.hour, t.minute);

  /// An end earlier than the start means the next morning (night vigils).
  DateTime? get _endsAt {
    if (_end == null) return null;
    final e = _at(_end!);
    return e.isAfter(_at(_start)) ? e : e.add(const Duration(days: 1));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final l = AppLocalizations.of(context);
    try {
      await RepositoryLocator.instance.events.create(
        CalendarEvent(
          id: 0,
          kind: _kind,
          title: _title.text.trim(),
          startsAt: _at(_start),
          endsAt: _endsAt,
          place: _place.text.trim(),
          dress: _dress,
          notes: _notes.text.trim(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.eventCreated)));
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
    InputDecoration deco({Widget? prefix}) => InputDecoration(
      prefixIcon: prefix,
      filled: true,
      fillColor: c.surfaceCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MsgRadius.md),
        borderSide: BorderSide(color: c.borderSubtle, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MsgRadius.md),
        borderSide: BorderSide(color: c.borderSubtle, width: 1.5),
      ),
    );
    Widget label(String t) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        t,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
    Widget picker(String text, IconData icon, VoidCallback onTap, {Key? key}) =>
        InkWell(
          key: key,
          onTap: onTap,
          child: InputDecorator(
            decoration: deco(prefix: Icon(icon)),
            child: Text(text, style: const TextStyle(fontSize: 16)),
          ),
        );
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.newEvent, back: true, small: true),
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    label(l.eventKind),
                    DropdownButtonFormField<String>(
                      initialValue: _kind,
                      decoration: deco(),
                      items: [
                        for (final k in eventKinds)
                          DropdownMenuItem(
                            value: k,
                            child: Text(eventKindLabel(l, k)),
                          ),
                      ],
                      onChanged: (v) => setState(() {
                        _kind = v!;
                        if (_title.text.isEmpty && v == 'assise') {
                          _title.text = l.kindAssise;
                        }
                      }),
                    ),
                    label(l.eventTitle),
                    TextFormField(
                      key: const Key('f-title'),
                      controller: _title,
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? l.required : null,
                      decoration: deco(),
                    ),
                    label(l.eventDate),
                    picker(
                      d.fullDate(_day),
                      Icons.calendar_today_outlined,
                      () async {
                        final p = await showDatePicker(
                          context: context,
                          initialDate: _day,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (p != null) setState(() => _day = p);
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              label(l.eventStart),
                              picker(
                                _start.format(context),
                                Icons.schedule,
                                () async {
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime: _start,
                                  );
                                  if (t != null) setState(() => _start = t);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              label(l.eventEnd),
                              picker(
                                _end?.format(context) ?? '—',
                                Icons.schedule,
                                () async {
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime: _end ?? _start,
                                  );
                                  setState(() => _end = t);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    label(l.eventPlace),
                    TextFormField(
                      controller: _place,
                      decoration: deco(
                        prefix: const Icon(Icons.place_outlined),
                      ),
                    ),
                    label(l.eventDress),
                    DropdownButtonFormField<String>(
                      initialValue: _dress,
                      decoration: deco(
                        prefix: const Icon(Icons.checkroom_outlined),
                      ),
                      items: [
                        for (final k in dressCodes)
                          DropdownMenuItem(
                            value: k,
                            child: Text(dressLabel(l, k)),
                          ),
                      ],
                      onChanged: (v) => setState(() => _dress = v!),
                    ),
                    label(l.eventNotes),
                    TextFormField(
                      controller: _notes,
                      maxLines: 4,
                      decoration: deco(),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: c.surfaceCard,
                border: Border(top: BorderSide(color: c.borderSubtle)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('save-event'),
                  onPressed: _busy ? null : _save,
                  child: _busy
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
