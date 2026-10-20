import 'package:flutter/material.dart';

import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../../models/me.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/dates.dart';
import '../../widgets/errors.dart';
import '../../widgets/ui.dart';
import '../planning/my_duties_view.dart';
import '../planning/planning_week_view.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

/// Calendar tab (design: "Calendrier · mois"): month grid with a dot per
/// event, today circled, chosen day filled; or the agenda of what's next.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.me});
  final Me me;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _view = 0; // 0 month, 1 agenda
  late DateTime _month;
  late DateTime _selected;
  List<CalendarEvent>? _events;
  Object? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final from = _view == 0 ? _month : DateTime(now.year, now.month, now.day);
    final to = _view == 0
        ? DateTime(_month.year, _month.month + 1, 0)
        : from.add(const Duration(days: 90));
    try {
      final events = await RepositoryLocator.instance.events.list(
        from: from,
        to: to,
      );
      if (!mounted) return;
      setState(() {
        _events = events;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selected = _month;
      _events = null;
    });
    _load();
  }

  Future<void> _open(CalendarEvent e) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(eventId: e.id, me: widget.me),
      ),
    );
    _load();
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EventFormScreen(initialDay: _selected)),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final canCreate = widget.me.can('calendar.events', 'create');
    final planner = widget.me.can('calendar.planning', 'view');
    final seg = Seg2(
      options: [
        l.monthView,
        l.agendaView,
        planner ? l.planningView : l.myDutiesView,
      ],
      selected: _view,
      onChanged: (i) {
        setState(() {
          _view = i;
          _events = null;
        });
        if (i < 2) _load();
      },
    );
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [seg, const SizedBox(height: 12)],
    );
    if (_view == 2) {
      return Column(
        children: [
          ScreenHeader(title: l.tabCalendar, sync: true),
          Expanded(
            child: planner
                ? PlanningWeekView(me: widget.me, header: header)
                : MyDutiesView(header: header),
          ),
        ],
      );
    }
    return Column(
      children: [
        ScreenHeader(
          title: l.tabCalendar,
          sync: true,
          actions: [
            if (canCreate)
              IconButton(
                key: const Key('new-event'),
                icon: const Icon(Icons.add),
                tooltip: l.newEvent,
                onPressed: _create,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
          ],
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                seg,
                const SizedBox(height: 12),
                if (_error != null && _events == null)
                  EmptyState(
                    icon: Icons.cloud_off_outlined,
                    error: true,
                    title: l.loadError,
                    text: describeError(context, _error!),
                    action: FilledButton(
                      onPressed: _load,
                      child: Text(l.retry),
                    ),
                  )
                else if (_view == 0)
                  ..._monthView(context)
                else
                  ..._agendaView(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _monthView(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final d = Dates(context);
    final events = _events ?? const [];
    final byDay = <int, List<CalendarEvent>>{};
    for (final e in events) {
      if (e.startsAt.year == _month.year && e.startsAt.month == _month.month) {
        byDay.putIfAbsent(e.startsAt.day, () => []).add(e);
      }
    }
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = _month.weekday - 1; // Monday first
    final today = DateTime.now();
    final dayEvents = byDay[_selected.day] ?? const <CalendarEvent>[];
    return [
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: l.previousMonth,
            onPressed: () => _shiftMonth(-1),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          Expanded(
            child: Text(
              d.monthYear(_month),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: l.nextMonth,
            onPressed: () => _shiftMonth(1),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
      Row(
        children: [
          for (final w in d.weekdayInitials())
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  w,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
      GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.05,
        children: [
          for (var i = 0; i < lead; i++) const SizedBox(),
          for (var day = 1; day <= daysInMonth; day++)
            _DayCell(
              key: Key('day-$day'),
              day: day,
              selected: day == _selected.day && _selected.month == _month.month,
              today:
                  day == today.day &&
                  _month.month == today.month &&
                  _month.year == today.year,
              dots: (byDay[day] ?? const []).length,
              onTap: () => setState(
                () => _selected = DateTime(_month.year, _month.month, day),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (_events == null)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (dayEvents.isEmpty)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l.noEventsDay,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textSecondary),
          ),
        )
      else
        GroupCard(
          children: [
            for (final e in dayEvents)
              ListRow(
                lead: SizedBox(
                  width: 48,
                  child: Text(
                    d.time(e.startsAt),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFeatures: tabular,
                    ),
                  ),
                ),
                title: Text(e.title),
                subtitle: Text(e.place),
                chevron: true,
                onTap: () => _open(e),
              ),
          ],
        ),
    ];
  }

  List<Widget> _agendaView(BuildContext context) {
    final l = AppLocalizations.of(context);
    final events = _events;
    if (events == null) {
      return [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (events.isEmpty) {
      return [
        EmptyState(icon: Icons.event_outlined, title: l.noEventsUpcoming),
      ];
    }
    return [
      for (final e in events)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EventCard(event: e, fullDate: true, onTap: () => _open(e)),
        ),
    ];
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.day,
    required this.selected,
    required this.today,
    required this.dots,
    required this.onTap,
  });
  final int day;
  final bool selected;
  final bool today;
  final int dots;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: selected ? c.primary : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: today && !selected
              ? BorderSide(color: c.textPrimary, width: 1.5)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : c.textPrimary,
                  fontFeatures: tabular,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < dots.clamp(0, 3); i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : c.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
