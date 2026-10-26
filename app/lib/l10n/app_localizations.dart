import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'MSG'**
  String get appTitle;

  /// No description provided for @motto.
  ///
  /// In fr, this message translates to:
  /// **'Service · Ordre · Accueil'**
  String get motto;

  /// No description provided for @splashPreparing.
  ///
  /// In fr, this message translates to:
  /// **'Préparation des données…'**
  String get splashPreparing;

  /// No description provided for @welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue'**
  String get welcome;

  /// No description provided for @loginIntro.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous avec le numéro de téléphone enregistré dans votre groupe.'**
  String get loginIntro;

  /// No description provided for @phoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get phoneLabel;

  /// No description provided for @phoneHint.
  ///
  /// In fr, this message translates to:
  /// **'Format : 6 XX XX XX XX (+237)'**
  String get phoneHint;

  /// No description provided for @phoneInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Format : 6 XX XX XX XX, ou le numéro international complet.'**
  String get phoneInvalid;

  /// No description provided for @continueButton.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueButton;

  /// No description provided for @noAccountNotice.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? Demandez au responsable de votre groupe de vous inscrire.'**
  String get noAccountNotice;

  /// No description provided for @pinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre code PIN'**
  String get pinTitle;

  /// No description provided for @pinGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {firstName}, entrez vos 4 chiffres.'**
  String pinGreeting(String firstName);

  /// No description provided for @pinForgot.
  ///
  /// In fr, this message translates to:
  /// **'Code oublié ?'**
  String get pinForgot;

  /// No description provided for @pinForgotHelp.
  ///
  /// In fr, this message translates to:
  /// **'Demandez au responsable de votre groupe de réinitialiser votre code.'**
  String get pinForgotHelp;

  /// No description provided for @keypadFingerprint.
  ///
  /// In fr, this message translates to:
  /// **'Empreinte'**
  String get keypadFingerprint;

  /// No description provided for @keypadDelete.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get keypadDelete;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @networkError.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Vérifiez le réseau et réessayez.'**
  String get networkError;

  /// No description provided for @serverError.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur ne répond pas correctement. Réessayez dans un instant.'**
  String get serverError;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @helloName.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {firstName}'**
  String helloName(String firstName);

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @tabHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get tabHome;

  /// No description provided for @tabMembers.
  ///
  /// In fr, this message translates to:
  /// **'Membres'**
  String get tabMembers;

  /// No description provided for @tabFinances.
  ///
  /// In fr, this message translates to:
  /// **'Finances'**
  String get tabFinances;

  /// No description provided for @tabCalendar.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get tabCalendar;

  /// No description provided for @tabAnnouncements.
  ///
  /// In fr, this message translates to:
  /// **'Annonces'**
  String get tabAnnouncements;

  /// No description provided for @comingSoonTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonBody.
  ///
  /// In fr, this message translates to:
  /// **'Cet onglet arrive dans une prochaine version de l’application.'**
  String get comingSoonBody;

  /// No description provided for @myRoles.
  ///
  /// In fr, this message translates to:
  /// **'Mes rôles'**
  String get myRoles;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logout;

  /// No description provided for @syncOk.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisé · dernière synchronisation {time}'**
  String syncOk(String time);

  /// No description provided for @ageYears.
  ///
  /// In fr, this message translates to:
  /// **'{age} ans'**
  String ageYears(int age);

  /// No description provided for @noRole.
  ///
  /// In fr, this message translates to:
  /// **'Aucun rôle actif'**
  String get noRole;

  /// No description provided for @errorUnknownMember.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro n’est pas enregistré. Demandez au responsable de votre groupe de vous inscrire.'**
  String get errorUnknownMember;

  /// No description provided for @errorWrongPin.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Code incorrect. Il vous reste 1 essai.} other{Code incorrect. Il vous reste {n} essais.}}'**
  String errorWrongPin(int n);

  /// No description provided for @errorLocked.
  ///
  /// In fr, this message translates to:
  /// **'Compte bloqué après trop d’erreurs. Réessayez dans {minutes} min.'**
  String errorLocked(int minutes);

  /// No description provided for @errorNoPin.
  ///
  /// In fr, this message translates to:
  /// **'Aucun code PIN pour ce compte. Demandez au responsable de votre groupe de l’initialiser.'**
  String get errorNoPin;

  /// No description provided for @errorForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Votre rôle ne donne pas accès à cette action.'**
  String get errorForbidden;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @roleSuperAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Super admin'**
  String get roleSuperAdmin;

  /// No description provided for @rolePresident.
  ///
  /// In fr, this message translates to:
  /// **'Président'**
  String get rolePresident;

  /// No description provided for @roleSecretaryGeneral.
  ///
  /// In fr, this message translates to:
  /// **'Secrétaire général'**
  String get roleSecretaryGeneral;

  /// No description provided for @roleTreasurer.
  ///
  /// In fr, this message translates to:
  /// **'Trésorier'**
  String get roleTreasurer;

  /// No description provided for @roleAuditor.
  ///
  /// In fr, this message translates to:
  /// **'Commissaire aux comptes'**
  String get roleAuditor;

  /// No description provided for @roleHeadCensor.
  ///
  /// In fr, this message translates to:
  /// **'Censeur général'**
  String get roleHeadCensor;

  /// No description provided for @roleTrainer.
  ///
  /// In fr, this message translates to:
  /// **'Formateur'**
  String get roleTrainer;

  /// No description provided for @roleAdviser.
  ///
  /// In fr, this message translates to:
  /// **'Conseiller'**
  String get roleAdviser;

  /// No description provided for @roleGroupLeader.
  ///
  /// In fr, this message translates to:
  /// **'Chef de groupe'**
  String get roleGroupLeader;

  /// No description provided for @roleCensorOfTheDay.
  ///
  /// In fr, this message translates to:
  /// **'Censeur du jour'**
  String get roleCensorOfTheDay;

  /// No description provided for @roleMember.
  ///
  /// In fr, this message translates to:
  /// **'Membre'**
  String get roleMember;

  /// No description provided for @roleGuard.
  ///
  /// In fr, this message translates to:
  /// **'Garde'**
  String get roleGuard;

  /// No description provided for @seeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get seeAll;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @required.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire.'**
  String get required;

  /// No description provided for @restrictedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Accès réservé'**
  String get restrictedTitle;

  /// No description provided for @pullToRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Tirez pour actualiser'**
  String get pullToRefresh;

  /// No description provided for @loadError.
  ///
  /// In fr, this message translates to:
  /// **'Chargement impossible'**
  String get loadError;

  /// No description provided for @statusActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get statusActive;

  /// No description provided for @statusLeave.
  ///
  /// In fr, this message translates to:
  /// **'En congé'**
  String get statusLeave;

  /// No description provided for @statusRetired.
  ///
  /// In fr, this message translates to:
  /// **'Classé'**
  String get statusRetired;

  /// No description provided for @statusSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Suspendu'**
  String get statusSuspended;

  /// No description provided for @diaspora.
  ///
  /// In fr, this message translates to:
  /// **'Diaspora'**
  String get diaspora;

  /// No description provided for @minor.
  ///
  /// In fr, this message translates to:
  /// **'Mineur'**
  String get minor;

  /// No description provided for @membersSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'{n} gardes'**
  String membersSubtitle(int n);

  /// No description provided for @membersSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un nom, un numéro…'**
  String get membersSearchHint;

  /// No description provided for @filterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous {n}'**
  String filterAll(int n);

  /// No description provided for @filterActive.
  ///
  /// In fr, this message translates to:
  /// **'Actifs {n}'**
  String filterActive(int n);

  /// No description provided for @filterLeave.
  ///
  /// In fr, this message translates to:
  /// **'En congé {n}'**
  String filterLeave(int n);

  /// No description provided for @filterRetired.
  ///
  /// In fr, this message translates to:
  /// **'Classés {n}'**
  String filterRetired(int n);

  /// No description provided for @filterDiaspora.
  ///
  /// In fr, this message translates to:
  /// **'Diaspora {n}'**
  String filterDiaspora(int n);

  /// No description provided for @theBureau.
  ///
  /// In fr, this message translates to:
  /// **'Le bureau'**
  String get theBureau;

  /// No description provided for @theBureauSub.
  ///
  /// In fr, this message translates to:
  /// **'Rôles du bureau et mandats'**
  String get theBureauSub;

  /// No description provided for @mandateUntil.
  ///
  /// In fr, this message translates to:
  /// **'Mandat jusqu’au {date}'**
  String mandateUntil(String date);

  /// No description provided for @guardSince.
  ///
  /// In fr, this message translates to:
  /// **'Garde · depuis {year}'**
  String guardSince(int year);

  /// No description provided for @noMembersFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun membre ne correspond.'**
  String get noMembersFound;

  /// No description provided for @addMember.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get addMember;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @information.
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get information;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phone;

  /// No description provided for @joinedOn.
  ///
  /// In fr, this message translates to:
  /// **'Date d’adhésion'**
  String get joinedOn;

  /// No description provided for @birthDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance'**
  String get birthDate;

  /// No description provided for @parentOrGuardian.
  ///
  /// In fr, this message translates to:
  /// **'Parent ou tuteur'**
  String get parentOrGuardian;

  /// No description provided for @contributions.
  ///
  /// In fr, this message translates to:
  /// **'Contributions'**
  String get contributions;

  /// No description provided for @restrictedMinorContacts.
  ///
  /// In fr, this message translates to:
  /// **'Les contacts des membres mineurs sont visibles uniquement par le président et le secrétaire général.'**
  String get restrictedMinorContacts;

  /// No description provided for @restrictedContributions.
  ///
  /// In fr, this message translates to:
  /// **'L’historique des contributions est réservé au trésorier, au commissaire aux comptes et au président.'**
  String get restrictedContributions;

  /// No description provided for @call.
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get call;

  /// No description provided for @newMember.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau membre'**
  String get newMember;

  /// No description provided for @lastNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get lastNameLabel;

  /// No description provided for @firstNamesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prénoms'**
  String get firstNamesLabel;

  /// No description provided for @birthDateHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une date'**
  String get birthDateHint;

  /// No description provided for @ageMinorHint.
  ///
  /// In fr, this message translates to:
  /// **'{age} ans · contact du parent obligatoire'**
  String ageMinorHint(int age);

  /// No description provided for @diasporaMember.
  ///
  /// In fr, this message translates to:
  /// **'Membre de la diaspora'**
  String get diasporaMember;

  /// No description provided for @cityCountry.
  ///
  /// In fr, this message translates to:
  /// **'Ville, pays'**
  String get cityCountry;

  /// No description provided for @parentName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du parent ou tuteur'**
  String get parentName;

  /// No description provided for @parentRelation.
  ///
  /// In fr, this message translates to:
  /// **'Lien (mère, père, tuteur…)'**
  String get parentRelation;

  /// No description provided for @parentPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone du parent ou tuteur'**
  String get parentPhone;

  /// No description provided for @parentRequired.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire pour un mineur.'**
  String get parentRequired;

  /// No description provided for @phoneTaken.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro est déjà celui d’un membre.'**
  String get phoneTaken;

  /// No description provided for @saveMember.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le membre'**
  String get saveMember;

  /// No description provided for @memberSavedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Membre enregistré'**
  String get memberSavedTitle;

  /// No description provided for @memberSavedPin.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN provisoire de {name} : {pin}. Communiquez-le en personne ; il ne sera plus affiché.'**
  String memberSavedPin(String name, String pin);

  /// No description provided for @monthView.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get monthView;

  /// No description provided for @agendaView.
  ///
  /// In fr, this message translates to:
  /// **'Agenda'**
  String get agendaView;

  /// No description provided for @previousMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois précédent'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois suivant'**
  String get nextMonth;

  /// No description provided for @newEvent.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel événement'**
  String get newEvent;

  /// No description provided for @noEventsDay.
  ///
  /// In fr, this message translates to:
  /// **'Rien de prévu ce jour.'**
  String get noEventsDay;

  /// No description provided for @noEventsUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement à venir.'**
  String get noEventsUpcoming;

  /// No description provided for @kindAssise.
  ///
  /// In fr, this message translates to:
  /// **'Assise du samedi'**
  String get kindAssise;

  /// No description provided for @kindMass.
  ///
  /// In fr, this message translates to:
  /// **'Messe'**
  String get kindMass;

  /// No description provided for @kindOutsideService.
  ///
  /// In fr, this message translates to:
  /// **'Service extérieur'**
  String get kindOutsideService;

  /// No description provided for @kindVigil.
  ///
  /// In fr, this message translates to:
  /// **'Grande veillée'**
  String get kindVigil;

  /// No description provided for @kindMeeting.
  ///
  /// In fr, this message translates to:
  /// **'Réunion'**
  String get kindMeeting;

  /// No description provided for @kindOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get kindOther;

  /// No description provided for @dressInside.
  ///
  /// In fr, this message translates to:
  /// **'Tenue intérieure'**
  String get dressInside;

  /// No description provided for @dressOutside.
  ///
  /// In fr, this message translates to:
  /// **'Tenue extérieure'**
  String get dressOutside;

  /// No description provided for @dressSport.
  ///
  /// In fr, this message translates to:
  /// **'Tenue sportive'**
  String get dressSport;

  /// No description provided for @dressCivil.
  ///
  /// In fr, this message translates to:
  /// **'Tenue civile'**
  String get dressCivil;

  /// No description provided for @dressNone.
  ///
  /// In fr, this message translates to:
  /// **'Pas de tenue imposée'**
  String get dressNone;

  /// No description provided for @myPresence.
  ///
  /// In fr, this message translates to:
  /// **'Ma présence'**
  String get myPresence;

  /// No description provided for @presenceNotMarked.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore marquée'**
  String get presenceNotMarked;

  /// No description provided for @presenceNotMarkedSub.
  ///
  /// In fr, this message translates to:
  /// **'Le censeur fait l’appel sur place'**
  String get presenceNotMarkedSub;

  /// No description provided for @presencePresent.
  ///
  /// In fr, this message translates to:
  /// **'Présent'**
  String get presencePresent;

  /// No description provided for @presenceAbsent.
  ///
  /// In fr, this message translates to:
  /// **'Absent'**
  String get presenceAbsent;

  /// No description provided for @presenceExcused.
  ///
  /// In fr, this message translates to:
  /// **'Excusé'**
  String get presenceExcused;

  /// No description provided for @warnAbsence.
  ///
  /// In fr, this message translates to:
  /// **'Prévenir d’une absence'**
  String get warnAbsence;

  /// No description provided for @absenceReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif (facultatif)'**
  String get absenceReason;

  /// No description provided for @absenceSent.
  ///
  /// In fr, this message translates to:
  /// **'Absence signalée au censeur.'**
  String get absenceSent;

  /// No description provided for @alreadyMarked.
  ///
  /// In fr, this message translates to:
  /// **'La présence est déjà marquée par le censeur.'**
  String get alreadyMarked;

  /// No description provided for @takeRollCall.
  ///
  /// In fr, this message translates to:
  /// **'Faire l’appel'**
  String get takeRollCall;

  /// No description provided for @rollCallTitle.
  ///
  /// In fr, this message translates to:
  /// **'Appel · {title}'**
  String rollCallTitle(String title);

  /// No description provided for @statPresent.
  ///
  /// In fr, this message translates to:
  /// **'Présents'**
  String get statPresent;

  /// No description provided for @statAbsent.
  ///
  /// In fr, this message translates to:
  /// **'Absents'**
  String get statAbsent;

  /// No description provided for @statExcused.
  ///
  /// In fr, this message translates to:
  /// **'Excusés'**
  String get statExcused;

  /// No description provided for @statRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Restants'**
  String get statRemaining;

  /// No description provided for @remote.
  ///
  /// In fr, this message translates to:
  /// **'À distance'**
  String get remote;

  /// No description provided for @rollCallSaved.
  ///
  /// In fr, this message translates to:
  /// **'Appel enregistré.'**
  String get rollCallSaved;

  /// No description provided for @unsavedChanges.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 modification non enregistrée} other{{n} modifications non enregistrées}}'**
  String unsavedChanges(int n);

  /// No description provided for @eventKind.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get eventKind;

  /// No description provided for @eventTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get eventTitle;

  /// No description provided for @eventDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get eventDate;

  /// No description provided for @eventStart.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get eventStart;

  /// No description provided for @eventEnd.
  ///
  /// In fr, this message translates to:
  /// **'Fin (facultatif)'**
  String get eventEnd;

  /// No description provided for @eventPlace.
  ///
  /// In fr, this message translates to:
  /// **'Lieu'**
  String get eventPlace;

  /// No description provided for @eventDress.
  ///
  /// In fr, this message translates to:
  /// **'Tenue'**
  String get eventDress;

  /// No description provided for @eventNotes.
  ///
  /// In fr, this message translates to:
  /// **'Notes'**
  String get eventNotes;

  /// No description provided for @eventEndBeforeStart.
  ///
  /// In fr, this message translates to:
  /// **'La fin doit être après le début.'**
  String get eventEndBeforeStart;

  /// No description provided for @eventCreated.
  ///
  /// In fr, this message translates to:
  /// **'Événement ajouté au calendrier.'**
  String get eventCreated;

  /// No description provided for @nightUntil.
  ///
  /// In fr, this message translates to:
  /// **'→ {time} · nuit'**
  String nightUntil(String time);

  /// No description provided for @filterAnnAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get filterAnnAll;

  /// No description provided for @filterConvocations.
  ///
  /// In fr, this message translates to:
  /// **'Convocations'**
  String get filterConvocations;

  /// No description provided for @filterUnread.
  ///
  /// In fr, this message translates to:
  /// **'Non lues {n}'**
  String filterUnread(int n);

  /// No description provided for @filterSent.
  ///
  /// In fr, this message translates to:
  /// **'Envoyées'**
  String get filterSent;

  /// No description provided for @kindAnnouncement.
  ///
  /// In fr, this message translates to:
  /// **'Annonce'**
  String get kindAnnouncement;

  /// No description provided for @kindConvocation.
  ///
  /// In fr, this message translates to:
  /// **'Convocation'**
  String get kindConvocation;

  /// No description provided for @pinned.
  ///
  /// In fr, this message translates to:
  /// **'Épinglé'**
  String get pinned;

  /// No description provided for @unreadDot.
  ///
  /// In fr, this message translates to:
  /// **'Non lu'**
  String get unreadDot;

  /// No description provided for @readBy.
  ///
  /// In fr, this message translates to:
  /// **'Lu par {read} sur {total}'**
  String readBy(int read, int total);

  /// No description provided for @compose.
  ///
  /// In fr, this message translates to:
  /// **'Rédiger'**
  String get compose;

  /// No description provided for @newAnnouncement.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle annonce'**
  String get newAnnouncement;

  /// No description provided for @message.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @linkedEvent.
  ///
  /// In fr, this message translates to:
  /// **'Événement lié'**
  String get linkedEvent;

  /// No description provided for @chooseEvent.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un événement'**
  String get chooseEvent;

  /// No description provided for @eventRequired.
  ///
  /// In fr, this message translates to:
  /// **'Une convocation doit être liée à un événement.'**
  String get eventRequired;

  /// No description provided for @pinOnTop.
  ///
  /// In fr, this message translates to:
  /// **'Épingler en tête du fil'**
  String get pinOnTop;

  /// No description provided for @recipientsAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous les membres'**
  String get recipientsAll;

  /// No description provided for @sendAnnouncement.
  ///
  /// In fr, this message translates to:
  /// **'Publier l’annonce'**
  String get sendAnnouncement;

  /// No description provided for @sendConvocation.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la convocation'**
  String get sendConvocation;

  /// No description provided for @announcementSent.
  ///
  /// In fr, this message translates to:
  /// **'Publié.'**
  String get announcementSent;

  /// No description provided for @allRead.
  ///
  /// In fr, this message translates to:
  /// **'Tout est lu'**
  String get allRead;

  /// No description provided for @allReadBody.
  ///
  /// In fr, this message translates to:
  /// **'Les nouvelles annonces et convocations du bureau apparaîtront ici.'**
  String get allReadBody;

  /// No description provided for @noAnnouncements.
  ///
  /// In fr, this message translates to:
  /// **'Aucune annonce'**
  String get noAnnouncements;

  /// No description provided for @readReceipts.
  ///
  /// In fr, this message translates to:
  /// **'Accusés de lecture'**
  String get readReceipts;

  /// No description provided for @notReadYet.
  ///
  /// In fr, this message translates to:
  /// **'Non lu {n}'**
  String notReadYet(int n);

  /// No description provided for @readTab.
  ///
  /// In fr, this message translates to:
  /// **'Lu {n}'**
  String readTab(int n);

  /// No description provided for @nextMeeting.
  ///
  /// In fr, this message translates to:
  /// **'Prochain rendez-vous'**
  String get nextMeeting;

  /// No description provided for @lastAnnouncement.
  ///
  /// In fr, this message translates to:
  /// **'Dernière annonce'**
  String get lastAnnouncement;

  /// No description provided for @nothingPlanned.
  ///
  /// In fr, this message translates to:
  /// **'Rien de prévu pour l’instant.'**
  String get nothingPlanned;

  /// No description provided for @calendarLink.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get calendarLink;

  /// No description provided for @allAnnouncements.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get allAnnouncements;

  /// No description provided for @myAccount.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get myAccount;

  /// No description provided for @readStatus.
  ///
  /// In fr, this message translates to:
  /// **'Lu'**
  String get readStatus;

  /// No description provided for @openAccount.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir mon compte'**
  String get openAccount;

  /// No description provided for @unreadCount.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 annonce non lue} other{{n} annonces non lues}}'**
  String unreadCount(int n);

  /// No description provided for @changePin.
  ///
  /// In fr, this message translates to:
  /// **'Changer mon code PIN'**
  String get changePin;

  /// No description provided for @choosePinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre code PIN'**
  String get choosePinTitle;

  /// No description provided for @choosePinForced.
  ///
  /// In fr, this message translates to:
  /// **'Votre code actuel est provisoire. Choisissez un code à 4 chiffres que vous seul connaissez.'**
  String get choosePinForced;

  /// No description provided for @currentPin.
  ///
  /// In fr, this message translates to:
  /// **'Code actuel'**
  String get currentPin;

  /// No description provided for @newPin.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code'**
  String get newPin;

  /// No description provided for @confirmPin.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le nouveau code'**
  String get confirmPin;

  /// No description provided for @pinMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les deux codes ne sont pas identiques.'**
  String get pinMismatch;

  /// No description provided for @pinFourDigits.
  ///
  /// In fr, this message translates to:
  /// **'4 chiffres.'**
  String get pinFourDigits;

  /// No description provided for @pinTooSimple.
  ///
  /// In fr, this message translates to:
  /// **'Code trop simple (1111, 1234…). Choisissez-en un autre.'**
  String get pinTooSimple;

  /// No description provided for @pinChanged.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN modifié.'**
  String get pinChanged;

  /// No description provided for @forgotTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN oublié'**
  String get forgotTitle;

  /// No description provided for @forgotIntro.
  ///
  /// In fr, this message translates to:
  /// **'Nous envoyons un code par SMS au numéro du compte.'**
  String get forgotIntro;

  /// No description provided for @sendCode.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le code'**
  String get sendCode;

  /// No description provided for @smsCode.
  ///
  /// In fr, this message translates to:
  /// **'Code reçu par SMS'**
  String get smsCode;

  /// No description provided for @badCode.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect ou expiré.'**
  String get badCode;

  /// No description provided for @smsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'L’envoi de SMS n’est pas encore disponible. Demandez au responsable de votre groupe de réinitialiser votre code.'**
  String get smsUnavailable;

  /// No description provided for @resetPin.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser le code PIN'**
  String get resetPin;

  /// No description provided for @resetPinConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Un nouveau code provisoire sera créé pour {name}. L’ancien ne fonctionnera plus.'**
  String resetPinConfirm(String name);

  /// No description provided for @resetPinDone.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code provisoire de {name} : {pin}. Communiquez-le en personne ; il ne sera plus affiché.'**
  String resetPinDone(String name, String pin);

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @attachFile.
  ///
  /// In fr, this message translates to:
  /// **'Joindre un fichier (PDF, photo)'**
  String get attachFile;

  /// No description provided for @attachHint.
  ///
  /// In fr, this message translates to:
  /// **'PDF, JPEG ou PNG · 10 Mo maximum'**
  String get attachHint;

  /// No description provided for @fileTooLarge.
  ///
  /// In fr, this message translates to:
  /// **'Fichier trop lourd (10 Mo maximum).'**
  String get fileTooLarge;

  /// No description provided for @fileType.
  ///
  /// In fr, this message translates to:
  /// **'Seuls les PDF, JPEG et PNG sont acceptés.'**
  String get fileType;

  /// No description provided for @attachmentFailed.
  ///
  /// In fr, this message translates to:
  /// **'Annonce publiée, mais « {name} » n’a pas pu être joint.'**
  String attachmentFailed(String name);

  /// No description provided for @openFileFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’ouvrir le fichier.'**
  String get openFileFailed;

  /// No description provided for @removeFile.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get removeFile;

  /// No description provided for @sizeKb.
  ///
  /// In fr, this message translates to:
  /// **'{n} Ko'**
  String sizeKb(int n);

  /// No description provided for @sizeMb.
  ///
  /// In fr, this message translates to:
  /// **'{n} Mo'**
  String sizeMb(String n);

  /// No description provided for @cashBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde de la caisse'**
  String get cashBalance;

  /// No description provided for @validatedUntil.
  ///
  /// In fr, this message translates to:
  /// **'Validé jusqu’au {date}'**
  String validatedUntil(String date);

  /// No description provided for @withPending.
  ///
  /// In fr, this message translates to:
  /// **'{amount} en comptant les opérations à valider'**
  String withPending(String amount);

  /// No description provided for @cashBook.
  ///
  /// In fr, this message translates to:
  /// **'Livre de caisse'**
  String get cashBook;

  /// No description provided for @solidarity.
  ///
  /// In fr, this message translates to:
  /// **'Solidarité'**
  String get solidarity;

  /// No description provided for @report.
  ///
  /// In fr, this message translates to:
  /// **'Rapport'**
  String get report;

  /// No description provided for @newEntry.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle opération'**
  String get newEntry;

  /// No description provided for @entryButton.
  ///
  /// In fr, this message translates to:
  /// **'Opération'**
  String get entryButton;

  /// No description provided for @directionIn.
  ///
  /// In fr, this message translates to:
  /// **'Entrée'**
  String get directionIn;

  /// No description provided for @directionOut.
  ///
  /// In fr, this message translates to:
  /// **'Sortie'**
  String get directionOut;

  /// No description provided for @amount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get amount;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get category;

  /// No description provided for @catRegistration.
  ///
  /// In fr, this message translates to:
  /// **'Inscriptions'**
  String get catRegistration;

  /// No description provided for @catFine.
  ///
  /// In fr, this message translates to:
  /// **'Amendes'**
  String get catFine;

  /// No description provided for @catDonation.
  ///
  /// In fr, this message translates to:
  /// **'Aides et dons'**
  String get catDonation;

  /// No description provided for @catSolidarity.
  ///
  /// In fr, this message translates to:
  /// **'Contributions de solidarité'**
  String get catSolidarity;

  /// No description provided for @catExpense.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get catExpense;

  /// No description provided for @member.
  ///
  /// In fr, this message translates to:
  /// **'Membre'**
  String get member;

  /// No description provided for @memberOptional.
  ///
  /// In fr, this message translates to:
  /// **'Membre (facultatif)'**
  String get memberOptional;

  /// No description provided for @chooseMember.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un membre'**
  String get chooseMember;

  /// No description provided for @description.
  ///
  /// In fr, this message translates to:
  /// **'Libellé'**
  String get description;

  /// No description provided for @amountRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un montant.'**
  String get amountRequired;

  /// No description provided for @willBeValidated.
  ///
  /// In fr, this message translates to:
  /// **'Sera validée par le commissaire aux comptes.'**
  String get willBeValidated;

  /// No description provided for @enteredBy.
  ///
  /// In fr, this message translates to:
  /// **'Saisi par {name} · {when}'**
  String enteredBy(String name, String when);

  /// No description provided for @validatedBy.
  ///
  /// In fr, this message translates to:
  /// **'Validé par {name}'**
  String validatedBy(String name);

  /// No description provided for @toValidate.
  ///
  /// In fr, this message translates to:
  /// **'À valider'**
  String get toValidate;

  /// No description provided for @validated.
  ///
  /// In fr, this message translates to:
  /// **'Validé'**
  String get validated;

  /// No description provided for @notSentYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore envoyé'**
  String get notSentYet;

  /// No description provided for @validateEntryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Valider cette opération ?'**
  String get validateEntryTitle;

  /// No description provided for @validateEntryBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre nom et l’heure seront enregistrés. Une opération validée ne peut plus être modifiée.'**
  String get validateEntryBody;

  /// No description provided for @validate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// No description provided for @entryValidated.
  ///
  /// In fr, this message translates to:
  /// **'Opération validée.'**
  String get entryValidated;

  /// No description provided for @entrySaved.
  ///
  /// In fr, this message translates to:
  /// **'Opération enregistrée, en attente de validation.'**
  String get entrySaved;

  /// No description provided for @ownEntry.
  ///
  /// In fr, this message translates to:
  /// **'On ne peut pas valider sa propre saisie.'**
  String get ownEntry;

  /// No description provided for @noEntries.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération pour l’instant.'**
  String get noEntries;

  /// No description provided for @collections.
  ///
  /// In fr, this message translates to:
  /// **'Collectes'**
  String get collections;

  /// No description provided for @newCollection.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle collecte'**
  String get newCollection;

  /// No description provided for @collectionKind.
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get collectionKind;

  /// No description provided for @kindDeath.
  ///
  /// In fr, this message translates to:
  /// **'Décès'**
  String get kindDeath;

  /// No description provided for @kindIllness.
  ///
  /// In fr, this message translates to:
  /// **'Maladie'**
  String get kindIllness;

  /// No description provided for @kindMedal.
  ///
  /// In fr, this message translates to:
  /// **'Médaille, diplôme, sacrement'**
  String get kindMedal;

  /// No description provided for @amountPerMember.
  ///
  /// In fr, this message translates to:
  /// **'Montant par membre'**
  String get amountPerMember;

  /// No description provided for @paidFullOf.
  ///
  /// In fr, this message translates to:
  /// **'{paid} sur {total} ont tout payé'**
  String paidFullOf(int paid, int total);

  /// No description provided for @tranchesInfo.
  ///
  /// In fr, this message translates to:
  /// **'Tranches de {parts}, une par semaine sur un mois.'**
  String tranchesInfo(String parts);

  /// No description provided for @filterToPay.
  ///
  /// In fr, this message translates to:
  /// **'À payer {n}'**
  String filterToPay(int n);

  /// No description provided for @filterPaid.
  ///
  /// In fr, this message translates to:
  /// **'Payé {n}'**
  String filterPaid(int n);

  /// No description provided for @thirdsOf3.
  ///
  /// In fr, this message translates to:
  /// **'{n}/3 tranches'**
  String thirdsOf3(int n);

  /// No description provided for @paidInFull.
  ///
  /// In fr, this message translates to:
  /// **'Payé'**
  String get paidInFull;

  /// No description provided for @savePayments.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Enregistrer 1 paiement · {amount}} other{Enregistrer {n} paiements · {amount}}}'**
  String savePayments(int n, String amount);

  /// No description provided for @paymentsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Paiements enregistrés.'**
  String get paymentsSaved;

  /// No description provided for @closeCollection.
  ///
  /// In fr, this message translates to:
  /// **'Clôturer la collecte'**
  String get closeCollection;

  /// No description provided for @closeCollectionBody.
  ///
  /// In fr, this message translates to:
  /// **'Les membres restants seront notés « non payé ».'**
  String get closeCollectionBody;

  /// No description provided for @closed.
  ///
  /// In fr, this message translates to:
  /// **'Clôturée'**
  String get closed;

  /// No description provided for @noCollections.
  ///
  /// In fr, this message translates to:
  /// **'Aucune collecte.'**
  String get noCollections;

  /// No description provided for @quarterReport.
  ///
  /// In fr, this message translates to:
  /// **'Rapport T{q} {year}'**
  String quarterReport(int q, int year);

  /// No description provided for @summary.
  ///
  /// In fr, this message translates to:
  /// **'Synthèse'**
  String get summary;

  /// No description provided for @openingBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde d’ouverture'**
  String get openingBalance;

  /// No description provided for @closingBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde de clôture'**
  String get closingBalance;

  /// No description provided for @incomeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Entrées'**
  String get incomeLabel;

  /// No description provided for @expenseLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sorties'**
  String get expenseLabel;

  /// No description provided for @incomeByCategory.
  ///
  /// In fr, this message translates to:
  /// **'Entrées par catégorie'**
  String get incomeByCategory;

  /// No description provided for @pendingBlock.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 opération reste à vérifier avant de valider.} other{{n} opérations restent à vérifier avant de valider.}}'**
  String pendingBlock(int n);

  /// No description provided for @validateReport.
  ///
  /// In fr, this message translates to:
  /// **'Valider le rapport'**
  String get validateReport;

  /// No description provided for @reportValidatedBy.
  ///
  /// In fr, this message translates to:
  /// **'Validé par {name} le {date}'**
  String reportValidatedBy(String name, String date);

  /// No description provided for @previousQuarter.
  ///
  /// In fr, this message translates to:
  /// **'Trimestre précédent'**
  String get previousQuarter;

  /// No description provided for @nextQuarter.
  ///
  /// In fr, this message translates to:
  /// **'Trimestre suivant'**
  String get nextQuarter;

  /// No description provided for @myContributions.
  ///
  /// In fr, this message translates to:
  /// **'Mes contributions'**
  String get myContributions;

  /// No description provided for @toPayLabel.
  ///
  /// In fr, this message translates to:
  /// **'À payer'**
  String get toPayLabel;

  /// No description provided for @nothingToPay.
  ///
  /// In fr, this message translates to:
  /// **'Rien à payer. Merci !'**
  String get nothingToPay;

  /// No description provided for @remainingOf.
  ///
  /// In fr, this message translates to:
  /// **'Reste {remaining} sur {total}'**
  String remainingOf(String remaining, String total);

  /// No description provided for @fine.
  ///
  /// In fr, this message translates to:
  /// **'Amende'**
  String get fine;

  /// No description provided for @planningView.
  ///
  /// In fr, this message translates to:
  /// **'Planning'**
  String get planningView;

  /// No description provided for @myDutiesView.
  ///
  /// In fr, this message translates to:
  /// **'Mes services'**
  String get myDutiesView;

  /// No description provided for @weekOf.
  ///
  /// In fr, this message translates to:
  /// **'Semaine du {start} au {end}'**
  String weekOf(String start, String end);

  /// No description provided for @previousWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine précédente'**
  String get previousWeek;

  /// No description provided for @nextWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine suivante'**
  String get nextWeek;

  /// No description provided for @postPremiereCentrale.
  ///
  /// In fr, this message translates to:
  /// **'Première centrale'**
  String get postPremiereCentrale;

  /// No description provided for @postDeuxiemeCentrale.
  ///
  /// In fr, this message translates to:
  /// **'Deuxième centrale'**
  String get postDeuxiemeCentrale;

  /// No description provided for @postControle.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle'**
  String get postControle;

  /// No description provided for @postPetitesPortes.
  ///
  /// In fr, this message translates to:
  /// **'Petites portes'**
  String get postPetitesPortes;

  /// No description provided for @postMesanie.
  ///
  /// In fr, this message translates to:
  /// **'Mésanie'**
  String get postMesanie;

  /// No description provided for @sidePariso.
  ///
  /// In fr, this message translates to:
  /// **'Pariso'**
  String get sidePariso;

  /// No description provided for @sideYapoma.
  ///
  /// In fr, this message translates to:
  /// **'Yapoma'**
  String get sideYapoma;

  /// No description provided for @freeSlot.
  ///
  /// In fr, this message translates to:
  /// **'+ Libre'**
  String get freeSlot;

  /// No description provided for @chefLabel.
  ///
  /// In fr, this message translates to:
  /// **'Chef : {name}'**
  String chefLabel(String name);

  /// No description provided for @filledOf.
  ///
  /// In fr, this message translates to:
  /// **'{filled}/{size}'**
  String filledOf(int filled, int size);

  /// No description provided for @alertsCount.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 alerte} other{{n} alertes}}'**
  String alertsCount(int n);

  /// No description provided for @alertUnderstaffed.
  ///
  /// In fr, this message translates to:
  /// **'{title} : {filled} sur {size}'**
  String alertUnderstaffed(String title, int filled, int size);

  /// No description provided for @alertDouble.
  ///
  /// In fr, this message translates to:
  /// **'{name} a deux services le même jour'**
  String alertDouble(String name);

  /// No description provided for @alertOnLeave.
  ///
  /// In fr, this message translates to:
  /// **'{name} est en congé'**
  String alertOnLeave(String name);

  /// No description provided for @publishAndNotify.
  ///
  /// In fr, this message translates to:
  /// **'Publier et notifier'**
  String get publishAndNotify;

  /// No description provided for @published.
  ///
  /// In fr, this message translates to:
  /// **'Publié'**
  String get published;

  /// No description provided for @publishedDone.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Planning publié · 1 garde notifié.} other{Planning publié · {n} gardes notifiés.}}'**
  String publishedDone(int n);

  /// No description provided for @noServicesWeek.
  ///
  /// In fr, this message translates to:
  /// **'Aucun service prévu cette semaine.'**
  String get noServicesWeek;

  /// No description provided for @setServiceSize.
  ///
  /// In fr, this message translates to:
  /// **'Prévoir le service'**
  String get setServiceSize;

  /// No description provided for @serviceSize.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de gardes'**
  String get serviceSize;

  /// No description provided for @assignGroup.
  ///
  /// In fr, this message translates to:
  /// **'Affecter un groupe'**
  String get assignGroup;

  /// No description provided for @groupAssigned.
  ///
  /// In fr, this message translates to:
  /// **'{assigned} postes remplis · {empty} encore libres'**
  String groupAssigned(int assigned, int empty);

  /// No description provided for @groupMembersInfo.
  ///
  /// In fr, this message translates to:
  /// **'{n} gardes · {available} disponibles'**
  String groupMembersInfo(int n, int available);

  /// No description provided for @leastSolicitedFirst.
  ///
  /// In fr, this message translates to:
  /// **'Les moins sollicités en premier'**
  String get leastSolicitedFirst;

  /// No description provided for @servicesThisMonth.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucun service ce mois} =1{1 service ce mois} other{{n} services ce mois}}'**
  String servicesThisMonth(int n);

  /// No description provided for @flagBusy.
  ///
  /// In fr, this message translates to:
  /// **'Déjà de service ce jour-là'**
  String get flagBusy;

  /// No description provided for @flagLeave.
  ///
  /// In fr, this message translates to:
  /// **'En congé'**
  String get flagLeave;

  /// No description provided for @flagMany.
  ///
  /// In fr, this message translates to:
  /// **'Déjà beaucoup de services ce mois'**
  String get flagMany;

  /// No description provided for @assign.
  ///
  /// In fr, this message translates to:
  /// **'Affecter'**
  String get assign;

  /// No description provided for @assignAnyway.
  ///
  /// In fr, this message translates to:
  /// **'Quand même'**
  String get assignAnyway;

  /// No description provided for @clearSlot.
  ///
  /// In fr, this message translates to:
  /// **'Libérer le poste'**
  String get clearSlot;

  /// No description provided for @dutyPending.
  ///
  /// In fr, this message translates to:
  /// **'À confirmer'**
  String get dutyPending;

  /// No description provided for @dutyConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmé'**
  String get dutyConfirmed;

  /// No description provided for @dutySwap.
  ///
  /// In fr, this message translates to:
  /// **'Échange demandé'**
  String get dutySwap;

  /// No description provided for @dutyReplaced.
  ///
  /// In fr, this message translates to:
  /// **'Remplacé'**
  String get dutyReplaced;

  /// No description provided for @dutyAbsent.
  ///
  /// In fr, this message translates to:
  /// **'Absence déclarée'**
  String get dutyAbsent;

  /// No description provided for @conflict.
  ///
  /// In fr, this message translates to:
  /// **'Conflit'**
  String get conflict;

  /// No description provided for @confirmDuty.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirmDuty;

  /// No description provided for @swapDuty.
  ///
  /// In fr, this message translates to:
  /// **'Échanger'**
  String get swapDuty;

  /// No description provided for @swapTitle.
  ///
  /// In fr, this message translates to:
  /// **'Échanger mon service'**
  String get swapTitle;

  /// No description provided for @withWhom.
  ///
  /// In fr, this message translates to:
  /// **'Avec qui ?'**
  String get withWhom;

  /// No description provided for @reasonOptional.
  ///
  /// In fr, this message translates to:
  /// **'Raison (facultatif)'**
  String get reasonOptional;

  /// No description provided for @sendRequest.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la demande'**
  String get sendRequest;

  /// No description provided for @declareAbsence.
  ///
  /// In fr, this message translates to:
  /// **'Je ne pourrai pas venir'**
  String get declareAbsence;

  /// No description provided for @requestSent.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée.'**
  String get requestSent;

  /// No description provided for @noDuties.
  ///
  /// In fr, this message translates to:
  /// **'Aucun service prévu pour vous.'**
  String get noDuties;

  /// No description provided for @myNextDuty.
  ///
  /// In fr, this message translates to:
  /// **'Mon prochain service'**
  String get myNextDuty;

  /// No description provided for @requests.
  ///
  /// In fr, this message translates to:
  /// **'Demandes'**
  String get requests;

  /// No description provided for @requestsPending.
  ///
  /// In fr, this message translates to:
  /// **'{n} en attente'**
  String requestsPending(int n);

  /// No description provided for @swapForYou.
  ///
  /// In fr, this message translates to:
  /// **'{name} vous propose son service'**
  String swapForYou(String name);

  /// No description provided for @accept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get accept;

  /// No description provided for @refuse.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get refuse;

  /// No description provided for @approve.
  ///
  /// In fr, this message translates to:
  /// **'Approuver'**
  String get approve;

  /// No description provided for @swapLine.
  ///
  /// In fr, this message translates to:
  /// **'{from} ⇄ {to}'**
  String swapLine(String from, String to);

  /// No description provided for @absenceLine.
  ///
  /// In fr, this message translates to:
  /// **'Absence · {name}'**
  String absenceLine(String name);

  /// No description provided for @chooseReplacement.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un remplaçant'**
  String get chooseReplacement;

  /// No description provided for @noRequests.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande en attente.'**
  String get noRequests;

  /// No description provided for @albs.
  ///
  /// In fr, this message translates to:
  /// **'Lavage des aubes'**
  String get albs;

  /// No description provided for @albsWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine du {date}'**
  String albsWeek(String date);

  /// No description provided for @albsCount.
  ///
  /// In fr, this message translates to:
  /// **'{n} aubes'**
  String albsCount(int n);

  /// No description provided for @albToWash.
  ///
  /// In fr, this message translates to:
  /// **'À laver'**
  String get albToWash;

  /// No description provided for @albWashed.
  ///
  /// In fr, this message translates to:
  /// **'Lavées'**
  String get albWashed;

  /// No description provided for @albReturned.
  ///
  /// In fr, this message translates to:
  /// **'Rendues'**
  String get albReturned;

  /// No description provided for @markWashed.
  ///
  /// In fr, this message translates to:
  /// **'Marquer « lavées »'**
  String get markWashed;

  /// No description provided for @markReturned.
  ///
  /// In fr, this message translates to:
  /// **'Marquer « rendues »'**
  String get markReturned;

  /// No description provided for @nextWeeks.
  ///
  /// In fr, this message translates to:
  /// **'Prochaines semaines'**
  String get nextWeeks;

  /// No description provided for @fairness12.
  ///
  /// In fr, this message translates to:
  /// **'Équité · lavages sur 12 mois'**
  String get fairness12;

  /// No description provided for @scheduleAlbs.
  ///
  /// In fr, this message translates to:
  /// **'Programmer une semaine'**
  String get scheduleAlbs;

  /// No description provided for @responsible.
  ///
  /// In fr, this message translates to:
  /// **'Responsable : {name}'**
  String responsible(String name);

  /// No description provided for @noAlbs.
  ///
  /// In fr, this message translates to:
  /// **'Aucune semaine programmée.'**
  String get noAlbs;

  /// No description provided for @group.
  ///
  /// In fr, this message translates to:
  /// **'Groupe'**
  String get group;

  /// No description provided for @groups.
  ///
  /// In fr, this message translates to:
  /// **'Groupes'**
  String get groups;

  /// No description provided for @planned.
  ///
  /// In fr, this message translates to:
  /// **'Prévu'**
  String get planned;

  /// No description provided for @notificationsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification.'**
  String get notificationsEmpty;

  /// No description provided for @markAllRead.
  ///
  /// In fr, this message translates to:
  /// **'Tout lire'**
  String get markAllRead;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get thisWeek;

  /// No description provided for @earlier.
  ///
  /// In fr, this message translates to:
  /// **'Plus ancien'**
  String get earlier;

  /// No description provided for @offlineBar.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get offlineBar;

  /// No description provided for @offlinePending.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Hors ligne · 1 saisie en attente d’envoi} other{Hors ligne · {n} saisies en attente d’envoi}}'**
  String offlinePending(int n);

  /// No description provided for @syncedAt.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisé · dernière synchronisation {time}'**
  String syncedAt(String time);

  /// No description provided for @syncing.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation en cours…'**
  String get syncing;

  /// No description provided for @offlineSince.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne · dernière synchronisation {time}'**
  String offlineSince(String time);

  /// No description provided for @syncFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la synchronisation'**
  String get syncFailed;

  /// No description provided for @savedOnPhone.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré sur le téléphone. Envoi dès le retour du réseau.'**
  String get savedOnPhone;

  /// No description provided for @pendingSend.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 envoi en attente} other{{n} envois en attente}}'**
  String pendingSend(int n);

  /// No description provided for @never.
  ///
  /// In fr, this message translates to:
  /// **'jamais'**
  String get never;

  /// No description provided for @addPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get addPhoto;

  /// No description provided for @changePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo'**
  String get changePhoto;

  /// No description provided for @photoSaved.
  ///
  /// In fr, this message translates to:
  /// **'Photo enregistrée.'**
  String get photoSaved;

  /// No description provided for @registrationFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais d’inscription payés'**
  String get registrationFee;

  /// No description provided for @registrationFeeSub.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté au livre de caisse, en attente de validation'**
  String get registrationFeeSub;

  /// No description provided for @presenceLast4.
  ///
  /// In fr, this message translates to:
  /// **'Présences · 4 dernières assises'**
  String get presenceLast4;

  /// No description provided for @presenceSummary.
  ///
  /// In fr, this message translates to:
  /// **'{present} présent · {absent} absent · {excused} excusé'**
  String presenceSummary(int present, int absent, int excused);

  /// No description provided for @lastOn.
  ///
  /// In fr, this message translates to:
  /// **'Dernière : {date}'**
  String lastOn(String date);

  /// No description provided for @proposeRole.
  ///
  /// In fr, this message translates to:
  /// **'Proposer un rôle'**
  String get proposeRole;

  /// No description provided for @roleRequestSent.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée au super admin.'**
  String get roleRequestSent;

  /// No description provided for @fromDate.
  ///
  /// In fr, this message translates to:
  /// **'Du'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In fr, this message translates to:
  /// **'Au (facultatif)'**
  String get toDate;

  /// No description provided for @reasonRequired.
  ///
  /// In fr, this message translates to:
  /// **'Motif (journalisé)'**
  String get reasonRequired;

  /// No description provided for @reminders.
  ///
  /// In fr, this message translates to:
  /// **'Rappels'**
  String get reminders;

  /// No description provided for @remindEve.
  ///
  /// In fr, this message translates to:
  /// **'La veille à 20:00'**
  String get remindEve;

  /// No description provided for @remind2h.
  ///
  /// In fr, this message translates to:
  /// **'2 heures avant'**
  String get remind2h;

  /// No description provided for @remindUnread.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Relancer le non-lecteur} other{Relancer les {n} non-lecteurs}}'**
  String remindUnread(int n);

  /// No description provided for @remindedDone.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 membre relancé.} other{{n} membres relancés.}}'**
  String remindedDone(int n);

  /// No description provided for @exportPdf.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en PDF'**
  String get exportPdf;

  /// No description provided for @toFollow.
  ///
  /// In fr, this message translates to:
  /// **'À suivre'**
  String get toFollow;

  /// No description provided for @activeMembers.
  ///
  /// In fr, this message translates to:
  /// **'Membres actifs'**
  String get activeMembers;

  /// No description provided for @entriesToValidate.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 opération à valider} other{{n} opérations à valider}}'**
  String entriesToValidate(int n);

  /// No description provided for @awaitingAuditor.
  ///
  /// In fr, this message translates to:
  /// **'En attente du commissaire aux comptes'**
  String get awaitingAuditor;

  /// No description provided for @unfilledSlots.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 poste non pourvu} other{{n} postes non pourvus}} · {title}'**
  String unfilledSlots(int n, String title);

  /// No description provided for @roleVicePresident.
  ///
  /// In fr, this message translates to:
  /// **'Vice-président'**
  String get roleVicePresident;

  /// No description provided for @roleSecretaryGeneralDeputy.
  ///
  /// In fr, this message translates to:
  /// **'Secrétaire général adjoint'**
  String get roleSecretaryGeneralDeputy;

  /// No description provided for @roleFormateurDeputy.
  ///
  /// In fr, this message translates to:
  /// **'Formateur adjoint'**
  String get roleFormateurDeputy;

  /// No description provided for @designateChef.
  ///
  /// In fr, this message translates to:
  /// **'Désigner le chef de groupe'**
  String get designateChef;

  /// No description provided for @chefSheetHint.
  ///
  /// In fr, this message translates to:
  /// **'Parmi les gardes de ce service.'**
  String get chefSheetHint;

  /// No description provided for @removeChef.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le chef de groupe'**
  String get removeChef;

  /// No description provided for @noChefYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de chef de groupe'**
  String get noChefYet;

  /// No description provided for @youAreChef.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes chef de groupe'**
  String get youAreChef;

  /// No description provided for @chefNeedsGuards.
  ///
  /// In fr, this message translates to:
  /// **'Affectez d’abord des gardes à ce service.'**
  String get chefNeedsGuards;

  /// No description provided for @statementPdf.
  ///
  /// In fr, this message translates to:
  /// **'Bilan général des membres (PDF)'**
  String get statementPdf;

  /// No description provided for @memberStatementPdf.
  ///
  /// In fr, this message translates to:
  /// **'Bilan financier (PDF)'**
  String get memberStatementPdf;

  /// No description provided for @errorBackofficeOnly.
  ///
  /// In fr, this message translates to:
  /// **'Les comptes super admin s’utilisent uniquement sur le back-office (navigateur web), pas dans l’application.'**
  String get errorBackofficeOnly;

  /// No description provided for @requestAccess.
  ///
  /// In fr, this message translates to:
  /// **'Demander un accès'**
  String get requestAccess;

  /// No description provided for @accessRequestsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demandes d’accès'**
  String get accessRequestsTitle;

  /// No description provided for @accessRole.
  ///
  /// In fr, this message translates to:
  /// **'Rôle demandé'**
  String get accessRole;

  /// No description provided for @accessNote.
  ///
  /// In fr, this message translates to:
  /// **'Message pour le partenaire (facultatif)'**
  String get accessNote;

  /// No description provided for @sendAccessRequest.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la demande'**
  String get sendAccessRequest;

  /// No description provided for @accessSentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée'**
  String get accessSentTitle;

  /// No description provided for @accessSentBody.
  ///
  /// In fr, this message translates to:
  /// **'Le partenaire MSG crée l’accès. Vous serez prévenu ici, avec le code provisoire à remettre au membre.'**
  String get accessSentBody;

  /// No description provided for @accessIntro.
  ///
  /// In fr, this message translates to:
  /// **'Le partenaire MSG ouvre le compte. Vous recevrez ensuite le code provisoire à remettre au membre.'**
  String get accessIntro;

  /// No description provided for @accessPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get accessPending;

  /// No description provided for @accessApproved.
  ///
  /// In fr, this message translates to:
  /// **'Accès créé'**
  String get accessApproved;

  /// No description provided for @accessRefused.
  ///
  /// In fr, this message translates to:
  /// **'Refusée'**
  String get accessRefused;

  /// No description provided for @showTempPin.
  ///
  /// In fr, this message translates to:
  /// **'Voir le code provisoire'**
  String get showTempPin;

  /// No description provided for @tempPinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code provisoire'**
  String get tempPinTitle;

  /// No description provided for @tempPinBody.
  ///
  /// In fr, this message translates to:
  /// **'Remettez ce code à {name} ({phone}). Il ne sera plus affiché. À sa première connexion, il choisira son propre code et verra son rôle.'**
  String tempPinBody(String name, String phone);

  /// No description provided for @accessExistingAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte existant : il se connecte avec son code habituel.'**
  String get accessExistingAccount;

  /// No description provided for @pinGone.
  ///
  /// In fr, this message translates to:
  /// **'Code déjà remis ou expiré. Demandez une réinitialisation au partenaire.'**
  String get pinGone;

  /// No description provided for @noAccessRequests.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande pour l’instant.'**
  String get noAccessRequests;

  /// No description provided for @switchGroup.
  ///
  /// In fr, this message translates to:
  /// **'Changer de groupe'**
  String get switchGroup;

  /// No description provided for @chooseGroup.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un groupe'**
  String get chooseGroup;

  /// No description provided for @errorNoGroup.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte n’appartient encore à aucun groupe. Demandez au responsable de votre groupe.'**
  String get errorNoGroup;

  /// No description provided for @platformTagline.
  ///
  /// In fr, this message translates to:
  /// **'La gestion de votre groupe : membres, caisse, calendrier, services, annonces.'**
  String get platformTagline;

  /// No description provided for @goodMorning.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In fr, this message translates to:
  /// **'Bon après-midi'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In fr, this message translates to:
  /// **'Bonsoir'**
  String get goodEvening;

  /// No description provided for @appearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearance;

  /// No description provided for @appColor.
  ///
  /// In fr, this message translates to:
  /// **'Couleur de l’application'**
  String get appColor;

  /// No description provided for @groupColorChoice.
  ///
  /// In fr, this message translates to:
  /// **'Couleur du groupe'**
  String get groupColorChoice;

  /// No description provided for @appColorHint.
  ///
  /// In fr, this message translates to:
  /// **'Pour ce téléphone. « Couleur du groupe » suit le réglage de votre groupe.'**
  String get appColorHint;

  /// No description provided for @colorN.
  ///
  /// In fr, this message translates to:
  /// **'Couleur {n}'**
  String colorN(int n);

  /// No description provided for @myPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil'**
  String get myPhoto;

  /// No description provided for @photoFromGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get photoFromGallery;

  /// No description provided for @photoFromCamera.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get photoFromCamera;

  /// No description provided for @removePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la photo'**
  String get removePhoto;

  /// No description provided for @photoRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Photo retirée.'**
  String get photoRemoved;

  /// No description provided for @requestDayRole.
  ///
  /// In fr, this message translates to:
  /// **'Demander un rôle du jour'**
  String get requestDayRole;

  /// No description provided for @dayRoleHint.
  ///
  /// In fr, this message translates to:
  /// **'Pour un membre actif sans rôle, le temps d’une journée. Le partenaire valide ; le rôle s’arrête le soir même.'**
  String get dayRoleHint;

  /// No description provided for @onDay.
  ///
  /// In fr, this message translates to:
  /// **'Le {date}'**
  String onDay(String date);

  /// No description provided for @dayRoleRequestSent.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée au partenaire.'**
  String get dayRoleRequestSent;

  /// No description provided for @unlockTitle.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre code PIN'**
  String get unlockTitle;

  /// No description provided for @unlockSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Pour ouvrir MSG.'**
  String get unlockSubtitle;

  /// No description provided for @unlockWrong.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect. Encore {n} essai(s).'**
  String unlockWrong(int n);

  /// No description provided for @unlockTooMany.
  ///
  /// In fr, this message translates to:
  /// **'Trop d’essais : reconnectez-vous avec votre numéro.'**
  String get unlockTooMany;

  /// No description provided for @unlockSignInAgain.
  ///
  /// In fr, this message translates to:
  /// **'Pour votre sécurité, reconnectez-vous une fois avec votre numéro et votre code.'**
  String get unlockSignInAgain;

  /// No description provided for @unlockOtherAccount.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter autrement'**
  String get unlockOtherAccount;

  /// No description provided for @biometricReason.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller MSG'**
  String get biometricReason;

  /// No description provided for @biometricUnlock.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller avec l’empreinte ou le visage'**
  String get biometricUnlock;

  /// No description provided for @biometricUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune empreinte ni visage enregistré sur ce téléphone.'**
  String get biometricUnavailable;

  /// No description provided for @biometricHint.
  ///
  /// In fr, this message translates to:
  /// **'Le code PIN reste toujours possible.'**
  String get biometricHint;

  /// No description provided for @addedBy.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté par'**
  String get addedBy;

  /// No description provided for @storageUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'L’envoi du fichier a échoué : le stockage est indisponible. Réessayez plus tard ; si cela continue, prévenez le partenaire.'**
  String get storageUnavailable;

  /// No description provided for @helpSection.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get helpSection;

  /// No description provided for @aboutSection.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get aboutSection;

  /// No description provided for @faq.
  ///
  /// In fr, this message translates to:
  /// **'Questions fréquentes'**
  String get faq;

  /// No description provided for @faqSub.
  ///
  /// In fr, this message translates to:
  /// **'Réponses aux questions courantes'**
  String get faqSub;

  /// No description provided for @helpSupport.
  ///
  /// In fr, this message translates to:
  /// **'Aide et assistance'**
  String get helpSupport;

  /// No description provided for @helpSupportSub.
  ///
  /// In fr, this message translates to:
  /// **'Appeler une vraie personne'**
  String get helpSupportSub;

  /// No description provided for @whatsappSupport.
  ///
  /// In fr, this message translates to:
  /// **'Assistance WhatsApp'**
  String get whatsappSupport;

  /// No description provided for @whatsappSupportSub.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez-nous sur WhatsApp'**
  String get whatsappSupportSub;

  /// No description provided for @contactUs.
  ///
  /// In fr, this message translates to:
  /// **'Nous contacter'**
  String get contactUs;

  /// No description provided for @contactUsSub.
  ///
  /// In fr, this message translates to:
  /// **'Questions ou suggestions'**
  String get contactUsSub;

  /// No description provided for @visitWebsite.
  ///
  /// In fr, this message translates to:
  /// **'Visiter notre site'**
  String get visitWebsite;

  /// No description provided for @privacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d’utilisation'**
  String get termsOfService;

  /// No description provided for @notAvailableYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore disponible'**
  String get notAvailableYet;

  /// No description provided for @appVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version {v}'**
  String appVersion(String v);

  /// No description provided for @faqQ1.
  ///
  /// In fr, this message translates to:
  /// **'J’ai oublié mon code PIN.'**
  String get faqQ1;

  /// No description provided for @faqA1.
  ///
  /// In fr, this message translates to:
  /// **'Sur l’écran du code, touchez « Code oublié ? ». Si les SMS ne sont pas disponibles, demandez au responsable de votre groupe : il peut vous donner un code provisoire.'**
  String get faqA1;

  /// No description provided for @faqQ2.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi l’application me demande-t-elle mon code à chaque ouverture ?'**
  String get faqQ2;

  /// No description provided for @faqA2.
  ///
  /// In fr, this message translates to:
  /// **'Pour protéger les données du groupe si quelqu’un prend votre téléphone. Vous pouvez déverrouiller avec l’empreinte ou le visage : Mon compte → Déverrouiller avec l’empreinte.'**
  String get faqA2;

  /// No description provided for @faqQ3.
  ///
  /// In fr, this message translates to:
  /// **'Je ne vois pas l’onglet Finances (ou un autre).'**
  String get faqQ3;

  /// No description provided for @faqA3.
  ///
  /// In fr, this message translates to:
  /// **'Les onglets dépendent de votre rôle dans le groupe. Si votre rôle change, ils s’adaptent à la prochaine ouverture.'**
  String get faqA3;

  /// No description provided for @faqQ4.
  ///
  /// In fr, this message translates to:
  /// **'Comment signaler une absence ?'**
  String get faqQ4;

  /// No description provided for @faqA4.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez l’activité dans le Calendrier et touchez « Prévenir d’une absence », avec le motif.'**
  String get faqA4;

  /// No description provided for @faqQ5.
  ///
  /// In fr, this message translates to:
  /// **'Qu’est-ce qu’un rôle du jour ?'**
  String get faqQ5;

  /// No description provided for @faqA5.
  ///
  /// In fr, this message translates to:
  /// **'Un membre actif sans rôle peut recevoir, pour une journée, un rôle comme président, censeur ou trésorier du jour. Il est demandé dans l’application et validé par le partenaire ; il s’arrête le soir même.'**
  String get faqA5;

  /// No description provided for @faqQ6.
  ///
  /// In fr, this message translates to:
  /// **'L’application marche-t-elle sans internet ?'**
  String get faqQ6;

  /// No description provided for @faqA6.
  ///
  /// In fr, this message translates to:
  /// **'Oui pour consulter ce qui a déjà été chargé et pour certaines saisies : elles partent dès que le réseau revient (bandeau « Hors ligne » en haut).'**
  String get faqA6;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
