import 'package:flutter/material.dart';

import '../../data/repositories/profile_repository.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../../theme/tokens.dart';
import '../../widgets/dates.dart';
import '../../widgets/errors.dart';
import '../../widgets/labels.dart';
import '../../widgets/member_picker.dart';
import '../../widgets/ui.dart';

/// "Nouvel événement" for roles allowed to create events; with [existing],
/// "Modifier l’événement" (its author, or the calendar's managers).
/// Owner, 2026-10-27: "Autre" is named by the author; Messe says intérieur
/// or extérieur; a chef de groupe is designated (not for meetings).
class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key, required this.initialDay, this.existing});
  final DateTime initialDay;
  final CalendarEvent? existing;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _place = TextEditingController();
  final _placeDetail = TextEditingController();
  final _notes = TextEditingController();
  final _kindOther = TextEditingController();
  String _kind = 'assise';
  String _scope = '';
  (int, String)? _chef;
  bool _scopeMissing = false;
  bool _chefMissing = false;
  Set<String> _scoped = AppSettings.defaultScopedTypes;
  Set<String> _noChef = AppSettings.defaultTypesWithoutChef;
  String _dress = 'interieure';
  late DateTime _day;
  TimeOfDay _start = const TimeOfDay(hour: 15, minute: 0);
  TimeOfDay? _end;
  bool _busy = false;
  List<NamedItem> _kinds = AppSettings.defaultActivityTypes;
  List<NamedItem> _dresses = AppSettings.defaultDressCodes;

  @override
  void initState() {
    super.initState();
    _day = widget.initialDay;
    final e = widget.existing;
    if (e != null) {
      _kind = e.kind;
      _dress = e.dress;
      _title.text = e.title;
      _place.text = e.place;
      _placeDetail.text = e.placeDetail;
      _notes.text = e.notes;
      _kindOther.text = e.kindOther;
      _scope = e.scope;
      if (e.chefId != null) _chef = (e.chefId!, e.chefName ?? '');
      _day = DateUtils.dateOnly(e.startsAt);
      _start = TimeOfDay.fromDateTime(e.startsAt);
      if (e.endsAt != null) _end = TimeOfDay.fromDateTime(e.endsAt!);
    }
    // The group's own lists; the defaults until they arrive.
    RepositoryLocator.instance.profile
        .settings()
        .then((s) {
          if (!mounted) return;
          setState(() {
            if (s.activityTypes.isNotEmpty) _kinds = s.activityTypes;
            if (s.dressCodes.isNotEmpty) _dresses = s.dressCodes;
            _scoped = s.scopedTypes;
            _noChef = s.typesWithoutChef;
            if (!_kinds.any((k) => k.$1 == _kind)) _kind = _kinds.first.$1;
            if (_dress.isNotEmpty && !_dresses.any((d) => d.$1 == _dress)) {
              _dress = '';
            }
          });
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    _placeDetail.dispose();
    _notes.dispose();
    _kindOther.dispose();
    super.dispose();
  }

  bool get _hasScope => _scoped.contains(_kind);
  bool get _needsChef => !_noChef.contains(_kind);

  DateTime _at(TimeOfDay t) =>
      DateTime(_day.year, _day.month, _day.day, t.hour, t.minute);

  /// An end earlier than the start means the next morning (night vigils).
  DateTime? get _endsAt {
    if (_end == null) return null;
    final e = _at(_end!);
    return e.isAfter(_at(_start)) ? e : e.add(const Duration(days: 1));
  }

  Future<void> _save() async {
    final formOk = _form.currentState!.validate();
    setState(() {
      _scopeMissing = _hasScope && _scope.isEmpty;
      _chefMissing = _needsChef && _chef == null;
    });
    if (!formOk || _scopeMissing || _chefMissing) return;
    setState(() => _busy = true);
    final l = AppLocalizations.of(context);
    try {
      final draft = CalendarEvent(
        id: widget.existing?.id ?? 0,
        kind: _kind,
        title: _title.text.trim(),
        startsAt: _at(_start),
        endsAt: _endsAt,
        place: _place.text.trim(),
        placeDetail: _placeDetail.text.trim(),
        dress: _dress,
        notes: _notes.text.trim(),
        kindOther: _kind == 'autre' ? _kindOther.text.trim() : '',
        scope: _hasScope ? _scope : '',
        chefId: _needsChef ? _chef?.$1 : null,
      );
      final repo = RepositoryLocator.instance.events;
      if (widget.existing == null) {
        await repo.create(draft);
      } else {
        await repo.update(widget.existing!.id, draft);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existing == null ? l.eventCreated : l.eventUpdated,
          ),
        ),
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
            ScreenHeader(
              title: widget.existing == null ? l.newEvent : l.editEvent,
              back: true,
              small: true,
            ),
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    label(l.eventKind),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _kind,
                      decoration: deco(),
                      items: [
                        for (final (k, name) in _kinds)
                          DropdownMenuItem(
                            value: k,
                            child: Text(eventKindLabel(l, k, name)),
                          ),
                      ],
                      onChanged: (v) => setState(() {
                        _kind = v!;
                        if (_title.text.isEmpty && v == 'assise') {
                          _title.text = l.kindAssise;
                        }
                      }),
                    ),
                    if (_kind == 'autre') ...[
                      label(l.eventKindOther),
                      TextFormField(
                        key: const Key('f-kind-other'),
                        controller: _kindOther,
                        maxLength: 60,
                        validator: (v) =>
                            (v ?? '').trim().isEmpty ? l.required : null,
                        decoration: deco().copyWith(
                          hintText: l.eventKindOtherHint,
                        ),
                      ),
                    ],
                    if (_hasScope) ...[
                      label(l.eventScope),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final sc in const ['interieur', 'exterieur'])
                            ChoiceChip(
                              key: Key('f-scope-$sc'),
                              label: Text(scopeLabel(l, sc)),
                              selected: _scope == sc,
                              onSelected: (_) => setState(() {
                                _scope = sc;
                                _scopeMissing = false;
                              }),
                            ),
                        ],
                      ),
                      if (_scopeMissing)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            l.scopeRequired,
                            style: TextStyle(
                              fontSize: 13,
                              color: c.alert,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                    label(l.eventTitle),
                    TextFormField(
                      key: const Key('f-title'),
                      controller: _title,
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? l.required : null,
                      decoration: deco(),
                    ),
                    if (_needsChef) ...[
                      label(l.chefDeGroupe),
                      GroupCard(
                        children: [
                          ListRow(
                            key: const Key('f-chef'),
                            lead: const Icon(Icons.shield_outlined),
                            title: Text(_chef?.$2 ?? l.chooseChef),
                            chevron: true,
                            onTap: () async {
                              final m = await pickMember(
                                context,
                                activeOnly: true,
                              );
                              if (m != null) {
                                setState(() {
                                  _chef = (m.id, m.fullName);
                                  _chefMissing = false;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _chefMissing ? l.chefRequired : l.chefHelp,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: _chefMissing ? c.alert : c.textSecondary,
                            fontWeight: _chefMissing
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
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
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const Key('f-place-detail'),
                      controller: _placeDetail,
                      maxLength: 140,
                      decoration: deco().copyWith(
                        labelText: l.placeDetail,
                        hintText: l.placeDetailHint,
                        counterText: '',
                      ),
                    ),
                    label(l.eventDress),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _dress,
                      decoration: deco(
                        prefix: const Icon(Icons.checkroom_outlined),
                      ),
                      items: [
                        for (final (k, name) in [..._dresses, ('', '')])
                          DropdownMenuItem(
                            value: k,
                            child: Text(dressLabel(l, k, name)),
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
