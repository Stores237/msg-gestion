import '../../models/me.dart';

/// (slug, name) of one of the group's activity types or dress codes.
typedef NamedItem = (String, String);

class AppSettings {
  const AppSettings({
    required this.quickAmounts,
    required this.fees,
    this.activityTypes = defaultActivityTypes,
    this.dressCodes = defaultDressCodes,
  });
  final List<int> quickAmounts;

  /// The group's own lists (back-office → Paramètres).
  final List<NamedItem> activityTypes;
  final List<NamedItem> dressCodes;

  static const defaultActivityTypes = <NamedItem>[
    ('assise', 'Assise du samedi'),
    ('messe', 'Messe'),
    ('service_exterieur', 'Service extérieur'),
    ('grande_veillee', 'Grande veillée'),
    ('reunion', 'Réunion'),
    ('autre', 'Autre'),
  ];
  static const defaultDressCodes = <NamedItem>[
    ('interieure', 'Tenue intérieure'),
    ('exterieure', 'Tenue extérieure'),
    ('sportive', 'Tenue sportive'),
    ('civile', 'Tenue civile'),
  ];

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

  /// The member's own picture: returns its new URL; [removeMyPhoto] clears it.
  Future<String?> uploadMyPhoto({
    required List<int> bytes,
    required String filename,
  });
  Future<void> removeMyPhoto();
}
