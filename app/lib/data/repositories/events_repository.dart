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

  /// Whoever added it (or the calendar's managers) edits or deletes it.
  Future<CalendarEvent> update(int id, CalendarEvent draft);
  Future<void> delete(int id);
  Future<void> excuse(int eventId, {String reason = ''});
  Future<AttendanceSheet> attendance(int eventId);

  /// marks: member id → present | absent | excuse | '' (clear).
  Future<AttendanceSheet> saveAttendance(int eventId, Map<int, String> marks);

  /// The chef de groupe's report (the chef and the formateur's circle).
  Future<EventReport> report(int eventId);

  /// By the chef: the text, and a PDF if [pdf] is given (name, bytes).
  Future<EventReport> submitReport(
    int eventId, {
    required String body,
    (String, List<int>)? pdf,
  });
}
