import '../../../models/event.dart';
import '../../api_client.dart';
import '../events_repository.dart';

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class HttpEventsRepository implements EventsRepository {
  HttpEventsRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<CalendarEvent>> list({
    required DateTime from,
    required DateTime to,
  }) async => [
    for (final e
        in await _api.get(
              '/events/',
              query: {'from': _day(from), 'to': _day(to)},
            )
            as List)
      CalendarEvent.fromJson(e as Map<String, dynamic>),
  ];

  @override
  Future<CalendarEvent> get(int id) async => CalendarEvent.fromJson(
    await _api.get('/events/$id/') as Map<String, dynamic>,
  );

  @override
  Future<CalendarEvent> create(CalendarEvent draft) async =>
      CalendarEvent.fromJson(
        await _api.post('/events/', body: draft.toJson())
            as Map<String, dynamic>,
      );

  @override
  Future<void> excuse(int eventId, {String reason = ''}) => _api.sendOrQueue(
    'POST',
    '/events/$eventId/excuse/',
    body: {'reason': reason},
    kind: 'excuse',
  );

  AttendanceSheet _sheet(Map<String, dynamic> data) => AttendanceSheet(
    counts: (data['counts'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as int),
    ),
    rows: [
      for (final r in data['rows'] as List)
        AttendanceRow.fromJson(r as Map<String, dynamic>),
    ],
  );

  @override
  Future<AttendanceSheet> attendance(int eventId) async => _sheet(
    await _api.get('/events/$eventId/attendance/') as Map<String, dynamic>,
  );

  @override
  Future<AttendanceSheet> saveAttendance(
    int eventId,
    Map<int, String> marks,
  ) async => _sheet(
    await _api.sendOrQueue(
          'PUT',
          '/events/$eventId/attendance/',
          kind: 'attendance',
          body: {
            'marks': [
              for (final e in marks.entries)
                {'member': e.key, 'status': e.value},
            ],
          },
        )
        as Map<String, dynamic>,
  );
}
