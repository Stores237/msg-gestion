import '../l10n/app_localizations.dart';

/// Role names come from the server in French (the back-office edits them);
/// the seeded roles are translated here by slug. A role created later in
/// the back-office shows its own name in both languages.
String roleLabel(AppLocalizations l, String slug, String serverName) =>
    switch (slug) {
      'super-admin' => l.roleSuperAdmin,
      'president' => l.rolePresident,
      'secretaire-general' => l.roleSecretaryGeneral,
      'tresorier' => l.roleTreasurer,
      'commissaire-aux-comptes' => l.roleAuditor,
      'censeur-general' => l.roleHeadCensor,
      'formateur' => l.roleTrainer,
      'conseiller' => l.roleAdviser,
      'chef-de-groupe' => l.roleGroupLeader,
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

String eventKindLabel(AppLocalizations l, String kind) => switch (kind) {
  'assise' => l.kindAssise,
  'messe' => l.kindMass,
  'service_exterieur' => l.kindOutsideService,
  'grande_veillee' => l.kindVigil,
  'reunion' => l.kindMeeting,
  _ => l.kindOther,
};

const eventKinds = [
  'assise',
  'messe',
  'service_exterieur',
  'grande_veillee',
  'reunion',
  'autre',
];
const dressCodes = ['interieure', 'exterieure', 'sportive', 'civile', ''];

String dressLabel(AppLocalizations l, String dress) => switch (dress) {
  'interieure' => l.dressInside,
  'exterieure' => l.dressOutside,
  'sportive' => l.dressSport,
  'civile' => l.dressCivil,
  _ => l.dressNone,
};

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
