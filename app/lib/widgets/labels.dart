import '../data/repositories/profile_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/event.dart';

/// Role names come from the server in French (the back-office edits them);
/// the seeded roles are translated here by slug. A role created later in
/// the back-office shows its own name in both languages.
String roleLabel(AppLocalizations l, String slug, String serverName) =>
    switch (slug) {
      'super-admin' => l.roleSuperAdmin,
      'president' => l.rolePresident,
      'vice-president' => l.roleVicePresident,
      'secretaire-general-adjoint' => l.roleSecretaryGeneralDeputy,
      'secretaire-general' => l.roleSecretaryGeneral,
      'tresorier' => l.roleTreasurer,
      'commissaire-aux-comptes' => l.roleAuditor,
      'censeur-general' => l.roleHeadCensor,
      'formateur' => l.roleTrainer,
      'conseiller' => l.roleAdviser,
      'chef-de-groupe' => l.roleGroupLeader,
      'formateur-adjoint' => l.roleFormateurDeputy,
      'censeur-du-jour' => l.roleCensorOfTheDay,
      'membre' => l.roleMember,
      _ => serverName,
    };

String memberStatusLabel(AppLocalizations l, String status) => switch (status) {
  'actif' => l.statusActive,
  'conge' => l.statusLeave,
  'classe' => l.statusRetired,
  'suspendu' => l.statusSuspended,
  _ => status,
};

/// Activity types and dress codes are each group's own (back-office →
/// Paramètres). The default ones are translated while the group keeps
/// their default French name; anything else is shown as the group wrote it.
String eventKindLabel(AppLocalizations l, String kind, [String? name]) {
  final fallback = _defaultName(AppSettings.defaultActivityTypes, kind);
  if (name != null && name.isNotEmpty && name != fallback) return name;
  return switch (kind) {
    'assise' => l.kindAssise,
    'messe' => l.kindMass,
    'service_exterieur' => l.kindOutsideService,
    'grande_veillee' => l.kindVigil,
    'reunion' => l.kindMeeting,
    'autre' => l.kindOther,
    _ => name ?? kind,
  };
}

/// What an event is: the author's words for "Autre", otherwise the type.
String eventTypeName(AppLocalizations l, CalendarEvent e) =>
    e.kind == 'autre' && e.kindOther.isNotEmpty
    ? e.kindOther
    : eventKindLabel(l, e.kind, e.kindName);

String scopeLabel(AppLocalizations l, String scope) => switch (scope) {
  'interieur' => l.scopeInside,
  'exterieur' => l.scopeOutside,
  _ => '',
};

String dressLabel(AppLocalizations l, String dress, [String? name]) {
  final fallback = _defaultName(AppSettings.defaultDressCodes, dress);
  if (name != null && name.isNotEmpty && name != fallback) return name;
  return switch (dress) {
    'interieure' => l.dressInside,
    'exterieure' => l.dressOutside,
    'sportive' => l.dressSport,
    'civile' => l.dressCivil,
    '' => l.dressNone,
    _ => name ?? dress,
  };
}

String? _defaultName(List<NamedItem> items, String slug) {
  for (final (s, n) in items) {
    if (s == slug) return n;
  }
  return null;
}

String presenceLabel(AppLocalizations l, String status) => switch (status) {
  'present' => l.presencePresent,
  'absent' => l.presenceAbsent,
  'excuse' => l.presenceExcused,
  _ => l.presenceNotMarked,
};

const incomeCategories = ['solidarite', 'amende', 'inscription', 'aide_don'];

String financeCategoryLabel(AppLocalizations l, String c) => switch (c) {
  'inscription' => l.catRegistration,
  'amende' => l.catFine,
  'aide_don' => l.catDonation,
  'solidarite' => l.catSolidarity,
  'depense' => l.catExpense,
  _ => c,
};

const collectionKinds = ['deces', 'maladie', 'medaille', 'autre'];

String collectionKindLabel(AppLocalizations l, String k) => switch (k) {
  'deces' => l.kindDeath,
  'maladie' => l.kindIllness,
  'medaille' => l.kindMedal,
  _ => l.kindOther,
};

String postLabel(AppLocalizations l, String post) => switch (post) {
  'premiere_centrale' => l.postPremiereCentrale,
  'deuxieme_centrale' => l.postDeuxiemeCentrale,
  'controle' => l.postControle,
  'petites_portes' => l.postPetitesPortes,
  'mesanie' => l.postMesanie,
  _ => post,
};

String sideLabel(AppLocalizations l, String side) =>
    side == 'yapoma' ? l.sideYapoma : l.sidePariso;

/// "Première centrale · Pariso"; "Chef de groupe" for a chef without a post.
String dutyLabel(AppLocalizations l, Duty d) => d.post.isEmpty
    ? l.chefDeGroupe
    : '${postLabel(l, d.post)} · ${sideLabel(l, d.side)}';

String dutyStatusLabel(AppLocalizations l, String s) => switch (s) {
  'conf' => l.dutyConfirmed,
  'swap' => l.dutySwap,
  'repl' => l.dutyReplaced,
  'absent' => l.dutyAbsent,
  _ => l.dutyPending,
};

const serviceSizes = [2, 4, 6, 8, 10, 12];
