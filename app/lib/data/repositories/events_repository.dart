import '../../models/event.dart';

class AttendanceSheet {
  const AttendanceSheet({required this.counts, required this.rows});
  final Map<String, int> counts;
  final List<AttendanceRow> rows;
}

abstract class EventsRepository {
  Future<List<CalendarEvent>> list({
    required DateTime from,
    required DateTime to,
  });
  Future<CalendarEvent> get(int id);
  Future<CalendarEvent> create(CalendarEvent draft);
  Future<void> excuse(int eventId, {String reason = ''});
  Future<AttendanceSheet> attendance(int eventId);

  /// marks: member id → present | absent | excuse | '' (clear).
  Future<AttendanceSheet> saveAttendance(int eventId, Map<int, String> marks);
}
