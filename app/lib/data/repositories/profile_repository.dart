import '../../models/me.dart';

/// (slug, name) of one of the group's activity types or dress codes.
typedef NamedItem = (String, String);

/// The partner's contacts and texts (back-office → Plateforme), for Mon
/// compte → Aide / À propos. Empty = not filled in yet.
class PlatformInfo {
  const PlatformInfo({
    this.supportPhone = '',
    this.supportWhatsapp = '',
    this.supportEmail = '',
    this.website = '',
    this.privacyText = '',
    this.termsText = '',
  });

  final String supportPhone;
  final String supportWhatsapp;
  final String supportEmail;
  final String website;
  final String privacyText;
  final String termsText;

  factory PlatformInfo.fromJson(Map<String, dynamic> j) => PlatformInfo(
    supportPhone: (j['support_phone'] as String?) ?? '',
    supportWhatsapp: (j['support_whatsapp'] as String?) ?? '',
    supportEmail: (j['support_email'] as String?) ?? '',
    website: (j['website'] as String?) ?? '',
    privacyText: (j['privacy_text'] as String?) ?? '',
    termsText: (j['terms_text'] as String?) ?? '',
  );
}

class AppSettings {
  const AppSettings({
    required this.quickAmounts,
    required this.fees,
    this.activityTypes = defaultActivityTypes,
    this.dressCodes = defaultDressCodes,
    this.scopedTypes = defaultScopedTypes,
    this.typesWithoutChef = defaultTypesWithoutChef,
    this.eventMinutes = 120,
    this.remindBeforeHours = 2,
    this.reportHours = 24,
    this.contactPhone = '',
    this.contactEmail = '',
    this.website = '',
    this.rulesText = '',
  });

  /// Wider group settings (back-office → Paramètres, owner 2026-11-02).
  /// An event without an end time lasts this long.
  final int eventMinutes;

  /// "N h avant" reminders.
  final int remindBeforeHours;

  /// The chef de groupe's report is due this long after the end.
  final int reportHours;

  /// The group's own contacts and rules (Aide → Mon groupe).
  final String contactPhone;
  final String contactEmail;
  final String website;
  final String rulesText;

  /// Types whose events say intérieur or extérieur (Messe).
  final Set<String> scopedTypes;

  /// Types with no chef de groupe (Réunion); every other type has one.
  final Set<String> typesWithoutChef;
  static const defaultScopedTypes = {'messe'};
  static const defaultTypesWithoutChef = {'reunion'};
  final List<int> quickAmounts;

  /// The group's own lists (back-office → Paramètres).
  final List<NamedItem> activityTypes;
  final List<NamedItem> dressCodes;

  static const defaultActivityTypes = <NamedItem>[
    ('assise', 'Assise du samedi'),
    ('messe', 'Messe'),
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
    this.toConfirm,
    this.collections = const [],
    this.unfilled = const [],
  });
  final int? membersActive;
  final int? toValidate;

  /// Lines the trésorier edited and validated, for the commissaire.
  final int? toConfirm;

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

/// One question of Aide → Questions fréquentes, from the server.
typedef FaqItem = (String question, String answer);

/// The platform's common questions and the group's own (owner, 2026-11-02).
class FaqData {
  const FaqData({this.common = const [], this.group = const []});
  final List<FaqItem> common;
  final List<FaqItem> group;
}

/// A question the member proposed: pending | published | declined.
class FaqSuggestion {
  const FaqSuggestion({
    required this.id,
    required this.question,
    required this.status,
    this.note = '',
  });
  final int id;
  final String question;
  final String status;
  final String note;
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

  /// The group's name and sigle (the group.profile right: the président).
  Future<GroupInfo> updateGroup({String? name, String? shortName});

  /// Its logo (JPEG/PNG, cropped to a square by the server), or none.
  Future<GroupInfo> uploadGroupLogo({
    required List<int> bytes,
    required String filename,
  });
  Future<GroupInfo> removeGroupLogo();

  Future<PlatformInfo> platform();

  Future<FaqData> faq();
  Future<List<FaqSuggestion>> myFaqSuggestions();
  Future<void> suggestFaq({required String question, String answer = ''});
}
