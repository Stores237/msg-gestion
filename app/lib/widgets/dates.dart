import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Dates in the on-screen language. The design writes them out in full
/// ("samedi 24 octobre 2026 · 15:00"); 24-hour times in both languages.
class Dates {
  Dates(BuildContext context)
    : _locale = Localizations.localeOf(context).languageCode;
  final String _locale;

  String fullDate(DateTime d) => DateFormat.yMMMMEEEEd(_locale).format(d);
  String time(DateTime d) => DateFormat.Hm(_locale).format(d);
  String fullDateTime(DateTime d) => '${fullDate(d)} · ${time(d)}';
  String shortDate(DateTime d) => DateFormat.yMd(_locale).format(d);
  String weekdayShort(DateTime d) => DateFormat.E(_locale).format(d);
  String monthShort(DateTime d) => DateFormat.MMM(_locale).format(d);
  String monthYear(DateTime d) => DateFormat.yMMMM(_locale).format(d);
  String dayMonth(DateTime d) => DateFormat.MMMEd(_locale).format(d);

  /// Narrow weekday initials starting Monday.
  List<String> weekdayInitials() {
    final monday = DateTime(2026, 10, 19);
    return [
      for (var i = 0; i < 7; i++)
        DateFormat.E(
          _locale,
        ).format(monday.add(Duration(days: i))).substring(0, 1).toUpperCase(),
    ];
  }
}
