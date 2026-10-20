import '../l10n/app_localizations.dart';

/// Role names come from the server in French (the back-office edits them);
/// the seeded roles are translated here by slug. A role created later in
/// the back-office shows its own name in both languages.
String roleLabel(AppLocalizations l, String slug, String serverName) => switch (slug) {
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
