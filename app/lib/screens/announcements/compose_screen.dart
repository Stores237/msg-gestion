import 'package:flutter/material.dart';

import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../../theme/tokens.dart';
import '../../widgets/dates.dart';
import '../../widgets/errors.dart';
import '../../widgets/ui.dart';

/// "Rédiger une annonce": announcement or convocation (linked to an
/// upcoming event), optionally pinned. Goes to every member.
class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  int _kind = 0; // 0 annonce, 1 convocation
  CalendarEvent? _event;
  bool _pinned = false;
  bool _busy = false;
  bool _eventMissing = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickEvent() async {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final List<CalendarEvent> events;
    try {
      events = await RepositoryLocator.instance.events.list(
        from: now,
        to: now.add(const Duration(days: 120)),
      );
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
      return;
    }
    if (!mounted) return;
    final d = Dates(context);
    final picked = await showModalBottomSheet<CalendarEvent>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shrinkWrap: true,
        children: [
          Text(l.chooseEvent, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (events.isEmpty) Text(l.noEventsUpcoming),
          for (final e in events)
            ListRow(
              key: Key('pick-${e.id}'),
              title: Text(e.title),
              subtitle: Text(d.fullDateTime(e.startsAt)),
              onTap: () => Navigator.of(context).pop(e),
            ),
        ],
      ),
    );
    if (picked != null) {
      setState(() {
        _event = picked;
        _eventMissing = false;
      });
    }
  }

  Future<void> _send() async {
    final formOk = _form.currentState!.validate();
    setState(() => _eventMissing = _kind == 1 && _event == null);
    if (!formOk || _eventMissing) return;
    setState(() => _busy = true);
    final l = AppLocalizations.of(context);
    try {
      await RepositoryLocator.instance.announcements.create(
        kind: _kind == 1 ? 'convocation' : 'annonce',
        title: _title.text.trim(),
        body: _body.text.trim(),
        eventId: _kind == 1 ? _event?.id : null,
        pinned: _pinned,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.announcementSent)));
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
    InputDecoration deco() => InputDecoration(
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.newAnnouncement, back: true, small: true),
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Seg2(
                      options: [l.kindAnnouncement, l.kindConvocation],
                      selected: _kind,
                      onChanged: (i) => setState(() => _kind = i),
                    ),
                    label(l.eventTitle),
                    TextFormField(
                      key: const Key('a-title'),
                      controller: _title,
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? l.required : null,
                      decoration: deco(),
                    ),
                    label(l.message),
                    TextFormField(
                      key: const Key('a-body'),
                      controller: _body,
                      maxLines: 6,
                      decoration: deco(),
                    ),
                    const SizedBox(height: 16),
                    GroupCard(
                      children: [
                        if (_kind == 1)
                          ListRow(
                            key: const Key('a-event'),
                            lead: IconChip(
                              Icons.event_available_outlined,
                              tone: _eventMissing ? Tone.red : Tone.green,
                            ),
                            title: Text(_event?.title ?? l.chooseEvent),
                            subtitle: _eventMissing
                                ? Text(
                                    l.eventRequired,
                                    style: TextStyle(color: c.alert),
                                  )
                                : (_event == null
                                      ? Text(l.linkedEvent)
                                      : Text(
                                          Dates(
                                            context,
                                          ).fullDateTime(_event!.startsAt),
                                        )),
                            chevron: true,
                            onTap: _pickEvent,
                          ),
                        ListRow(
                          lead: const IconChip(
                            Icons.groups_outlined,
                            tone: Tone.neutral,
                          ),
                          title: Text(l.recipientsAll),
                        ),
                        ListRow(
                          title: Text(l.pinOnTop),
                          trailing: Switch(
                            key: const Key('a-pin'),
                            value: _pinned,
                            onChanged: (v) => setState(() => _pinned = v),
                          ),
                        ),
                      ],
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
                child: FilledButton.icon(
                  key: const Key('a-send'),
                  onPressed: _busy ? null : _send,
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: Text(
                    _kind == 1 ? l.sendConvocation : l.sendAnnouncement,
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
