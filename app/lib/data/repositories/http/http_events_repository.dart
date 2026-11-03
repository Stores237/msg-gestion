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
  Future<CalendarEvent> update(int id, CalendarEvent draft) async =>
      CalendarEvent.fromJson(
        await _api.patch('/events/$id/', body: draft.toJson())
            as Map<String, dynamic>,
      );

  @override
  Future<void> delete(int id) async => _api.delete('/events/$id/');

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
    lineup: (data['lineup'] as bool?) ?? false,
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

  @override
  Future<EventReport> report(int eventId) async => EventReport.fromJson(
    await _api.get('/events/$eventId/report/') as Map<String, dynamic>,
  );

  @override
  Future<EventReport> submitReport(
    int eventId, {
    required String body,
    (String, List<int>)? pdf,
  }) async {
    final path = '/events/$eventId/report/';
    final data = pdf == null
        ? await _api.post(path, body: {'body': body})
        : await _api.postFile(
            path,
            field: 'file',
            bytes: pdf.$2,
            filename: pdf.$1,
            fields: {'body': body},
          );
    return EventReport.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<ContingentBoard> contingents(int eventId) async =>
      ContingentBoard.fromJson(
        await _api.get('/events/$eventId/contingents/') as Map<String, dynamic>,
      );

  @override
  Future<ContingentBoard> askContingents(
    int eventId,
    List<({int group, int requested, String note})> requests,
  ) async => ContingentBoard.fromJson(
    await _api.put(
          '/events/$eventId/contingents/',
          body: {
            'requests': [
              for (final r in requests)
                {'group': r.group, 'requested': r.requested, 'note': r.note},
            ],
          },
        )
        as Map<String, dynamic>,
  );

  @override
  Future<MyContingent> myContingent(int eventId) async => MyContingent.fromJson(
    await _api.get('/events/$eventId/contingent/') as Map<String, dynamic>,
  );

  @override
  Future<MyContingent> answerContingent(int eventId, List<int> members) async =>
      MyContingent.fromJson(
        await _api.put(
              '/events/$eventId/contingent/',
              body: {'members': members},
            )
            as Map<String, dynamic>,
      );
}
