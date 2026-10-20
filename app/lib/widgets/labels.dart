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

String dutyStatusLabel(AppLocalizations l, String s) => switch (s) {
  'conf' => l.dutyConfirmed,
  'swap' => l.dutySwap,
  'repl' => l.dutyReplaced,
  'absent' => l.dutyAbsent,
  _ => l.dutyPending,
};

const serviceSizes = [2, 4, 6, 8, 10, 12];
