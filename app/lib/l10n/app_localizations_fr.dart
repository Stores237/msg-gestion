// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'MSG';

  @override
  String get motto => 'Service · Ordre · Accueil';

  @override
  String get splashPreparing => 'Préparation des données…';

  @override
  String get welcome => 'Bienvenue';

  @override
  String get loginIntro =>
      'Connectez-vous avec le numéro de téléphone enregistré dans votre groupe.';

  @override
  String get phoneLabel => 'Numéro de téléphone';

  @override
  String get phoneHint => 'Format : 6 XX XX XX XX (+237)';

  @override
  String get phoneInvalid =>
      'Format : 6 XX XX XX XX, ou le numéro international complet.';

  @override
  String get continueButton => 'Continuer';

  @override
  String get noAccountNotice =>
      'Pas encore de compte ? Demandez au responsable de votre groupe de vous inscrire.';

  @override
  String get pinTitle => 'Votre code PIN';

  @override
  String pinGreeting(String firstName) {
    return 'Bonjour $firstName, entrez vos 4 chiffres.';
  }

  @override
  String get pinForgot => 'Code oublié ?';

  @override
  String get pinForgotHelp =>
      'Demandez au responsable de votre groupe de réinitialiser votre code.';

  @override
  String get keypadFingerprint => 'Empreinte';

  @override
  String get keypadDelete => 'Effacer';

  @override
  String get back => 'Retour';

  @override
  String get networkError =>
      'Connexion impossible. Vérifiez le réseau et réessayez.';

  @override
  String get serverError =>
      'Le serveur ne répond pas correctement. Réessayez dans un instant.';

  @override
  String get retry => 'Réessayer';

  @override
  String helloName(String firstName) {
    return 'Bonjour $firstName';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabMembers => 'Membres';

  @override
  String get tabFinances => 'Finances';

  @override
  String get tabCalendar => 'Calendrier';

  @override
  String get tabAnnouncements => 'Annonces';

  @override
  String get comingSoonTitle => 'Bientôt disponible';

  @override
  String get comingSoonBody =>
      'Cet onglet arrive dans une prochaine version de l’application.';

  @override
  String get myRoles => 'Mes rôles';

  @override
  String get logout => 'Se déconnecter';

  @override
  String syncOk(String time) {
    return 'Synchronisé · dernière synchronisation $time';
  }

  @override
  String ageYears(int age) {
    return '$age ans';
  }

  @override
  String get noRole => 'Aucun rôle actif';

  @override
  String get errorUnknownMember =>
      'Ce numéro n’est pas enregistré. Demandez au responsable de votre groupe de vous inscrire.';

  @override
  String errorWrongPin(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Code incorrect. Il vous reste $n essais.',
      one: 'Code incorrect. Il vous reste 1 essai.',
    );
    return '$_temp0';
  }

  @override
  String errorLocked(int minutes) {
    return 'Compte bloqué après trop d’erreurs. Réessayez dans $minutes min.';
  }

  @override
  String get errorNoPin =>
      'Aucun code PIN pour ce compte. Demandez au responsable de votre groupe de l’initialiser.';

  @override
  String get errorForbidden => 'Votre rôle ne donne pas accès à cette action.';

  @override
  String get language => 'Langue';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get roleSuperAdmin => 'Super admin';

  @override
  String get rolePresident => 'Président';

  @override
  String get roleSecretaryGeneral => 'Secrétaire général';

  @override
  String get roleTreasurer => 'Trésorier';

  @override
  String get roleAuditor => 'Commissaire aux comptes';

  @override
  String get roleHeadCensor => 'Censeur général';

  @override
  String get roleTrainer => 'Formateur';

  @override
  String get roleAdviser => 'Conseiller';

  @override
  String get roleGroupLeader => 'Chef de groupe';

  @override
  String get roleCensorOfTheDay => 'Censeur du jour';

  @override
  String get roleMember => 'Membre';

  @override
  String get roleGuard => 'Garde';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get close => 'Fermer';

  @override
  String get search => 'Rechercher';

  @override
  String get required => 'Ce champ est obligatoire.';

  @override
  String get restrictedTitle => 'Accès réservé';

  @override
  String get pullToRefresh => 'Tirez pour actualiser';

  @override
  String get loadError => 'Chargement impossible';

  @override
  String get statusActive => 'Actif';

  @override
  String get statusLeave => 'En congé';

  @override
  String get statusRetired => 'Classé';

  @override
  String get statusSuspended => 'Suspendu';

  @override
  String get diaspora => 'Diaspora';

  @override
  String get minor => 'Mineur';

  @override
  String membersSubtitle(int n) {
    return '$n gardes';
  }

  @override
  String get membersSearchHint => 'Rechercher un nom, un numéro…';

  @override
  String filterAll(int n) {
    return 'Tous $n';
  }

  @override
  String filterActive(int n) {
    return 'Actifs $n';
  }

  @override
  String filterLeave(int n) {
    return 'En congé $n';
  }

  @override
  String filterRetired(int n) {
    return 'Classés $n';
  }

  @override
  String filterDiaspora(int n) {
    return 'Diaspora $n';
  }

  @override
  String get theBureau => 'Le bureau';

  @override
  String get theBureauSub => 'Rôles du bureau et mandats';

  @override
  String mandateUntil(String date) {
    return 'Mandat jusqu’au $date';
  }

  @override
  String guardSince(int year) {
    return 'Garde · depuis $year';
  }

  @override
  String get noMembersFound => 'Aucun membre ne correspond.';

  @override
  String get addMember => 'Ajouter';

  @override
  String get profile => 'Profil';

  @override
  String get information => 'Informations';

  @override
  String get phone => 'Téléphone';

  @override
  String get joinedOn => 'Date d’adhésion';

  @override
  String get birthDate => 'Date de naissance';

  @override
  String get parentOrGuardian => 'Parent ou tuteur';

  @override
  String get contributions => 'Contributions';

  @override
  String get restrictedMinorContacts =>
      'Les contacts des membres mineurs sont visibles uniquement par le président et le secrétaire général.';

  @override
  String get restrictedContributions =>
      'L’historique des contributions est réservé au trésorier, au commissaire aux comptes et au président.';

  @override
  String get call => 'Appeler';

  @override
  String get newMember => 'Nouveau membre';

  @override
  String get lastNameLabel => 'Nom';

  @override
  String get firstNamesLabel => 'Prénoms';

  @override
  String get birthDateHint => 'Choisir une date';

  @override
  String ageMinorHint(int age) {
    return '$age ans · contact du parent obligatoire';
  }

  @override
  String get diasporaMember => 'Membre de la diaspora';

  @override
  String get cityCountry => 'Ville, pays';

  @override
  String get parentName => 'Nom du parent ou tuteur';

  @override
  String get parentRelation => 'Lien (mère, père, tuteur…)';

  @override
  String get parentPhone => 'Téléphone du parent ou tuteur';

  @override
  String get parentRequired => 'Ce champ est obligatoire pour un mineur.';

  @override
  String get phoneTaken => 'Ce numéro est déjà celui d’un membre.';

  @override
  String get saveMember => 'Enregistrer le membre';

  @override
  String get memberSavedTitle => 'Membre enregistré';

  @override
  String memberSavedPin(String name, String pin) {
    return 'Code PIN provisoire de $name : $pin. Communiquez-le en personne ; il ne sera plus affiché.';
  }

  @override
  String get monthView => 'Mois';

  @override
  String get agendaView => 'Agenda';

  @override
  String get previousMonth => 'Mois précédent';

  @override
  String get nextMonth => 'Mois suivant';

  @override
  String get newEvent => 'Nouvel événement';

  @override
  String get noEventsDay => 'Rien de prévu ce jour.';

  @override
  String get noEventsUpcoming => 'Aucun événement à venir.';

  @override
  String get kindAssise => 'Assise du samedi';

  @override
  String get kindMass => 'Messe';

  @override
  String get kindOutsideService => 'Service extérieur';

  @override
  String get kindVigil => 'Grande veillée';

  @override
  String get kindMeeting => 'Réunion';

  @override
  String get kindOther => 'Autre';

  @override
  String get dressInside => 'Tenue intérieure';

  @override
  String get dressOutside => 'Tenue extérieure';

  @override
  String get dressSport => 'Tenue sportive';

  @override
  String get dressCivil => 'Tenue civile';

  @override
  String get dressNone => 'Pas de tenue imposée';

  @override
  String get myPresence => 'Ma présence';

  @override
  String get presenceNotMarked => 'Pas encore marquée';

  @override
  String get presenceNotMarkedSub => 'Le censeur fait l’appel sur place';

  @override
  String get presencePresent => 'Présent';

  @override
  String get presenceAbsent => 'Absent';

  @override
  String get presenceExcused => 'Excusé';

  @override
  String get warnAbsence => 'Prévenir d’une absence';

  @override
  String get absenceReason => 'Motif (facultatif)';

  @override
  String get absenceSent => 'Absence signalée au censeur.';

  @override
  String get alreadyMarked => 'La présence est déjà marquée par le censeur.';

  @override
  String get takeRollCall => 'Faire l’appel';

  @override
  String rollCallTitle(String title) {
    return 'Appel · $title';
  }

  @override
  String get statPresent => 'Présents';

  @override
  String get statAbsent => 'Absents';

  @override
  String get statExcused => 'Excusés';

  @override
  String get statRemaining => 'Restants';

  @override
  String get remote => 'À distance';

  @override
  String get rollCallSaved => 'Appel enregistré.';

  @override
  String unsavedChanges(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n modifications non enregistrées',
      one: '1 modification non enregistrée',
    );
    return '$_temp0';
  }

  @override
  String get eventKind => 'Type';

  @override
  String get eventTitle => 'Titre';

  @override
  String get eventDate => 'Date';

  @override
  String get eventStart => 'Début';

  @override
  String get eventEnd => 'Fin (facultatif)';

  @override
  String get eventPlace => 'Lieu';

  @override
  String get eventDress => 'Tenue';

  @override
  String get eventNotes => 'Notes';

  @override
  String get eventEndBeforeStart => 'La fin doit être après le début.';

  @override
  String get eventCreated => 'Événement ajouté au calendrier.';

  @override
  String nightUntil(String time) {
    return '→ $time · nuit';
  }

  @override
  String get filterAnnAll => 'Toutes';

  @override
  String get filterConvocations => 'Convocations';

  @override
  String filterUnread(int n) {
    return 'Non lues $n';
  }

  @override
  String get filterSent => 'Envoyées';

  @override
  String get kindAnnouncement => 'Annonce';

  @override
  String get kindConvocation => 'Convocation';

  @override
  String get pinned => 'Épinglé';

  @override
  String get unreadDot => 'Non lu';

  @override
  String readBy(int read, int total) {
    return 'Lu par $read sur $total';
  }

  @override
  String get compose => 'Rédiger';

  @override
  String get newAnnouncement => 'Nouvelle annonce';

  @override
  String get message => 'Message';

  @override
  String get linkedEvent => 'Événement lié';

  @override
  String get chooseEvent => 'Choisir un événement';

  @override
  String get eventRequired => 'Une convocation doit être liée à un événement.';

  @override
  String get pinOnTop => 'Épingler en tête du fil';

  @override
  String get recipientsAll => 'Tous les membres';

  @override
  String get sendAnnouncement => 'Publier l’annonce';

  @override
  String get sendConvocation => 'Envoyer la convocation';

  @override
  String get announcementSent => 'Publié.';

  @override
  String get allRead => 'Tout est lu';

  @override
  String get allReadBody =>
      'Les nouvelles annonces et convocations du bureau apparaîtront ici.';

  @override
  String get noAnnouncements => 'Aucune annonce';

  @override
  String get readReceipts => 'Accusés de lecture';

  @override
  String notReadYet(int n) {
    return 'Non lu $n';
  }

  @override
  String readTab(int n) {
    return 'Lu $n';
  }

  @override
  String get nextMeeting => 'Prochain rendez-vous';

  @override
  String get lastAnnouncement => 'Dernière annonce';

  @override
  String get nothingPlanned => 'Rien de prévu pour l’instant.';

  @override
  String get calendarLink => 'Calendrier';

  @override
  String get allAnnouncements => 'Toutes';

  @override
  String get myAccount => 'Mon compte';

  @override
  String get readStatus => 'Lu';

  @override
  String get openAccount => 'Ouvrir mon compte';

  @override
  String unreadCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n annonces non lues',
      one: '1 annonce non lue',
    );
    return '$_temp0';
  }

  @override
  String get changePin => 'Changer mon code PIN';

  @override
  String get choosePinTitle => 'Choisissez votre code PIN';

  @override
  String get choosePinForced =>
      'Votre code actuel est provisoire. Choisissez un code à 4 chiffres que vous seul connaissez.';

  @override
  String get currentPin => 'Code actuel';

  @override
  String get newPin => 'Nouveau code';

  @override
  String get confirmPin => 'Confirmer le nouveau code';

  @override
  String get pinMismatch => 'Les deux codes ne sont pas identiques.';

  @override
  String get pinFourDigits => '4 chiffres.';

  @override
  String get pinTooSimple =>
      'Code trop simple (1111, 1234…). Choisissez-en un autre.';

  @override
  String get pinChanged => 'Code PIN modifié.';

  @override
  String get forgotTitle => 'Code PIN oublié';

  @override
  String get forgotIntro =>
      'Nous envoyons un code par SMS au numéro du compte.';

  @override
  String get sendCode => 'Envoyer le code';

  @override
  String get smsCode => 'Code reçu par SMS';

  @override
  String get badCode => 'Code incorrect ou expiré.';

  @override
  String get smsUnavailable =>
      'L’envoi de SMS n’est pas encore disponible. Demandez au responsable de votre groupe de réinitialiser votre code.';

  @override
  String get resetPin => 'Réinitialiser le code PIN';

  @override
  String resetPinConfirm(String name) {
    return 'Un nouveau code provisoire sera créé pour $name. L’ancien ne fonctionnera plus.';
  }

  @override
  String resetPinDone(String name, String pin) {
    return 'Nouveau code provisoire de $name : $pin. Communiquez-le en personne ; il ne sera plus affiché.';
  }

  @override
  String get confirm => 'Confirmer';

  @override
  String get attachFile => 'Joindre un fichier (PDF, photo)';

  @override
  String get attachHint => 'PDF, JPEG ou PNG · 10 Mo maximum';

  @override
  String get fileTooLarge => 'Fichier trop lourd (10 Mo maximum).';

  @override
  String get fileType => 'Seuls les PDF, JPEG et PNG sont acceptés.';

  @override
  String attachmentFailed(String name) {
    return 'Annonce publiée, mais « $name » n’a pas pu être joint.';
  }

  @override
  String get openFileFailed => 'Impossible d’ouvrir le fichier.';

  @override
  String get removeFile => 'Retirer';

  @override
  String sizeKb(int n) {
    return '$n Ko';
  }

  @override
  String sizeMb(String n) {
    return '$n Mo';
  }

  @override
  String get cashBalance => 'Solde de la caisse';

  @override
  String validatedUntil(String date) {
    return 'Validé jusqu’au $date';
  }

  @override
  String withPending(String amount) {
    return '$amount en comptant les opérations à valider';
  }

  @override
  String get cashBook => 'Livre de caisse';

  @override
  String get solidarity => 'Solidarité';

  @override
  String get report => 'Rapport';

  @override
  String get newEntry => 'Nouvelle opération';

  @override
  String get entryButton => 'Opération';

  @override
  String get directionIn => 'Entrée';

  @override
  String get directionOut => 'Sortie';

  @override
  String get amount => 'Montant';

  @override
  String get category => 'Catégorie';

  @override
  String get catRegistration => 'Inscriptions';

  @override
  String get catFine => 'Amendes';

  @override
  String get catDonation => 'Aides et dons';

  @override
  String get catSolidarity => 'Contributions de solidarité';

  @override
  String get catExpense => 'Dépenses';

  @override
  String get member => 'Membre';

  @override
  String get memberOptional => 'Membre (facultatif)';

  @override
  String get chooseMember => 'Choisir un membre';

  @override
  String get description => 'Libellé';

  @override
  String get amountRequired => 'Indiquez un montant.';

  @override
  String get willBeValidated => 'Sera validée par le commissaire aux comptes.';

  @override
  String enteredBy(String name, String when) {
    return 'Saisi par $name · $when';
  }

  @override
  String validatedBy(String name) {
    return 'Validé par $name';
  }

  @override
  String get toValidate => 'À valider';

  @override
  String get validated => 'Validé';

  @override
  String get notSentYet => 'Pas encore envoyé';

  @override
  String get validateEntryTitle => 'Valider cette opération ?';

  @override
  String get validateEntryBody =>
      'Votre nom et l’heure seront enregistrés. Une opération validée ne peut plus être modifiée.';

  @override
  String get validate => 'Valider';

  @override
  String get entryValidated => 'Opération validée.';

  @override
  String get entrySaved => 'Opération enregistrée, en attente de validation.';

  @override
  String get ownEntry => 'On ne peut pas valider sa propre saisie.';

  @override
  String get noEntries => 'Aucune opération pour l’instant.';

  @override
  String get collections => 'Collectes';

  @override
  String get newCollection => 'Nouvelle collecte';

  @override
  String get collectionKind => 'Motif';

  @override
  String get kindDeath => 'Décès';

  @override
  String get kindIllness => 'Maladie';

  @override
  String get kindMedal => 'Médaille, diplôme, sacrement';

  @override
  String get amountPerMember => 'Montant par membre';

  @override
  String paidFullOf(int paid, int total) {
    return '$paid sur $total ont tout payé';
  }

  @override
  String tranchesInfo(String parts) {
    return 'Tranches de $parts, une par semaine sur un mois.';
  }

  @override
  String filterToPay(int n) {
    return 'À payer $n';
  }

  @override
  String filterPaid(int n) {
    return 'Payé $n';
  }

  @override
  String thirdsOf3(int n) {
    return '$n/3 tranches';
  }

  @override
  String get paidInFull => 'Payé';

  @override
  String savePayments(int n, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Enregistrer $n paiements · $amount',
      one: 'Enregistrer 1 paiement · $amount',
    );
    return '$_temp0';
  }

  @override
  String get paymentsSaved => 'Paiements enregistrés.';

  @override
  String get closeCollection => 'Clôturer la collecte';

  @override
  String get closeCollectionBody =>
      'Les membres restants seront notés « non payé ».';

  @override
  String get closed => 'Clôturée';

  @override
  String get noCollections => 'Aucune collecte.';

  @override
  String quarterReport(int q, int year) {
    return 'Rapport T$q $year';
  }

  @override
  String get summary => 'Synthèse';

  @override
  String get openingBalance => 'Solde d’ouverture';

  @override
  String get closingBalance => 'Solde de clôture';

  @override
  String get incomeLabel => 'Entrées';

  @override
  String get expenseLabel => 'Sorties';

  @override
  String get incomeByCategory => 'Entrées par catégorie';

  @override
  String pendingBlock(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n opérations restent à vérifier avant de valider.',
      one: '1 opération reste à vérifier avant de valider.',
    );
    return '$_temp0';
  }

  @override
  String get validateReport => 'Valider le rapport';

  @override
  String reportValidatedBy(String name, String date) {
    return 'Validé par $name le $date';
  }

  @override
  String get previousQuarter => 'Trimestre précédent';

  @override
  String get nextQuarter => 'Trimestre suivant';

  @override
  String get myContributions => 'Mes contributions';

  @override
  String get toPayLabel => 'À payer';

  @override
  String get nothingToPay => 'Rien à payer. Merci !';

  @override
  String remainingOf(String remaining, String total) {
    return 'Reste $remaining sur $total';
  }

  @override
  String get fine => 'Amende';

  @override
  String get planningView => 'Planning';

  @override
  String get myDutiesView => 'Mes services';

  @override
  String weekOf(String start, String end) {
    return 'Semaine du $start au $end';
  }

  @override
  String get previousWeek => 'Semaine précédente';

  @override
  String get nextWeek => 'Semaine suivante';

  @override
  String get postPremiereCentrale => 'Première centrale';

  @override
  String get postDeuxiemeCentrale => 'Deuxième centrale';

  @override
  String get postControle => 'Contrôle';

  @override
  String get postPetitesPortes => 'Petites portes';

  @override
  String get postMesanie => 'Mésanie';

  @override
  String get sidePariso => 'Pariso';

  @override
  String get sideYapoma => 'Yapoma';

  @override
  String get freeSlot => '+ Libre';

  @override
  String chefLabel(String name) {
    return 'Chef : $name';
  }

  @override
  String filledOf(int filled, int size) {
    return '$filled/$size';
  }

  @override
  String alertsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n alertes',
      one: '1 alerte',
    );
    return '$_temp0';
  }

  @override
  String alertUnderstaffed(String title, int filled, int size) {
    return '$title : $filled sur $size';
  }

  @override
  String alertDouble(String name) {
    return '$name a deux services le même jour';
  }

  @override
  String alertOnLeave(String name) {
    return '$name est en congé';
  }

  @override
  String get publishAndNotify => 'Publier et notifier';

  @override
  String get published => 'Publié';

  @override
  String publishedDone(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Planning publié · $n gardes notifiés.',
      one: 'Planning publié · 1 garde notifié.',
    );
    return '$_temp0';
  }

  @override
  String get noServicesWeek => 'Aucun service prévu cette semaine.';

  @override
  String get setServiceSize => 'Prévoir le service';

  @override
  String get serviceSize => 'Nombre de gardes';

  @override
  String get assignGroup => 'Affecter un groupe';

  @override
  String groupAssigned(int assigned, int empty) {
    return '$assigned postes remplis · $empty encore libres';
  }

  @override
  String groupMembersInfo(int n, int available) {
    return '$n gardes · $available disponibles';
  }

  @override
  String get leastSolicitedFirst => 'Les moins sollicités en premier';

  @override
  String servicesThisMonth(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n services ce mois',
      one: '1 service ce mois',
      zero: 'Aucun service ce mois',
    );
    return '$_temp0';
  }

  @override
  String get flagBusy => 'Déjà de service ce jour-là';

  @override
  String get flagLeave => 'En congé';

  @override
  String get flagMany => 'Déjà beaucoup de services ce mois';

  @override
  String get assign => 'Affecter';

  @override
  String get assignAnyway => 'Quand même';

  @override
  String get clearSlot => 'Libérer le poste';

  @override
  String get dutyPending => 'À confirmer';

  @override
  String get dutyConfirmed => 'Confirmé';

  @override
  String get dutySwap => 'Échange demandé';

  @override
  String get dutyReplaced => 'Remplacé';

  @override
  String get dutyAbsent => 'Absence déclarée';

  @override
  String get conflict => 'Conflit';

  @override
  String get confirmDuty => 'Confirmer';

  @override
  String get swapDuty => 'Échanger';

  @override
  String get swapTitle => 'Échanger mon service';

  @override
  String get withWhom => 'Avec qui ?';

  @override
  String get reasonOptional => 'Raison (facultatif)';

  @override
  String get sendRequest => 'Envoyer la demande';

  @override
  String get declareAbsence => 'Je ne pourrai pas venir';

  @override
  String get requestSent => 'Demande envoyée.';

  @override
  String get noDuties => 'Aucun service prévu pour vous.';

  @override
  String get myNextDuty => 'Mon prochain service';

  @override
  String get requests => 'Demandes';

  @override
  String requestsPending(int n) {
    return '$n en attente';
  }

  @override
  String swapForYou(String name) {
    return '$name vous propose son service';
  }

  @override
  String get accept => 'Accepter';

  @override
  String get refuse => 'Refuser';

  @override
  String get approve => 'Approuver';

  @override
  String swapLine(String from, String to) {
    return '$from ⇄ $to';
  }

  @override
  String absenceLine(String name) {
    return 'Absence · $name';
  }

  @override
  String get chooseReplacement => 'Choisir un remplaçant';

  @override
  String get noRequests => 'Aucune demande en attente.';

  @override
  String get albs => 'Lavage des aubes';

  @override
  String albsWeek(String date) {
    return 'Semaine du $date';
  }

  @override
  String albsCount(int n) {
    return '$n aubes';
  }

  @override
  String get albToWash => 'À laver';

  @override
  String get albWashed => 'Lavées';

  @override
  String get albReturned => 'Rendues';

  @override
  String get markWashed => 'Marquer « lavées »';

  @override
  String get markReturned => 'Marquer « rendues »';

  @override
  String get nextWeeks => 'Prochaines semaines';

  @override
  String get fairness12 => 'Équité · lavages sur 12 mois';

  @override
  String get scheduleAlbs => 'Programmer une semaine';

  @override
  String responsible(String name) {
    return 'Responsable : $name';
  }

  @override
  String get noAlbs => 'Aucune semaine programmée.';

  @override
  String get group => 'Groupe';

  @override
  String get groups => 'Groupes';

  @override
  String get planned => 'Prévu';

  @override
  String get notificationsEmpty => 'Aucune notification.';

  @override
  String get markAllRead => 'Tout lire';

  @override
  String get today => 'Aujourd’hui';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get earlier => 'Plus ancien';

  @override
  String get offlineBar => 'Hors ligne';

  @override
  String offlinePending(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Hors ligne · $n saisies en attente d’envoi',
      one: 'Hors ligne · 1 saisie en attente d’envoi',
    );
    return '$_temp0';
  }

  @override
  String syncedAt(String time) {
    return 'Synchronisé · dernière synchronisation $time';
  }

  @override
  String get syncing => 'Synchronisation en cours…';

  @override
  String offlineSince(String time) {
    return 'Hors ligne · dernière synchronisation $time';
  }

  @override
  String get syncFailed => 'Échec de la synchronisation';

  @override
  String get savedOnPhone =>
      'Enregistré sur le téléphone. Envoi dès le retour du réseau.';

  @override
  String pendingSend(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n envois en attente',
      one: '1 envoi en attente',
    );
    return '$_temp0';
  }

  @override
  String get never => 'jamais';

  @override
  String get addPhoto => 'Ajouter une photo';

  @override
  String get changePhoto => 'Changer la photo';

  @override
  String get photoSaved => 'Photo enregistrée.';

  @override
  String get registrationFee => 'Frais d’inscription payés';

  @override
  String get registrationFeeSub =>
      'Ajouté au livre de caisse, en attente de validation';

  @override
  String get presenceLast4 => 'Présences · 4 dernières assises';

  @override
  String presenceSummary(int present, int absent, int excused) {
    return '$present présent · $absent absent · $excused excusé';
  }

  @override
  String lastOn(String date) {
    return 'Dernière : $date';
  }

  @override
  String get proposeRole => 'Proposer un rôle';

  @override
  String get roleRequestSent => 'Demande envoyée au super admin.';

  @override
  String get fromDate => 'Du';

  @override
  String get toDate => 'Au (facultatif)';

  @override
  String get reasonRequired => 'Motif (journalisé)';

  @override
  String get reminders => 'Rappels';

  @override
  String get remindEve => 'La veille à 20:00';

  @override
  String get remind2h => '2 heures avant';

  @override
  String remindUnread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Relancer les $n non-lecteurs',
      one: 'Relancer le non-lecteur',
    );
    return '$_temp0';
  }

  @override
  String remindedDone(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n membres relancés.',
      one: '1 membre relancé.',
    );
    return '$_temp0';
  }

  @override
  String get exportPdf => 'Exporter en PDF';

  @override
  String get toFollow => 'À suivre';

  @override
  String get activeMembers => 'Membres actifs';

  @override
  String entriesToValidate(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n opérations à valider',
      one: '1 opération à valider',
    );
    return '$_temp0';
  }

  @override
  String get awaitingAuditor => 'En attente du commissaire aux comptes';

  @override
  String unfilledSlots(int n, String title) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n postes non pourvus',
      one: '1 poste non pourvu',
    );
    return '$_temp0 · $title';
  }

  @override
  String get roleVicePresident => 'Vice-président';

  @override
  String get roleSecretaryGeneralDeputy => 'Secrétaire général adjoint';

  @override
  String get roleFormateurDeputy => 'Formateur adjoint';

  @override
  String get designateChef => 'Désigner le chef de groupe';

  @override
  String get chefSheetHint => 'Parmi les gardes de ce service.';

  @override
  String get removeChef => 'Retirer le chef de groupe';

  @override
  String get noChefYet => 'Pas encore de chef de groupe';

  @override
  String get youAreChef => 'Vous êtes chef de groupe';

  @override
  String get chefNeedsGuards => 'Affectez d’abord des gardes à ce service.';

  @override
  String get statementPdf => 'Bilan général des membres (PDF)';

  @override
  String get memberStatementPdf => 'Bilan financier (PDF)';

  @override
  String get errorBackofficeOnly =>
      'Les comptes du back-office (super admin, équipes support, IT, intégrations) s’utilisent uniquement sur le back-office (navigateur web), pas dans l’application.';

  @override
  String get requestAccess => 'Demander un accès';

  @override
  String get accessRequestsTitle => 'Demandes d’accès';

  @override
  String get accessRole => 'Rôle demandé';

  @override
  String get accessNote => 'Message pour le partenaire (facultatif)';

  @override
  String get sendAccessRequest => 'Envoyer la demande';

  @override
  String get accessSentTitle => 'Demande envoyée';

  @override
  String get accessSentBody =>
      'Le partenaire MSG crée l’accès. Vous serez prévenu ici, avec le code provisoire à remettre au membre.';

  @override
  String get accessIntro =>
      'Le partenaire MSG ouvre le compte. Vous recevrez ensuite le code provisoire à remettre au membre.';

  @override
  String get accessPending => 'En attente';

  @override
  String get accessApproved => 'Accès créé';

  @override
  String get accessRefused => 'Refusée';

  @override
  String get showTempPin => 'Voir le code provisoire';

  @override
  String get tempPinTitle => 'Code provisoire';

  @override
  String tempPinBody(String name, String phone) {
    return 'Remettez ce code à $name ($phone). Il ne sera plus affiché. À sa première connexion, il choisira son propre code et verra son rôle.';
  }

  @override
  String get accessExistingAccount =>
      'Compte existant : il se connecte avec son code habituel.';

  @override
  String get pinGone =>
      'Code déjà remis ou expiré. Demandez une réinitialisation au partenaire.';

  @override
  String get noAccessRequests => 'Aucune demande pour l’instant.';

  @override
  String get switchGroup => 'Changer de groupe';

  @override
  String get chooseGroup => 'Choisir un groupe';

  @override
  String get errorNoGroup =>
      'Ce compte n’appartient encore à aucun groupe. Demandez au responsable de votre groupe.';

  @override
  String get platformTagline =>
      'La gestion de votre groupe : membres, caisse, calendrier, services, annonces.';

  @override
  String get goodMorning => 'Bonjour';

  @override
  String get goodAfternoon => 'Bon après-midi';

  @override
  String get goodEvening => 'Bonsoir';

  @override
  String get appearance => 'Apparence';

  @override
  String get appColor => 'Couleur de l’application';

  @override
  String get groupColorChoice => 'Couleur du groupe';

  @override
  String get appColorHint =>
      'Pour ce téléphone. « Couleur du groupe » suit le réglage de votre groupe.';

  @override
  String colorN(int n) {
    return 'Couleur $n';
  }

  @override
  String get myPhoto => 'Photo de profil';

  @override
  String get photoFromGallery => 'Choisir dans la galerie';

  @override
  String get photoFromCamera => 'Prendre une photo';

  @override
  String get removePhoto => 'Retirer la photo';

  @override
  String get photoRemoved => 'Photo retirée.';

  @override
  String get requestDayRole => 'Demander un rôle du jour';

  @override
  String get dayRoleHint =>
      'Pour un membre actif sans rôle, le temps d’une journée. Le partenaire valide ; le rôle s’arrête le soir même.';

  @override
  String onDay(String date) {
    return 'Le $date';
  }

  @override
  String get dayRoleRequestSent => 'Demande envoyée au partenaire.';

  @override
  String get unlockTitle => 'Entrez votre code PIN';

  @override
  String get unlockSubtitle => 'Pour ouvrir MSG.';

  @override
  String unlockWrong(int n) {
    return 'Code incorrect. Encore $n essai(s).';
  }

  @override
  String get unlockTooMany =>
      'Trop d’essais : reconnectez-vous avec votre numéro.';

  @override
  String get unlockSignInAgain =>
      'Pour votre sécurité, reconnectez-vous une fois avec votre numéro et votre code.';

  @override
  String get unlockOtherAccount => 'Se connecter autrement';

  @override
  String get biometricReason => 'Déverrouiller MSG';

  @override
  String get biometricUnlock => 'Déverrouiller avec l’empreinte ou le visage';

  @override
  String get biometricUnavailable =>
      'Aucune empreinte ni visage enregistré sur ce téléphone.';

  @override
  String get biometricHint => 'Le code PIN reste toujours possible.';

  @override
  String get addedBy => 'Ajouté par';

  @override
  String get storageUnavailable =>
      'L’envoi du fichier a échoué : le stockage est indisponible. Réessayez plus tard ; si cela continue, prévenez le partenaire.';

  @override
  String get helpSection => 'Aide';

  @override
  String get aboutSection => 'À propos';

  @override
  String get faq => 'Questions fréquentes';

  @override
  String get faqSub => 'Réponses aux questions courantes';

  @override
  String get helpSupport => 'Aide et assistance';

  @override
  String get helpSupportSub => 'Appeler une vraie personne';

  @override
  String get whatsappSupport => 'Assistance WhatsApp';

  @override
  String get whatsappSupportSub => 'Écrivez-nous sur WhatsApp';

  @override
  String get contactUs => 'Nous contacter';

  @override
  String get contactUsSub => 'Questions ou suggestions';

  @override
  String get visitWebsite => 'Visiter notre site';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsOfService => 'Conditions d’utilisation';

  @override
  String get notAvailableYet => 'Pas encore disponible';

  @override
  String appVersion(String v) {
    return 'Version $v';
  }

  @override
  String get faqQ1 => 'J’ai oublié mon code PIN.';

  @override
  String get faqA1 =>
      'Sur l’écran du code, touchez « Code oublié ? ». Si les SMS ne sont pas disponibles, demandez au responsable de votre groupe : il peut vous donner un code provisoire.';

  @override
  String get faqQ2 =>
      'Pourquoi l’application me demande-t-elle mon code à chaque ouverture ?';

  @override
  String get faqA2 =>
      'Pour protéger les données du groupe si quelqu’un prend votre téléphone. Vous pouvez déverrouiller avec l’empreinte ou le visage : Mon compte → Déverrouiller avec l’empreinte.';

  @override
  String get faqQ3 => 'Je ne vois pas l’onglet Finances (ou un autre).';

  @override
  String get faqA3 =>
      'Les onglets dépendent de votre rôle dans le groupe. Si votre rôle change, ils s’adaptent à la prochaine ouverture.';

  @override
  String get faqQ4 => 'Comment signaler une absence ?';

  @override
  String get faqA4 =>
      'Ouvrez l’activité dans le Calendrier et touchez « Prévenir d’une absence », avec le motif.';

  @override
  String get faqQ5 => 'Qu’est-ce qu’un rôle du jour ?';

  @override
  String get faqA5 =>
      'Un membre actif sans rôle peut recevoir, pour une journée, un rôle comme président, censeur ou trésorier du jour. Il est demandé dans l’application et validé par le partenaire ; il s’arrête le soir même.';

  @override
  String get faqQ6 => 'L’application marche-t-elle sans internet ?';

  @override
  String get faqA6 =>
      'Oui pour consulter ce qui a déjà été chargé et pour certaines saisies : elles partent dès que le réseau revient (bandeau « Hors ligne » en haut).';
}
