// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'MSG Gestion';

  @override
  String get movementName => 'Mouvement Garde Suisse';

  @override
  String get parishName => 'Paroisse Notre-Dame de Lourdes de Yapoma';

  @override
  String get motto => 'Service · Ordre · Accueil';

  @override
  String get splashPreparing => 'Préparation des données…';

  @override
  String get welcome => 'Bienvenue';

  @override
  String get loginIntro =>
      'Connectez-vous avec le numéro de téléphone enregistré au mouvement.';

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
      'Pas encore de compte ? Le secrétaire général vous inscrit lors de l’assise du samedi.';

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
      'Demandez au secrétaire général de réinitialiser votre code lors de l’assise.';

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
      'Ce numéro n’est pas enregistré. Le secrétaire général vous inscrit lors de l’assise du samedi.';

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
      'Aucun code PIN pour ce compte. Demandez au secrétaire général de l’initialiser.';

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
      'L’envoi de SMS n’est pas encore disponible. Demandez au secrétaire général de réinitialiser votre code.';

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
}
