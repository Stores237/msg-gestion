import '../../models/me.dart';

class AppSettings {
  const AppSettings({required this.quickAmounts, required this.fees});
  final List<int> quickAmounts;

  /// inscription | medaille | maladie | deces → amount
  final Map<String, int> fees;

  static const fallback = AppSettings(
    quickAmounts: [500, 1000, 2000, 2500],
    fees: {
      'inscription': 500,
      'medaille': 2000,
      'maladie': 1000,
      'deces': 2500,
    },
  );
}

class BureauHome {
  const BureauHome({
    this.membersActive,
    this.toValidate,
    this.collections = const [],
    this.unfilled = const [],
  });
  final int? membersActive;
  final int? toValidate;

  /// (id, title, paid_full, members)
  final List<(int, String, int, int)> collections;

  /// (title, starts_at, missing)
  final List<(String, DateTime, int)> unfilled;

  bool get isEmpty =>
      membersActive == null &&
      toValidate == null &&
      collections.isEmpty &&
      unfilled.isEmpty;
}

abstract class ProfileRepository {
  Future<Me> fetchMe();
  Future<AppSettings> settings();
  Future<void> setReminders({bool? eve, bool? twoHours});
  Future<BureauHome> bureauHome();
}
