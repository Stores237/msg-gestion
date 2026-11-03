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
  /// **'Huddle'**
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
  /// **'{n, plural, =0{Code incorrect. Il vous reste {n} essais.} =1{Code incorrect. Il vous reste 1 essai.} other{Code incorrect. Il vous reste {n} essais.}}'**
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
  /// **'{n, plural, =0{{n} modifications non enregistrées} =1{1 modification non enregistrée} other{{n} modifications non enregistrées}}'**
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

  /// No description provided for @photoCount.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{{n} photos} =1{1 photo} other{{n} photos}}'**
  String photoCount(int n);

  /// No description provided for @lastAnnouncement.
  ///
  /// In fr, this message translates to:
  /// **'Dernières annonces'**
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
  /// **'{n, plural, =0{{n} annonces non lues} =1{1 annonce non lue} other{{n} annonces non lues}}'**
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
  /// **'L’envoi de SMS n’est pas encore disponible. Demandez un code de récupération au responsable de votre groupe, puis touchez « J’ai un code de récupération ».'**
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
  /// **'L’autre responsable des finances (trésorier ou commissaire aux comptes) l’approuvera ; elle compte ensuite.'**
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
  /// **'{n, plural, =0{Enregistrer {n} paiements · {amount}} =1{Enregistrer 1 paiement · {amount}} other{Enregistrer {n} paiements · {amount}}}'**
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
  /// **'{n, plural, =0{{n} opérations restent à vérifier avant de valider.} =1{1 opération reste à vérifier avant de valider.} other{{n} opérations restent à vérifier avant de valider.}}'**
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
  /// **'{n, plural, =0{{n} alertes} =1{1 alerte} other{{n} alertes}}'**
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
  /// **'{n, plural, =0{Planning publié · {n} gardes notifiés.} =1{Planning publié · 1 garde notifié.} other{Planning publié · {n} gardes notifiés.}}'**
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
  /// **'{n, plural, =0{Hors ligne · {n} saisies en attente d’envoi} =1{Hors ligne · 1 saisie en attente d’envoi} other{Hors ligne · {n} saisies en attente d’envoi}}'**
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
  /// **'{n, plural, =0{{n} envois en attente} =1{1 envoi en attente} other{{n} envois en attente}}'**
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
  /// **'{n, plural, =0{Relancer les {n} non-lecteurs} =1{Relancer le non-lecteur} other{Relancer les {n} non-lecteurs}}'**
  String remindUnread(int n);

  /// No description provided for @remindedDone.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{{n} membres relancés.} =1{1 membre relancé.} other{{n} membres relancés.}}'**
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
  /// **'{n, plural, =0{{n} opérations à valider} =1{1 opération à valider} other{{n} opérations à valider}}'**
  String entriesToValidate(int n);

  /// No description provided for @awaitingAuditor.
  ///
  /// In fr, this message translates to:
  /// **'En attente de votre accord'**
  String get awaitingAuditor;

  /// No description provided for @unfilledSlots.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{{n} postes non pourvus} =1{1 poste non pourvu} other{{n} postes non pourvus}} · {title}'**
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
  /// **'Les comptes du back-office (super admin, équipes support, IT, intégrations) s’utilisent uniquement sur le back-office (navigateur web), pas dans l’application.'**
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
  /// **'Le partenaire Huddle crée l’accès. Vous serez prévenu ici, avec le code provisoire à remettre au membre.'**
  String get accessSentBody;

  /// No description provided for @accessIntro.
  ///
  /// In fr, this message translates to:
  /// **'Le partenaire Huddle ouvre le compte. Vous recevrez ensuite le code provisoire à remettre au membre.'**
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
  /// **'Choisissez votre groupe'**
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
  /// **'Pour ouvrir Huddle.'**
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
  /// **'Déverrouiller Huddle'**
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
  /// **'Version {version} ({build})'**
  String appVersion(String version, String build);

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

  /// No description provided for @editAction.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get editAction;

  /// No description provided for @deleteAction.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get deleteAction;

  /// No description provided for @editEvent.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l’événement'**
  String get editEvent;

  /// No description provided for @eventUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Événement modifié.'**
  String get eventUpdated;

  /// No description provided for @deleteEventConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {title} » du calendrier ? Les présences notées seront perdues.'**
  String deleteEventConfirm(String title);

  /// No description provided for @eventDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Événement supprimé.'**
  String get eventDeleted;

  /// No description provided for @editAnnouncement.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l’annonce'**
  String get editAnnouncement;

  /// No description provided for @announcementUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Annonce modifiée.'**
  String get announcementUpdated;

  /// No description provided for @deleteAnnouncementConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {title} » ? Elle disparaît pour tous les membres.'**
  String deleteAnnouncementConfirm(String title);

  /// No description provided for @announcementDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Annonce supprimée.'**
  String get announcementDeleted;

  /// No description provided for @termsAcceptPrefix.
  ///
  /// In fr, this message translates to:
  /// **'J’ai lu et j’accepte les '**
  String get termsAcceptPrefix;

  /// No description provided for @termsOfServiceLink.
  ///
  /// In fr, this message translates to:
  /// **'conditions d’utilisation'**
  String get termsOfServiceLink;

  /// No description provided for @termsRequired.
  ///
  /// In fr, this message translates to:
  /// **'Les conditions d’utilisation ont changé : revenez en arrière, relisez-les et cochez la case pour continuer.'**
  String get termsRequired;

  /// No description provided for @termsTickToContinue.
  ///
  /// In fr, this message translates to:
  /// **'Cochez la case pour continuer.'**
  String get termsTickToContinue;

  /// No description provided for @logoutPending.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{{n} modifications ne sont pas encore envoyées : elles seront perdues si vous vous déconnectez maintenant.} =1{1 modification n’est pas encore envoyée : elle sera perdue si vous vous déconnectez maintenant.} other{{n} modifications ne sont pas encore envoyées : elles seront perdues si vous vous déconnectez maintenant.}}'**
  String logoutPending(int n);

  /// No description provided for @scopeInside.
  ///
  /// In fr, this message translates to:
  /// **'Intérieur'**
  String get scopeInside;

  /// No description provided for @scopeOutside.
  ///
  /// In fr, this message translates to:
  /// **'Extérieur'**
  String get scopeOutside;

  /// No description provided for @eventScope.
  ///
  /// In fr, this message translates to:
  /// **'Service intérieur ou extérieur'**
  String get eventScope;

  /// No description provided for @scopeRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez intérieur ou extérieur.'**
  String get scopeRequired;

  /// No description provided for @eventKindOther.
  ///
  /// In fr, this message translates to:
  /// **'Précisez le type'**
  String get eventKindOther;

  /// No description provided for @eventKindOtherHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. kermesse, retraite, pèlerinage…'**
  String get eventKindOtherHint;

  /// No description provided for @chefDeGroupe.
  ///
  /// In fr, this message translates to:
  /// **'Chef de groupe'**
  String get chefDeGroupe;

  /// No description provided for @chooseChef.
  ///
  /// In fr, this message translates to:
  /// **'Choisir le chef de groupe'**
  String get chooseChef;

  /// No description provided for @chefHelp.
  ///
  /// In fr, this message translates to:
  /// **'Il coordonne l’événement et remet un rapport au formateur dans les 24 h qui suivent la fin.'**
  String get chefHelp;

  /// No description provided for @chefRequired.
  ///
  /// In fr, this message translates to:
  /// **'Désignez le chef de groupe.'**
  String get chefRequired;

  /// No description provided for @chefLine.
  ///
  /// In fr, this message translates to:
  /// **'Chef de groupe : {name}'**
  String chefLine(String name);

  /// No description provided for @reportSection.
  ///
  /// In fr, this message translates to:
  /// **'Rapport du chef de groupe'**
  String get reportSection;

  /// No description provided for @reportDue.
  ///
  /// In fr, this message translates to:
  /// **'À remettre avant le {date}'**
  String reportDue(String date);

  /// No description provided for @reportSubmittedOn.
  ///
  /// In fr, this message translates to:
  /// **'Remis le {date}'**
  String reportSubmittedOn(String date);

  /// No description provided for @reportLateOn.
  ///
  /// In fr, this message translates to:
  /// **'Remis en retard le {date}'**
  String reportLateOn(String date);

  /// No description provided for @reportMissingSince.
  ///
  /// In fr, this message translates to:
  /// **'Non remis : le délai a expiré le {date}'**
  String reportMissingSince(String date);

  /// No description provided for @reportBadgePending.
  ///
  /// In fr, this message translates to:
  /// **'Attendu'**
  String get reportBadgePending;

  /// No description provided for @reportBadgeSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Remis'**
  String get reportBadgeSubmitted;

  /// No description provided for @reportBadgeLate.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get reportBadgeLate;

  /// No description provided for @reportBadgeMissing.
  ///
  /// In fr, this message translates to:
  /// **'Non remis'**
  String get reportBadgeMissing;

  /// No description provided for @reportChefBefore.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes chef de groupe. Le rapport se remet après l’événement, avant le {date}.'**
  String reportChefBefore(String date);

  /// No description provided for @writeReport.
  ///
  /// In fr, this message translates to:
  /// **'Rédiger le rapport'**
  String get writeReport;

  /// No description provided for @editReport.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le rapport'**
  String get editReport;

  /// No description provided for @readReport.
  ///
  /// In fr, this message translates to:
  /// **'Lire le rapport'**
  String get readReport;

  /// No description provided for @reportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rapport'**
  String get reportTitle;

  /// No description provided for @reportBodyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Compte rendu'**
  String get reportBodyLabel;

  /// No description provided for @reportBodyHint.
  ///
  /// In fr, this message translates to:
  /// **'Déroulement, présences, incidents, remarques…'**
  String get reportBodyHint;

  /// No description provided for @reportAttachPdf.
  ///
  /// In fr, this message translates to:
  /// **'Joindre un rapport PDF'**
  String get reportAttachPdf;

  /// No description provided for @reportRecipients.
  ///
  /// In fr, this message translates to:
  /// **'Envoyé au formateur ; en copie : formateur adjoint, secrétaire général, censeur général et vice-censeur.'**
  String get reportRecipients;

  /// No description provided for @sendReport.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le rapport'**
  String get sendReport;

  /// No description provided for @reportSent.
  ///
  /// In fr, this message translates to:
  /// **'Rapport envoyé au formateur.'**
  String get reportSent;

  /// No description provided for @reportEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez le rapport ou joignez un PDF.'**
  String get reportEmpty;

  /// No description provided for @reportLocked.
  ///
  /// In fr, this message translates to:
  /// **'Le délai de 24 h est passé : le rapport remis ne peut plus être modifié.'**
  String get reportLocked;

  /// No description provided for @reportTooEarly.
  ///
  /// In fr, this message translates to:
  /// **'Le rapport se remet une fois l’événement commencé.'**
  String get reportTooEarly;

  /// No description provided for @reportBy.
  ///
  /// In fr, this message translates to:
  /// **'Par {name}, chef de groupe'**
  String reportBy(String name);

  /// No description provided for @reportLateWarning.
  ///
  /// In fr, this message translates to:
  /// **'Le délai de 24 h est passé : le rapport sera marqué « en retard » et ne pourra plus être modifié.'**
  String get reportLateWarning;

  /// No description provided for @pdfOnly.
  ///
  /// In fr, this message translates to:
  /// **'PDF uniquement, 10 Mo maximum'**
  String get pdfOnly;

  /// No description provided for @reportHandedIn.
  ///
  /// In fr, this message translates to:
  /// **'Remis au formateur'**
  String get reportHandedIn;

  /// No description provided for @reportHandedInLate.
  ///
  /// In fr, this message translates to:
  /// **'Remis en retard au formateur'**
  String get reportHandedInLate;

  /// No description provided for @reportReadBy.
  ///
  /// In fr, this message translates to:
  /// **'Ouvert par {name} : ne peut plus être modifié'**
  String reportReadBy(String name);

  /// No description provided for @reportOpenedOn.
  ///
  /// In fr, this message translates to:
  /// **'Ouvert par {name} le {date}'**
  String reportOpenedOn(String name, String date);

  /// No description provided for @reportReadLocked.
  ///
  /// In fr, this message translates to:
  /// **'Un membre du bureau a ouvert le rapport : il ne peut plus être modifié.'**
  String get reportReadLocked;

  /// No description provided for @reportLockNote.
  ///
  /// In fr, this message translates to:
  /// **'Dès qu’un membre du bureau ouvre le rapport, il ne peut plus être modifié.'**
  String get reportLockNote;

  /// No description provided for @lineupOnly.
  ///
  /// In fr, this message translates to:
  /// **'Seuls les gardes alignés pour ce service sont listés, avec leur poste.'**
  String get lineupOnly;

  /// No description provided for @lineupEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Personne n’est encore aligné pour ce service.'**
  String get lineupEmpty;

  /// No description provided for @myPost.
  ///
  /// In fr, this message translates to:
  /// **'Votre poste : {post}'**
  String myPost(String post);

  /// No description provided for @notOnDuty.
  ///
  /// In fr, this message translates to:
  /// **'Vous n’êtes pas de service pour cet événement.'**
  String get notOnDuty;

  /// No description provided for @flagLeaveUntil.
  ///
  /// In fr, this message translates to:
  /// **'En congé jusqu’au {date}'**
  String flagLeaveUntil(String date);

  /// No description provided for @alertOnLeaveUntil.
  ///
  /// In fr, this message translates to:
  /// **'{name} est en congé jusqu’au {date}'**
  String alertOnLeaveUntil(String name, String date);

  /// No description provided for @groupOnLeave.
  ///
  /// In fr, this message translates to:
  /// **'{n} en congé'**
  String groupOnLeave(int n);

  /// No description provided for @groupSheetNotice.
  ///
  /// In fr, this message translates to:
  /// **'{title} · {n} postes. Les postes libres sont pris par les membres disponibles du groupe ; les autres sont exclus et les cases restantes signalées.'**
  String groupSheetNotice(String title, int n);

  /// No description provided for @keepDraft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get keepDraft;

  /// No description provided for @draftKept.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon : personne n’est notifié tant que vous ne publiez pas.'**
  String get draftKept;

  /// No description provided for @dragHint.
  ///
  /// In fr, this message translates to:
  /// **'Maintenez un nom pour le glisser vers une autre case.'**
  String get dragHint;

  /// No description provided for @dropHere.
  ///
  /// In fr, this message translates to:
  /// **'Déposer ici'**
  String get dropHere;

  /// No description provided for @swapValidation.
  ///
  /// In fr, this message translates to:
  /// **'Validation : {name}, chef de groupe'**
  String swapValidation(String name);

  /// No description provided for @swapValidationPlanners.
  ///
  /// In fr, this message translates to:
  /// **'Validation : les responsables du planning'**
  String get swapValidationPlanners;

  /// No description provided for @draftSaved.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon enregistré sur ce téléphone.'**
  String get draftSaved;

  /// No description provided for @draftRestored.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon repris.'**
  String get draftRestored;

  /// No description provided for @placeDetail.
  ///
  /// In fr, this message translates to:
  /// **'Précision du lieu (facultatif)'**
  String get placeDetail;

  /// No description provided for @placeDetailHint.
  ///
  /// In fr, this message translates to:
  /// **'Quartier, ville'**
  String get placeDetailHint;

  /// No description provided for @memberLeaveUntil.
  ///
  /// In fr, this message translates to:
  /// **'En congé jusqu’au {date}'**
  String memberLeaveUntil(String date);

  /// No description provided for @poweredBy.
  ///
  /// In fr, this message translates to:
  /// **'Propulsé par'**
  String get poweredBy;

  /// No description provided for @storageAndData.
  ///
  /// In fr, this message translates to:
  /// **'Stockage et données'**
  String get storageAndData;

  /// No description provided for @manageStorage.
  ///
  /// In fr, this message translates to:
  /// **'Gérer le stockage'**
  String get manageStorage;

  /// No description provided for @storageUsed.
  ///
  /// In fr, this message translates to:
  /// **'{size} utilisés sur ce téléphone'**
  String storageUsed(String size);

  /// No description provided for @networkUsage.
  ///
  /// In fr, this message translates to:
  /// **'Utilisation du réseau'**
  String get networkUsage;

  /// No description provided for @trafficSentReceived.
  ///
  /// In fr, this message translates to:
  /// **'{sent} envoyés • {received} reçus'**
  String trafficSentReceived(String sent, String received);

  /// No description provided for @trafficSince.
  ///
  /// In fr, this message translates to:
  /// **'Depuis le {date}'**
  String trafficSince(String date);

  /// No description provided for @resetTrafficConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Remettre à zéro les compteurs de données ?'**
  String get resetTrafficConfirm;

  /// No description provided for @reset.
  ///
  /// In fr, this message translates to:
  /// **'Remettre à zéro'**
  String get reset;

  /// No description provided for @dataSaver.
  ///
  /// In fr, this message translates to:
  /// **'Économiser les données mobiles'**
  String get dataSaver;

  /// No description provided for @dataSaverHint.
  ///
  /// In fr, this message translates to:
  /// **'Sur données mobiles : pas de photos automatiques, photos envoyées en qualité standard'**
  String get dataSaverHint;

  /// No description provided for @uploadQuality.
  ///
  /// In fr, this message translates to:
  /// **'Qualité d’envoi des photos'**
  String get uploadQuality;

  /// No description provided for @qualityStandard.
  ///
  /// In fr, this message translates to:
  /// **'Qualité standard'**
  String get qualityStandard;

  /// No description provided for @qualityStandardHint.
  ///
  /// In fr, this message translates to:
  /// **'Plus rapide, moins de données (jusqu’à 1024 px)'**
  String get qualityStandardHint;

  /// No description provided for @qualityHigh.
  ///
  /// In fr, this message translates to:
  /// **'Haute qualité'**
  String get qualityHigh;

  /// No description provided for @qualityHighHint.
  ///
  /// In fr, this message translates to:
  /// **'Plus nette, plus de données (jusqu’à 2048 px)'**
  String get qualityHighHint;

  /// No description provided for @autoDownload.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement automatique des médias'**
  String get autoDownload;

  /// No description provided for @autoDownloadHint.
  ///
  /// In fr, this message translates to:
  /// **'Les pièces jointes ne se téléchargent que lorsque vous les ouvrez.'**
  String get autoDownloadHint;

  /// No description provided for @onMobileData.
  ///
  /// In fr, this message translates to:
  /// **'Sur données mobiles'**
  String get onMobileData;

  /// No description provided for @onWifi.
  ///
  /// In fr, this message translates to:
  /// **'En Wi-Fi'**
  String get onWifi;

  /// No description provided for @memberPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Photos (membres et annonces)'**
  String get memberPhotos;

  /// No description provided for @noMedia.
  ///
  /// In fr, this message translates to:
  /// **'Aucun média'**
  String get noMedia;

  /// No description provided for @autoOffBySaver.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé : économie de données'**
  String get autoOffBySaver;

  /// No description provided for @currentNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Connexion actuelle : {network}'**
  String currentNetwork(String network);

  /// No description provided for @networkWifi.
  ///
  /// In fr, this message translates to:
  /// **'Wi-Fi'**
  String get networkWifi;

  /// No description provided for @networkMobile.
  ///
  /// In fr, this message translates to:
  /// **'données mobiles'**
  String get networkMobile;

  /// No description provided for @networkNone.
  ///
  /// In fr, this message translates to:
  /// **'hors ligne'**
  String get networkNone;

  /// No description provided for @networkUnknown.
  ///
  /// In fr, this message translates to:
  /// **'inconnue'**
  String get networkUnknown;

  /// No description provided for @offlineData.
  ///
  /// In fr, this message translates to:
  /// **'Données hors ligne'**
  String get offlineData;

  /// No description provided for @offlineDataHint.
  ///
  /// In fr, this message translates to:
  /// **'rechargées depuis le serveur'**
  String get offlineDataHint;

  /// No description provided for @unsentChanges.
  ///
  /// In fr, this message translates to:
  /// **'Modifications non envoyées'**
  String get unsentChanges;

  /// No description provided for @unsentKept.
  ///
  /// In fr, this message translates to:
  /// **'conservées jusqu’à l’envoi'**
  String get unsentKept;

  /// No description provided for @imagesInMemory.
  ///
  /// In fr, this message translates to:
  /// **'Images en mémoire'**
  String get imagesInMemory;

  /// No description provided for @clear.
  ///
  /// In fr, this message translates to:
  /// **'Vider'**
  String get clear;

  /// No description provided for @sizeGb.
  ///
  /// In fr, this message translates to:
  /// **'{n} Go'**
  String sizeGb(String n);

  /// No description provided for @framePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Cadrer la photo'**
  String get framePhoto;

  /// No description provided for @framePhotoHint.
  ///
  /// In fr, this message translates to:
  /// **'Déplacez et zoomez la photo : seul ce qui est dans le cadre est envoyé.'**
  String get framePhotoHint;

  /// No description provided for @photoRules.
  ///
  /// In fr, this message translates to:
  /// **'Format paysage 4:3 · 2 Mo maximum · 4 photos par annonce'**
  String get photoRules;

  /// No description provided for @usePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser cette photo'**
  String get usePhoto;

  /// No description provided for @photoUnreadable.
  ///
  /// In fr, this message translates to:
  /// **'Cette image ne peut pas être lue.'**
  String get photoUnreadable;

  /// No description provided for @showPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Afficher la photo'**
  String get showPhoto;

  /// No description provided for @addPhotoHint.
  ///
  /// In fr, this message translates to:
  /// **'Galerie ou appareil photo · cadrée en 4:3, 2 Mo max'**
  String get addPhotoHint;

  /// No description provided for @photosLimit.
  ///
  /// In fr, this message translates to:
  /// **'4 photos maximum par annonce.'**
  String get photosLimit;

  /// No description provided for @attachPdfHint.
  ///
  /// In fr, this message translates to:
  /// **'Document PDF, 10 Mo max'**
  String get attachPdfHint;

  /// No description provided for @eventExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expiré'**
  String get eventExpired;

  /// No description provided for @notifyAll.
  ///
  /// In fr, this message translates to:
  /// **'Notifier : tous les membres'**
  String get notifyAll;

  /// No description provided for @notifyCount.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Notifier : {n} membres} =1{Notifier : 1 membre} other{Notifier : {n} membres}}'**
  String notifyCount(int n);

  /// No description provided for @notifyHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez qui reçoit la notification. L’annonce reste visible par tous.'**
  String get notifyHint;

  /// No description provided for @chooseRecipients.
  ///
  /// In fr, this message translates to:
  /// **'Qui notifier ?'**
  String get chooseRecipients;

  /// No description provided for @chooseRecipientsHint.
  ///
  /// In fr, this message translates to:
  /// **'Seuls les membres cochés sont notifiés. Sans choix, tout le monde l’est.'**
  String get chooseRecipientsHint;

  /// No description provided for @notifyEveryone.
  ///
  /// In fr, this message translates to:
  /// **'Tout le monde'**
  String get notifyEveryone;

  /// No description provided for @doneCount.
  ///
  /// In fr, this message translates to:
  /// **'Valider ({n})'**
  String doneCount(int n);

  /// No description provided for @forYou.
  ///
  /// In fr, this message translates to:
  /// **'Pour vous'**
  String get forYou;

  /// No description provided for @taggedLine.
  ///
  /// In fr, this message translates to:
  /// **'Pour : {names}'**
  String taggedLine(String names);

  /// No description provided for @filterForMe.
  ///
  /// In fr, this message translates to:
  /// **'Pour moi'**
  String get filterForMe;

  /// No description provided for @taggedStatus.
  ///
  /// In fr, this message translates to:
  /// **'Mentionné'**
  String get taggedStatus;

  /// No description provided for @removeRecipient.
  ///
  /// In fr, this message translates to:
  /// **'Retirer {name}'**
  String removeRecipient(String name);

  /// No description provided for @searchName.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un nom'**
  String get searchName;

  /// No description provided for @downloads.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargements'**
  String get downloads;

  /// No description provided for @downloadsHint.
  ///
  /// In fr, this message translates to:
  /// **'Les photos et PDF téléchargés ou ouverts restent ici, lisibles sans réseau. Les photos déjà vues dans l’app aussi.'**
  String get downloadsHint;

  /// No description provided for @downloadsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun téléchargement'**
  String get downloadsEmpty;

  /// No description provided for @downloadsEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargez une photo d’une annonce ou ouvrez un rapport PDF : il restera ici.'**
  String get downloadsEmptyHint;

  /// No description provided for @onThePhone.
  ///
  /// In fr, this message translates to:
  /// **'sur le téléphone'**
  String get onThePhone;

  /// No description provided for @saveToPhone.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer sur le téléphone'**
  String get saveToPhone;

  /// No description provided for @saveToPhoneFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le téléphone n’a pas permis l’enregistrement. Le fichier reste dans Téléchargements.'**
  String get saveToPhoneFailed;

  /// No description provided for @deleteFile.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get deleteFile;

  /// No description provided for @savedToDownloads.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré dans Téléchargements › Huddle'**
  String get savedToDownloads;

  /// No description provided for @photoSavedToGallery.
  ///
  /// In fr, this message translates to:
  /// **'Photo enregistrée dans la galerie (Images › Huddle)'**
  String get photoSavedToGallery;

  /// No description provided for @keptInDownloads.
  ///
  /// In fr, this message translates to:
  /// **'Gardé dans Mon compte › Téléchargements'**
  String get keptInDownloads;

  /// No description provided for @noPdfViewer.
  ///
  /// In fr, this message translates to:
  /// **'Aucune application ne peut ouvrir ce PDF. Il est gardé dans Mon compte › Téléchargements.'**
  String get noPdfViewer;

  /// No description provided for @offlineCopyOf.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne : copie du {date}'**
  String offlineCopyOf(String date);

  /// No description provided for @downloadPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger la photo'**
  String get downloadPhoto;

  /// No description provided for @downloadFile.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger'**
  String get downloadFile;

  /// No description provided for @photosAndFiles.
  ///
  /// In fr, this message translates to:
  /// **'Photos vues'**
  String get photosAndFiles;

  /// No description provided for @photosAndFilesHint.
  ///
  /// In fr, this message translates to:
  /// **'gardées pour les voir sans réseau'**
  String get photosAndFilesHint;

  /// No description provided for @pdfStatementName.
  ///
  /// In fr, this message translates to:
  /// **'Relevé des soldes {date}.pdf'**
  String pdfStatementName(String date);

  /// No description provided for @pdfCashbookName.
  ///
  /// In fr, this message translates to:
  /// **'Livre de caisse {date}.pdf'**
  String pdfCashbookName(String date);

  /// No description provided for @pdfReportName.
  ///
  /// In fr, this message translates to:
  /// **'Rapport T{quarter} {year}.pdf'**
  String pdfReportName(int quarter, int year);

  /// No description provided for @pdfMemberStatementName.
  ///
  /// In fr, this message translates to:
  /// **'Relevé {name} {date}.pdf'**
  String pdfMemberStatementName(String name, String date);

  /// No description provided for @preview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get preview;

  /// No description provided for @gradient.
  ///
  /// In fr, this message translates to:
  /// **'Dégradé'**
  String get gradient;

  /// No description provided for @gradientHint.
  ///
  /// In fr, this message translates to:
  /// **'L’en-tête d’Accueil passe de la couleur principale à une deuxième.'**
  String get gradientHint;

  /// No description provided for @secondColorN.
  ///
  /// In fr, this message translates to:
  /// **'Deuxième couleur {n}'**
  String secondColorN(int n);

  /// No description provided for @otherColor.
  ///
  /// In fr, this message translates to:
  /// **'Autre couleur…'**
  String get otherColor;

  /// No description provided for @hue.
  ///
  /// In fr, this message translates to:
  /// **'Teinte'**
  String get hue;

  /// No description provided for @shade.
  ///
  /// In fr, this message translates to:
  /// **'Nuance'**
  String get shade;

  /// No description provided for @choose.
  ///
  /// In fr, this message translates to:
  /// **'Choisir'**
  String get choose;

  /// No description provided for @draftsSection.
  ///
  /// In fr, this message translates to:
  /// **'Brouillons à publier'**
  String get draftsSection;

  /// No description provided for @publishedSection.
  ///
  /// In fr, this message translates to:
  /// **'Publiés'**
  String get publishedSection;

  /// No description provided for @reuse.
  ///
  /// In fr, this message translates to:
  /// **'Réutiliser'**
  String get reuse;

  /// No description provided for @reuseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réutiliser ce planning pour…'**
  String get reuseTitle;

  /// No description provided for @reuseHint.
  ///
  /// In fr, this message translates to:
  /// **'Mêmes postes et mêmes gardes, en brouillon : vérifiez puis publiez.'**
  String get reuseHint;

  /// No description provided for @reuseNoTarget.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement à venir sans planning. Créez d’abord l’événement dans le Calendrier.'**
  String get reuseNoTarget;

  /// No description provided for @reuseDone.
  ///
  /// In fr, this message translates to:
  /// **'Planning repris pour {title}, en brouillon.'**
  String reuseDone(String title);

  /// No description provided for @reuseSkipped.
  ///
  /// In fr, this message translates to:
  /// **'Non repris (congé, inactif ou déjà de service ce jour-là) : {names}.'**
  String reuseSkipped(String names);

  /// No description provided for @datePassed.
  ///
  /// In fr, this message translates to:
  /// **'Date passée'**
  String get datePassed;

  /// No description provided for @pastDraftsNotice.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{{n} plannings dont la date est passée ne peuvent plus être publiés : réutilisez-les pour un événement à venir.} =1{Un planning dont la date est passée ne peut plus être publié : réutilisez-le pour un événement à venir.} other{{n} plannings dont la date est passée ne peuvent plus être publiés : réutilisez-les pour un événement à venir.}}'**
  String pastDraftsNotice(int n);

  /// No description provided for @errorDatePassed.
  ///
  /// In fr, this message translates to:
  /// **'La date est passée : ce planning ne peut plus être publié. Réutilisez-le pour un événement à venir.'**
  String get errorDatePassed;

  /// No description provided for @signedOutOtherDevice.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte a été ouvert sur un autre téléphone, celui-ci a donc été déconnecté. Si ce n’est pas vous, reconnectez-vous et changez votre code PIN.'**
  String get signedOutOtherDevice;

  /// No description provided for @checkAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout cocher'**
  String get checkAll;

  /// No description provided for @chooseMembers.
  ///
  /// In fr, this message translates to:
  /// **'Choisir les membres'**
  String get chooseMembers;

  /// No description provided for @membersLabel.
  ///
  /// In fr, this message translates to:
  /// **'Membres'**
  String get membersLabel;

  /// No description provided for @memberRequiredError.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez au moins un membre.'**
  String get memberRequiredError;

  /// No description provided for @membersChosen.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{{n} membres choisis} =1{1 membre choisi} other{{n} membres choisis}}'**
  String membersChosen(int n);

  /// No description provided for @perMemberTotal.
  ///
  /// In fr, this message translates to:
  /// **'{n} membres × {amount} = {total}'**
  String perMemberTotal(int n, String amount, String total);

  /// No description provided for @perMemberHint.
  ///
  /// In fr, this message translates to:
  /// **'Une opération par membre, du même montant.'**
  String get perMemberHint;

  /// No description provided for @catOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get catOther;

  /// No description provided for @otherDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description (obligatoire)'**
  String get otherDescription;

  /// No description provided for @descriptionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez l’opération.'**
  String get descriptionRequired;

  /// No description provided for @editEntryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l’opération'**
  String get editEntryTitle;

  /// No description provided for @entryEdited.
  ///
  /// In fr, this message translates to:
  /// **'Opération modifiée. L’autre responsable l’approuvera.'**
  String get entryEdited;

  /// No description provided for @editedBadge.
  ///
  /// In fr, this message translates to:
  /// **'Modifié'**
  String get editedBadge;

  /// No description provided for @editedBy.
  ///
  /// In fr, this message translates to:
  /// **'modifié par {name}'**
  String editedBy(String name);

  /// No description provided for @toConfirmBadge.
  ///
  /// In fr, this message translates to:
  /// **'À finaliser'**
  String get toConfirmBadge;

  /// No description provided for @confirmEntryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Finaliser l’opération ?'**
  String get confirmEntryTitle;

  /// No description provided for @confirmEntryBody.
  ///
  /// In fr, this message translates to:
  /// **'{name} l’a modifiée puis validée. Finalisez-la si la correction est juste, sinon renvoyez-la avec la raison.'**
  String confirmEntryBody(String name);

  /// No description provided for @finalise.
  ///
  /// In fr, this message translates to:
  /// **'Finaliser'**
  String get finalise;

  /// No description provided for @sendBack.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer'**
  String get sendBack;

  /// No description provided for @sendBackReason.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi la renvoyer au trésorier ?'**
  String get sendBackReason;

  /// No description provided for @entryFinalised.
  ///
  /// In fr, this message translates to:
  /// **'Opération finalisée.'**
  String get entryFinalised;

  /// No description provided for @entrySentBack.
  ///
  /// In fr, this message translates to:
  /// **'Opération renvoyée au trésorier.'**
  String get entrySentBack;

  /// No description provided for @validateEditedNote.
  ///
  /// In fr, this message translates to:
  /// **'Elle a été modifiée : en la validant, vous approuvez la version corrigée.'**
  String get validateEditedNote;

  /// No description provided for @linkedEntryNote.
  ///
  /// In fr, this message translates to:
  /// **'Paiement d’une cotisation ou d’une amende : le membre et la catégorie ne changent pas.'**
  String get linkedEntryNote;

  /// No description provided for @entriesToConfirm.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{{n} opérations à finaliser} =1{1 opération à finaliser} other{{n} opérations à finaliser}}'**
  String entriesToConfirm(int n);

  /// No description provided for @groupBy.
  ///
  /// In fr, this message translates to:
  /// **'Grouper par'**
  String get groupBy;

  /// No description provided for @groupByDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour'**
  String get groupByDay;

  /// No description provided for @groupByType.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get groupByType;

  /// No description provided for @groupByStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get groupByStatus;

  /// No description provided for @groupByMember.
  ///
  /// In fr, this message translates to:
  /// **'Membre'**
  String get groupByMember;

  /// No description provided for @noMemberGroup.
  ///
  /// In fr, this message translates to:
  /// **'Sans membre'**
  String get noMemberGroup;

  /// No description provided for @entriesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{{count} opérations} =1{1 opération} other{{count} opérations}}'**
  String entriesCount(int count);

  /// No description provided for @awaitingOtherBadge.
  ///
  /// In fr, this message translates to:
  /// **'En attente de l’autre'**
  String get awaitingOtherBadge;

  /// No description provided for @longPressHint.
  ///
  /// In fr, this message translates to:
  /// **'Appui long sur une opération pour en valider plusieurs.'**
  String get longPressHint;

  /// No description provided for @selectedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{{count} sélectionnées} =1{1 sélectionnée} other{{count} sélectionnées}}'**
  String selectedCount(int count);

  /// No description provided for @selectAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout sélectionner'**
  String get selectAll;

  /// No description provided for @validateSelected.
  ///
  /// In fr, this message translates to:
  /// **'Valider ({count})'**
  String validateSelected(int count);

  /// No description provided for @validateManyTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Valider {count} opérations ?} =1{Valider 1 opération ?} other{Valider {count} opérations ?}}'**
  String validateManyTitle(int count);

  /// No description provided for @validateManyBody.
  ///
  /// In fr, this message translates to:
  /// **'Total : {total}. Votre nom et l’heure seront enregistrés sur chacune ; elles ne pourront plus être modifiées.'**
  String validateManyBody(String total);

  /// No description provided for @validatedMany.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{{count} opérations validées.} =1{1 opération validée.} other{{count} opérations validées.}}'**
  String validatedMany(int count);

  /// No description provided for @skippedMany.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{{count} n’ont pas été validées (elles attendent l’accord de l’autre).} =1{1 n’a pas été validée (elle attend l’accord de l’autre).} other{{count} n’ont pas été validées (elles attendent l’accord de l’autre).}}'**
  String skippedMany(int count);

  /// No description provided for @financeCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code finances'**
  String get financeCodeTitle;

  /// No description provided for @financeCodeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre code finances pour ouvrir les finances.'**
  String get financeCodeSubtitle;

  /// No description provided for @financeCodeWrong.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Code finances incorrect.} =1{Code finances incorrect. Encore 1 essai.} other{Code finances incorrect. Encore {count} essais.}}'**
  String financeCodeWrong(int count);

  /// No description provided for @financeCodeForgot.
  ///
  /// In fr, this message translates to:
  /// **'Code finances oublié ?'**
  String get financeCodeForgot;

  /// No description provided for @financeCodeChooseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre code finances'**
  String get financeCodeChooseTitle;

  /// No description provided for @financeCodeChooseBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre groupe protège les finances par un second code à 4 chiffres, différent de votre PIN. Choisissez-le et confirmez avec votre PIN.'**
  String get financeCodeChooseBody;

  /// No description provided for @financeCodeYourPin.
  ///
  /// In fr, this message translates to:
  /// **'Votre PIN'**
  String get financeCodeYourPin;

  /// No description provided for @financeCodeNew.
  ///
  /// In fr, this message translates to:
  /// **'Code finances (4 chiffres)'**
  String get financeCodeNew;

  /// No description provided for @financeCodeConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez le code finances'**
  String get financeCodeConfirm;

  /// No description provided for @financeCodeMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les deux codes ne correspondent pas.'**
  String get financeCodeMismatch;

  /// No description provided for @financeCodeFourDigits.
  ///
  /// In fr, this message translates to:
  /// **'Le PIN et le code ont 4 chiffres.'**
  String get financeCodeFourDigits;

  /// No description provided for @financeCodeSameAsPin.
  ///
  /// In fr, this message translates to:
  /// **'Le code finances doit être différent du PIN.'**
  String get financeCodeSameAsPin;

  /// No description provided for @financeCodeSaved.
  ///
  /// In fr, this message translates to:
  /// **'Code finances enregistré.'**
  String get financeCodeSaved;

  /// No description provided for @financeCodeSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le code'**
  String get financeCodeSave;

  /// No description provided for @financeCodeOffline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne : ce code n’a encore jamais été vérifié sur ce téléphone.'**
  String get financeCodeOffline;

  /// No description provided for @expensesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demandes de dépense'**
  String get expensesTitle;

  /// No description provided for @expTodo.
  ///
  /// In fr, this message translates to:
  /// **'À traiter'**
  String get expTodo;

  /// No description provided for @expMine.
  ///
  /// In fr, this message translates to:
  /// **'Mes demandes'**
  String get expMine;

  /// No description provided for @expAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get expAll;

  /// No description provided for @expNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle demande'**
  String get expNew;

  /// No description provided for @expNothingTodo.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande ne vous attend.'**
  String get expNothingTodo;

  /// No description provided for @expNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande.'**
  String get expNone;

  /// No description provided for @expStatusSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Chez le responsable'**
  String get expStatusSubmitted;

  /// No description provided for @expStatusApproved.
  ///
  /// In fr, this message translates to:
  /// **'Chez le commissaire'**
  String get expStatusApproved;

  /// No description provided for @expStatusToPay.
  ///
  /// In fr, this message translates to:
  /// **'À payer'**
  String get expStatusToPay;

  /// No description provided for @expStatusPaid.
  ///
  /// In fr, this message translates to:
  /// **'Payée'**
  String get expStatusPaid;

  /// No description provided for @expStatusRefused.
  ///
  /// In fr, this message translates to:
  /// **'Refusée'**
  String get expStatusRefused;

  /// No description provided for @expStatusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get expStatusCancelled;

  /// No description provided for @expReplaces.
  ///
  /// In fr, this message translates to:
  /// **'Remplace la demande n° {id}.'**
  String expReplaces(int id);

  /// No description provided for @expReplacedBy.
  ///
  /// In fr, this message translates to:
  /// **'Refaite : demande n° {id}.'**
  String expReplacedBy(int id);

  /// No description provided for @expDomain.
  ///
  /// In fr, this message translates to:
  /// **'Type de dépense'**
  String get expDomain;

  /// No description provided for @expDomainRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le type de dépense.'**
  String get expDomainRequired;

  /// No description provided for @expTitleRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez l’objet de la dépense.'**
  String get expTitleRequired;

  /// No description provided for @expLeadHint.
  ///
  /// In fr, this message translates to:
  /// **'Approuvée d’abord par : {role} (ou un coordinateur que vous identifiez).'**
  String expLeadHint(String role);

  /// No description provided for @expNoLeadHint.
  ///
  /// In fr, this message translates to:
  /// **'Identifiez le coordinateur qui l’approuvera.'**
  String get expNoLeadHint;

  /// No description provided for @expTitle.
  ///
  /// In fr, this message translates to:
  /// **'Objet (ex. Papier pour l’examen)'**
  String get expTitle;

  /// No description provided for @expAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant demandé'**
  String get expAmount;

  /// No description provided for @expDescription.
  ///
  /// In fr, this message translates to:
  /// **'Détails (facultatif)'**
  String get expDescription;

  /// No description provided for @expTagCoordinators.
  ///
  /// In fr, this message translates to:
  /// **'Identifier un coordinateur'**
  String get expTagCoordinators;

  /// No description provided for @expTagHint.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif : un responsable plus haut peut aussi l’approuver.'**
  String get expTagHint;

  /// No description provided for @expSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la demande'**
  String get expSend;

  /// No description provided for @expSent.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée.'**
  String get expSent;

  /// No description provided for @expDetailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demande de dépense'**
  String get expDetailTitle;

  /// No description provided for @expThread.
  ///
  /// In fr, this message translates to:
  /// **'Échanges'**
  String get expThread;

  /// No description provided for @expCancelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la demande ?'**
  String get expCancelTitle;

  /// No description provided for @expRefuseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Refuser la demande ?'**
  String get expRefuseTitle;

  /// No description provided for @expReasonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Motif (obligatoire)'**
  String get expReasonLabel;

  /// No description provided for @expCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Demande annulée. Elle reste dans l’historique.'**
  String get expCancelled;

  /// No description provided for @expApproved.
  ///
  /// In fr, this message translates to:
  /// **'Demande approuvée et transmise.'**
  String get expApproved;

  /// No description provided for @expRefused.
  ///
  /// In fr, this message translates to:
  /// **'Demande refusée.'**
  String get expRefused;

  /// No description provided for @expPaid.
  ///
  /// In fr, this message translates to:
  /// **'Paiement enregistré, preuve jointe.'**
  String get expPaid;

  /// No description provided for @expMessageSent.
  ///
  /// In fr, this message translates to:
  /// **'Message envoyé.'**
  String get expMessageSent;

  /// No description provided for @expApprove.
  ///
  /// In fr, this message translates to:
  /// **'Approuver'**
  String get expApprove;

  /// No description provided for @expRefuse.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get expRefuse;

  /// No description provided for @expPayAction.
  ///
  /// In fr, this message translates to:
  /// **'Payer et joindre la preuve'**
  String get expPayAction;

  /// No description provided for @expCancelAction.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la demande'**
  String get expCancelAction;

  /// No description provided for @expResubmit.
  ///
  /// In fr, this message translates to:
  /// **'Refaire une demande'**
  String get expResubmit;

  /// No description provided for @expAttach.
  ///
  /// In fr, this message translates to:
  /// **'Joindre un fichier'**
  String get expAttach;

  /// No description provided for @expMessageHint.
  ///
  /// In fr, this message translates to:
  /// **'Écrire un message…'**
  String get expMessageHint;

  /// No description provided for @expSendMessage.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get expSendMessage;

  /// No description provided for @expPaidAmount.
  ///
  /// In fr, this message translates to:
  /// **'Payé : {amount}'**
  String expPaidAmount(String amount);

  /// No description provided for @expAskedBy.
  ///
  /// In fr, this message translates to:
  /// **'demandée par {name}'**
  String expAskedBy(String name);

  /// No description provided for @expTagged.
  ///
  /// In fr, this message translates to:
  /// **'Coordinateurs identifiés : {names}'**
  String expTagged(String names);

  /// No description provided for @expReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif : {reason}'**
  String expReason(String reason);

  /// No description provided for @expStepAsked.
  ///
  /// In fr, this message translates to:
  /// **'Demande'**
  String get expStepAsked;

  /// No description provided for @expStepLead.
  ///
  /// In fr, this message translates to:
  /// **'Responsable du domaine'**
  String get expStepLead;

  /// No description provided for @expStepAuditor.
  ///
  /// In fr, this message translates to:
  /// **'Commissaire aux comptes'**
  String get expStepAuditor;

  /// No description provided for @expStepPaid.
  ///
  /// In fr, this message translates to:
  /// **'Paiement par le trésorier'**
  String get expStepPaid;

  /// No description provided for @expProof.
  ///
  /// In fr, this message translates to:
  /// **'Preuve de paiement'**
  String get expProof;

  /// No description provided for @expPayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Payer la dépense'**
  String get expPayTitle;

  /// No description provided for @expApprovedAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant approuvé : {amount}'**
  String expApprovedAmount(String amount);

  /// No description provided for @expAmountPaid.
  ///
  /// In fr, this message translates to:
  /// **'Montant payé'**
  String get expAmountPaid;

  /// No description provided for @expAmountMaxHint.
  ///
  /// In fr, this message translates to:
  /// **'Au plus le montant approuvé. Pour plus, le demandeur annule et refait sa demande.'**
  String get expAmountMaxHint;

  /// No description provided for @expAmountMax.
  ///
  /// In fr, this message translates to:
  /// **'Le montant payé va de 1 à {amount}.'**
  String expAmountMax(String amount);

  /// No description provided for @expProofRequired.
  ///
  /// In fr, this message translates to:
  /// **'Joignez la capture de la transaction.'**
  String get expProofRequired;

  /// No description provided for @expAddProof.
  ///
  /// In fr, this message translates to:
  /// **'Joindre la capture de la transaction'**
  String get expAddProof;

  /// No description provided for @expPayNote.
  ///
  /// In fr, this message translates to:
  /// **'Note (ex. Orange Money, réf. …)'**
  String get expPayNote;

  /// No description provided for @expPayCashbook.
  ///
  /// In fr, this message translates to:
  /// **'La sortie est inscrite au livre de caisse et compte aussitôt : la demande a été approuvée par le commissaire.'**
  String get expPayCashbook;

  /// No description provided for @expPayConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le paiement'**
  String get expPayConfirm;

  /// No description provided for @homeExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Demandes de dépense'**
  String get homeExpenses;

  /// No description provided for @homeExpensesHint.
  ///
  /// In fr, this message translates to:
  /// **'Demander un achat, suivre vos demandes'**
  String get homeExpensesHint;

  /// No description provided for @fromExpense.
  ///
  /// In fr, this message translates to:
  /// **'Payée sur la demande de dépense n° {id} · voir la preuve'**
  String fromExpense(int id);

  /// No description provided for @selectLines.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner'**
  String get selectLines;

  /// No description provided for @expTodoCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} à traiter'**
  String expTodoCount(int count);

  /// No description provided for @expAttachments.
  ///
  /// In fr, this message translates to:
  /// **'Pièces jointes'**
  String get expAttachments;

  /// No description provided for @expAddFile.
  ///
  /// In fr, this message translates to:
  /// **'Joindre une photo ou un PDF'**
  String get expAddFile;

  /// No description provided for @expRemoveFile.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get expRemoveFile;

  /// No description provided for @expAttachmentsHint.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif : devis, facture, photo de l’article (JPEG, PNG ou PDF, 10 Mo, 3 au plus).'**
  String get expAttachmentsHint;

  /// No description provided for @expAttachmentBody.
  ///
  /// In fr, this message translates to:
  /// **'Pièce jointe à la demande'**
  String get expAttachmentBody;

  /// No description provided for @expSentFilesMissed.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Demande envoyée.} =1{Demande envoyée, mais 1 pièce jointe n’est pas partie : ajoutez-la dans les échanges.} other{Demande envoyée, mais {count} pièces jointes ne sont pas parties : ajoutez-les dans les échanges.}}'**
  String expSentFilesMissed(int count);

  /// No description provided for @financeSettingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages des finances'**
  String get financeSettingsTitle;

  /// No description provided for @financeCodeAskTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demander mon code finances'**
  String get financeCodeAskTitle;

  /// No description provided for @financeCodeAskHint.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir Finances sur ce compte demandera votre code à 4 chiffres.'**
  String get financeCodeAskHint;

  /// No description provided for @financeCodeForced.
  ///
  /// In fr, this message translates to:
  /// **'Exigé par votre groupe pour tous : il ne peut pas être désactivé.'**
  String get financeCodeForced;

  /// No description provided for @financeCodeChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer mon code finances'**
  String get financeCodeChange;

  /// No description provided for @financeCodeChangeHint.
  ///
  /// In fr, this message translates to:
  /// **'Avec votre PIN, aussi si vous l’avez oublié.'**
  String get financeCodeChangeHint;

  /// No description provided for @financeCodeAbout.
  ///
  /// In fr, this message translates to:
  /// **'Le code finances est un second code, différent du PIN. Une fois saisi, Finances reste ouvert 5 minutes ; il se referme quand l’application se verrouille.'**
  String get financeCodeAbout;

  /// No description provided for @financeCodeTurnOffTitle.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver le code finances ?'**
  String get financeCodeTurnOffTitle;

  /// No description provided for @financeCodeTurnedOn.
  ///
  /// In fr, this message translates to:
  /// **'Code finances activé.'**
  String get financeCodeTurnedOn;

  /// No description provided for @financeCodeTurnedOff.
  ///
  /// In fr, this message translates to:
  /// **'Code finances désactivé.'**
  String get financeCodeTurnedOff;

  /// No description provided for @chooseGroupHint.
  ///
  /// In fr, this message translates to:
  /// **'Vous faites partie de plusieurs groupes. Vous pourrez changer à tout moment depuis l’Accueil.'**
  String get chooseGroupHint;

  /// No description provided for @groupLabel.
  ///
  /// In fr, this message translates to:
  /// **'Groupe'**
  String get groupLabel;

  /// No description provided for @groupProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nom et logo du groupe'**
  String get groupProfileTitle;

  /// No description provided for @groupProfileHint.
  ///
  /// In fr, this message translates to:
  /// **'Ce que les membres voient dans Huddle'**
  String get groupProfileHint;

  /// No description provided for @groupLogoChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer le logo'**
  String get groupLogoChange;

  /// No description provided for @groupLogoRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le logo'**
  String get groupLogoRemove;

  /// No description provided for @groupLogoSaved.
  ///
  /// In fr, this message translates to:
  /// **'Logo du groupe enregistré.'**
  String get groupLogoSaved;

  /// No description provided for @groupLogoHint.
  ///
  /// In fr, this message translates to:
  /// **'Image carrée de préférence (JPEG ou PNG, 5 Mo). Sans logo, le sigle s’affiche sur la couleur du groupe.'**
  String get groupLogoHint;

  /// No description provided for @groupName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du groupe'**
  String get groupName;

  /// No description provided for @groupShortName.
  ///
  /// In fr, this message translates to:
  /// **'Sigle'**
  String get groupShortName;

  /// No description provided for @groupShortNameHint.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères au plus, ex. MSG'**
  String get groupShortNameHint;

  /// No description provided for @groupNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom du groupe est obligatoire.'**
  String get groupNameRequired;

  /// No description provided for @groupProfileSaved.
  ///
  /// In fr, this message translates to:
  /// **'Groupe enregistré.'**
  String get groupProfileSaved;

  /// No description provided for @huddleBy.
  ///
  /// In fr, this message translates to:
  /// **'Huddle ·'**
  String get huddleBy;

  /// No description provided for @eventEnded.
  ///
  /// In fr, this message translates to:
  /// **'Cet événement est passé : il ne peut plus être modifié. Seul l’appel reste possible.'**
  String get eventEnded;

  /// No description provided for @showBalance.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le solde'**
  String get showBalance;

  /// No description provided for @hideBalance.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le solde'**
  String get hideBalance;

  /// No description provided for @downloadAskTitle.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger ce document ?'**
  String get downloadAskTitle;

  /// No description provided for @downloadAskWhere.
  ///
  /// In fr, this message translates to:
  /// **'PDF · enregistré dans Téléchargements/Huddle et lisible ensuite sans connexion.'**
  String get downloadAskWhere;

  /// No description provided for @download.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger'**
  String get download;

  /// No description provided for @aboutStatementPdf.
  ///
  /// In fr, this message translates to:
  /// **'Bilan général des membres : pour chacun, ce qu’il doit, ce qu’il a versé (validé), ce qui attend une validation et ce qui reste à payer, sur la période choisie.'**
  String get aboutStatementPdf;

  /// No description provided for @aboutCashbookPdf.
  ///
  /// In fr, this message translates to:
  /// **'Livre de caisse : les opérations (entrées et sorties) de la période, avec leur date, leur libellé, le membre concerné, qui les a saisies et validées, et leur montant ; avec une période, le solde au début et à la fin.'**
  String get aboutCashbookPdf;

  /// No description provided for @aboutReportPdf.
  ///
  /// In fr, this message translates to:
  /// **'Rapport financier du trimestre {quarter} {year} : solde d’ouverture, entrées et sorties, solde de clôture et entrées par catégorie.'**
  String aboutReportPdf(int quarter, int year);

  /// No description provided for @aboutMemberStatementPdf.
  ///
  /// In fr, this message translates to:
  /// **'Relevé de {name} : ce qu’il doit (cotisations, amendes), ce qu’il a versé, ce qui attend une validation et ce qui reste à payer.'**
  String aboutMemberStatementPdf(String name);

  /// No description provided for @faqGroupSection.
  ///
  /// In fr, this message translates to:
  /// **'Questions du groupe'**
  String get faqGroupSection;

  /// No description provided for @faqCommonSection.
  ///
  /// In fr, this message translates to:
  /// **'Questions courantes'**
  String get faqCommonSection;

  /// No description provided for @faqSuggest.
  ///
  /// In fr, this message translates to:
  /// **'Proposer une question'**
  String get faqSuggest;

  /// No description provided for @faqSuggestHint.
  ///
  /// In fr, this message translates to:
  /// **'Une question que d’autres se posent ? Proposez-la avec sa réponse : l’équipe Huddle la relit puis l’ajoute à l’aide.'**
  String get faqSuggestHint;

  /// No description provided for @faqMine.
  ///
  /// In fr, this message translates to:
  /// **'Mes propositions'**
  String get faqMine;

  /// No description provided for @faqPublished.
  ///
  /// In fr, this message translates to:
  /// **'Publiée'**
  String get faqPublished;

  /// No description provided for @faqDeclined.
  ///
  /// In fr, this message translates to:
  /// **'Non retenue'**
  String get faqDeclined;

  /// No description provided for @faqPending.
  ///
  /// In fr, this message translates to:
  /// **'En lecture'**
  String get faqPending;

  /// No description provided for @faqSent.
  ///
  /// In fr, this message translates to:
  /// **'Merci ! Votre question est envoyée à l’équipe Huddle.'**
  String get faqSent;

  /// No description provided for @faqQuestion.
  ///
  /// In fr, this message translates to:
  /// **'La question'**
  String get faqQuestion;

  /// No description provided for @faqQuestionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez la question.'**
  String get faqQuestionRequired;

  /// No description provided for @faqAnswer.
  ///
  /// In fr, this message translates to:
  /// **'La réponse (si vous la connaissez)'**
  String get faqAnswer;

  /// No description provided for @faqAnswerHint.
  ///
  /// In fr, this message translates to:
  /// **'L’équipe la corrige ou la complète avant de la publier.'**
  String get faqAnswerHint;

  /// No description provided for @faqSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get faqSend;

  /// No description provided for @myGroupSection.
  ///
  /// In fr, this message translates to:
  /// **'Mon groupe'**
  String get myGroupSection;

  /// No description provided for @groupRules.
  ///
  /// In fr, this message translates to:
  /// **'Règlement du groupe'**
  String get groupRules;

  /// No description provided for @groupCall.
  ///
  /// In fr, this message translates to:
  /// **'Appeler le groupe'**
  String get groupCall;

  /// No description provided for @groupMail.
  ///
  /// In fr, this message translates to:
  /// **'Écrire au groupe'**
  String get groupMail;

  /// No description provided for @groupLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien du groupe'**
  String get groupLink;

  /// No description provided for @recoveryCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de récupération (8 chiffres)'**
  String get recoveryCode;

  /// No description provided for @recoveryCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Donné par le responsable de votre groupe ou l’équipe Huddle. Valable 24 h, une seule fois.'**
  String get recoveryCodeHint;

  /// No description provided for @haveRecoveryCode.
  ///
  /// In fr, this message translates to:
  /// **'J’ai un code de récupération'**
  String get haveRecoveryCode;

  /// No description provided for @memberInactive.
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get memberInactive;

  /// No description provided for @memberOnProbation.
  ///
  /// In fr, this message translates to:
  /// **'À l’essai'**
  String get memberOnProbation;

  /// No description provided for @remindBefore.
  ///
  /// In fr, this message translates to:
  /// **'{hours, plural, =1{1 heure avant} other{{hours} heures avant}}'**
  String remindBefore(int hours);

  /// No description provided for @periodLabel.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get periodLabel;

  /// No description provided for @periodAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get periodAll;

  /// No description provided for @periodThisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get periodThisMonth;

  /// No description provided for @periodLastMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois dernier'**
  String get periodLastMonth;

  /// No description provided for @periodThisYear.
  ///
  /// In fr, this message translates to:
  /// **'Cette année'**
  String get periodThisYear;

  /// No description provided for @periodCustom.
  ///
  /// In fr, this message translates to:
  /// **'Choisir…'**
  String get periodCustom;

  /// No description provided for @periodWhole.
  ///
  /// In fr, this message translates to:
  /// **'Tout l’historique, jusqu’à aujourd’hui.'**
  String get periodWhole;

  /// No description provided for @periodRange.
  ///
  /// In fr, this message translates to:
  /// **'Du {from} au {to}.'**
  String periodRange(String from, String to);

  /// No description provided for @groupNetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réseau'**
  String get groupNetTitle;

  /// No description provided for @groupNetSheetHint.
  ///
  /// In fr, this message translates to:
  /// **'Les groupes au-dessus et rattachés'**
  String get groupNetSheetHint;

  /// No description provided for @groupNetNone.
  ///
  /// In fr, this message translates to:
  /// **'Votre groupe ne fait partie d’aucun réseau. L’équipe Huddle place les groupes dans un réseau (paroisses, zones, diocèses…).'**
  String get groupNetNone;

  /// No description provided for @groupNetIn.
  ///
  /// In fr, this message translates to:
  /// **'Réseau {network} · votre groupe : {level}.'**
  String groupNetIn(String network, String level);

  /// No description provided for @groupNetAbove.
  ///
  /// In fr, this message translates to:
  /// **'Rattaché à'**
  String get groupNetAbove;

  /// No description provided for @groupNetNoParent.
  ///
  /// In fr, this message translates to:
  /// **'Votre groupe n’est rattaché à aucun groupe.'**
  String get groupNetNoParent;

  /// No description provided for @groupNetJoinWithCode.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre avec un code'**
  String get groupNetJoinWithCode;

  /// No description provided for @groupNetJoinHint.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code d’invitation reçu du groupe de niveau supérieur (ex. votre zone).'**
  String get groupNetJoinHint;

  /// No description provided for @groupNetCodeLength.
  ///
  /// In fr, this message translates to:
  /// **'Le code a 8 caractères, ex. ABCD-EFGH.'**
  String get groupNetCodeLength;

  /// No description provided for @groupNetJoinAskTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rattacher votre groupe à {name} ?'**
  String groupNetJoinAskTitle(String name);

  /// No description provided for @groupNetUnder.
  ///
  /// In fr, this message translates to:
  /// **'Lui-même rattaché à {chain}'**
  String groupNetUnder(String chain);

  /// No description provided for @groupNetJoinAskBody.
  ///
  /// In fr, this message translates to:
  /// **'Ce groupe pourra informer le vôtre (annonces, événements). Il ne décide pas pour votre groupe et ne voit que ce que vous choisirez de partager. Vous pourrez vous détacher à tout moment.'**
  String get groupNetJoinAskBody;

  /// No description provided for @groupNetJoin.
  ///
  /// In fr, this message translates to:
  /// **'Rattacher'**
  String get groupNetJoin;

  /// No description provided for @groupNetJoined.
  ///
  /// In fr, this message translates to:
  /// **'Votre groupe est rattaché à {name}.'**
  String groupNetJoined(String name);

  /// No description provided for @groupNetLeave.
  ///
  /// In fr, this message translates to:
  /// **'Se détacher de {name}'**
  String groupNetLeave(String name);

  /// No description provided for @groupNetLeaveBody.
  ///
  /// In fr, this message translates to:
  /// **'Les présidents des deux groupes seront prévenus. Pour revenir, il faudra un nouveau code d’invitation.'**
  String get groupNetLeaveBody;

  /// No description provided for @groupNetLeaveReason.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez le motif.'**
  String get groupNetLeaveReason;

  /// No description provided for @groupNetLeaveConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Se détacher'**
  String get groupNetLeaveConfirm;

  /// No description provided for @groupNetLeft.
  ///
  /// In fr, this message translates to:
  /// **'Votre groupe n’est plus rattaché à {name}.'**
  String groupNetLeft(String name);

  /// No description provided for @groupNetBelow.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Groupes rattachés} =1{1 groupe rattaché} other{{count} groupes rattachés}}'**
  String groupNetBelow(int count);

  /// No description provided for @groupNetNoChildren.
  ///
  /// In fr, this message translates to:
  /// **'Aucun groupe rattaché pour l’instant.'**
  String get groupNetNoChildren;

  /// No description provided for @groupNetGroupsBelow.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 groupe en dessous} other{{count} groupes en dessous}}'**
  String groupNetGroupsBelow(int count);

  /// No description provided for @groupNetInvite.
  ///
  /// In fr, this message translates to:
  /// **'Inviter un groupe'**
  String get groupNetInvite;

  /// No description provided for @groupNetInviteAbout.
  ///
  /// In fr, this message translates to:
  /// **'Un code par groupe invité, valable 14 jours, une seule fois. Son président le saisit dans Réseau → Rejoindre avec un code.'**
  String get groupNetInviteAbout;

  /// No description provided for @groupNetInviteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code d’invitation'**
  String get groupNetInviteTitle;

  /// No description provided for @groupNetInviteHint.
  ///
  /// In fr, this message translates to:
  /// **'Envoyez ce code au président du groupe à inviter. Valable jusqu’au {date}, une seule fois.'**
  String groupNetInviteHint(String date);

  /// No description provided for @groupNetPendingCodes.
  ///
  /// In fr, this message translates to:
  /// **'Codes en attente'**
  String get groupNetPendingCodes;

  /// No description provided for @groupNetCodeUntil.
  ///
  /// In fr, this message translates to:
  /// **'Valable jusqu’au {date}'**
  String groupNetCodeUntil(String date);

  /// No description provided for @groupNetRevoke.
  ///
  /// In fr, this message translates to:
  /// **'Annuler ce code'**
  String get groupNetRevoke;

  /// No description provided for @groupNetCodeCopied.
  ///
  /// In fr, this message translates to:
  /// **'Code copié.'**
  String get groupNetCodeCopied;

  /// No description provided for @groupNetCodeRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Code annulé : il ne marche plus.'**
  String get groupNetCodeRevoked;

  /// No description provided for @groupNetUnknownCode.
  ///
  /// In fr, this message translates to:
  /// **'Code d’invitation inconnu. Vérifiez-le auprès du groupe qui vous invite.'**
  String get groupNetUnknownCode;

  /// No description provided for @groupNetAbout.
  ///
  /// In fr, this message translates to:
  /// **'Un groupe supérieur informe les groupes rattachés ; il ne décide pas pour eux et ne voit que ce que chaque groupe choisit de partager.'**
  String get groupNetAbout;

  /// No description provided for @copy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get copy;

  /// No description provided for @groupNetSharingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ce que nous partageons'**
  String get groupNetSharingTitle;

  /// No description provided for @groupNetSharingWith.
  ///
  /// In fr, this message translates to:
  /// **'Avec {name} et les groupes au-dessus'**
  String groupNetSharingWith(String name);

  /// No description provided for @groupNetSharingAbout.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez ce que les groupes au-dessus du vôtre peuvent voir. Là-haut, chaque partie n’est lue que par ceux dont le rôle la couvre (le trésorier pour les finances…). Rien n’est partagé tant que vous ne l’avez pas choisi.'**
  String get groupNetSharingAbout;

  /// No description provided for @groupNetSharingSaved.
  ///
  /// In fr, this message translates to:
  /// **'Partage enregistré. Les groupes au-dessus sont prévenus.'**
  String get groupNetSharingSaved;

  /// No description provided for @groupNetNeverShared.
  ///
  /// In fr, this message translates to:
  /// **'Jamais partagés : numéros de téléphone, codes, contacts des mineurs, pièces jointes, relevés personnels.'**
  String get groupNetNeverShared;

  /// No description provided for @groupNetKindMembers.
  ///
  /// In fr, this message translates to:
  /// **'Membres'**
  String get groupNetKindMembers;

  /// No description provided for @groupNetKindFinances.
  ///
  /// In fr, this message translates to:
  /// **'Finances'**
  String get groupNetKindFinances;

  /// No description provided for @groupNetKindCalendar.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get groupNetKindCalendar;

  /// No description provided for @groupNetKindAnnouncements.
  ///
  /// In fr, this message translates to:
  /// **'Annonces'**
  String get groupNetKindAnnouncements;

  /// No description provided for @groupNetKindReports.
  ///
  /// In fr, this message translates to:
  /// **'Présences et rapports'**
  String get groupNetKindReports;

  /// No description provided for @groupNetLevelNone.
  ///
  /// In fr, this message translates to:
  /// **'Rien'**
  String get groupNetLevelNone;

  /// No description provided for @groupNetLevelSummary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé'**
  String get groupNetLevelSummary;

  /// No description provided for @groupNetLevelDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail'**
  String get groupNetLevelDetail;

  /// No description provided for @groupNetHintMembers.
  ///
  /// In fr, this message translates to:
  /// **'Résumé : le nombre de membres. Détail : + les noms et les rôles.'**
  String get groupNetHintMembers;

  /// No description provided for @groupNetHintFinances.
  ///
  /// In fr, this message translates to:
  /// **'Résumé : le solde et les totaux de l’année. Détail : + les 30 dernières opérations validées.'**
  String get groupNetHintFinances;

  /// No description provided for @groupNetHintCalendar.
  ///
  /// In fr, this message translates to:
  /// **'Résumé : le nombre d’événements à 30 jours. Détail : + leurs dates et lieux.'**
  String get groupNetHintCalendar;

  /// No description provided for @groupNetHintAnnouncements.
  ///
  /// In fr, this message translates to:
  /// **'Détail : vos 10 dernières annonces (pas les convocations).'**
  String get groupNetHintAnnouncements;

  /// No description provided for @groupNetHintReports.
  ///
  /// In fr, this message translates to:
  /// **'Résumé : le taux de présence sur 3 mois. Détail : + les présences par événement.'**
  String get groupNetHintReports;

  /// No description provided for @groupNetSharesNone.
  ///
  /// In fr, this message translates to:
  /// **'Ne partage rien'**
  String get groupNetSharesNone;

  /// No description provided for @groupNetSharesList.
  ///
  /// In fr, this message translates to:
  /// **'Partage : {kinds}'**
  String groupNetSharesList(String kinds);

  /// No description provided for @groupNetTotals.
  ///
  /// In fr, this message translates to:
  /// **'{sharing, plural, =0{Aucun des {groups} groupes ne partage encore ses membres} =1{{members} membres, d’après 1 groupe sur {groups} qui partage ses membres} other{{members} membres, d’après {sharing} groupes sur {groups} qui partagent leurs membres}}'**
  String groupNetTotals(int members, int sharing, int groups);

  /// No description provided for @groupNetSharesNothing.
  ///
  /// In fr, this message translates to:
  /// **'Ce groupe ne partage rien'**
  String get groupNetSharesNothing;

  /// No description provided for @groupNetSharesNothingBody.
  ///
  /// In fr, this message translates to:
  /// **'Son président choisit ce qu’il partage, dans Réseau → Ce que nous partageons.'**
  String get groupNetSharesNothingBody;

  /// No description provided for @groupNetNotYourRole.
  ///
  /// In fr, this message translates to:
  /// **'Partagé, mais votre rôle dans ce groupe ne couvre pas cette partie.'**
  String get groupNetNotYourRole;

  /// No description provided for @groupNetMembersActive.
  ///
  /// In fr, this message translates to:
  /// **'Membres'**
  String get groupNetMembersActive;

  /// No description provided for @groupNetBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde validé'**
  String get groupNetBalance;

  /// No description provided for @groupNetYearIn.
  ///
  /// In fr, this message translates to:
  /// **'Entrées de l’année'**
  String get groupNetYearIn;

  /// No description provided for @groupNetYearOut.
  ///
  /// In fr, this message translates to:
  /// **'Sorties de l’année'**
  String get groupNetYearOut;

  /// No description provided for @groupNetUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'Événements à 30 jours'**
  String get groupNetUpcoming;

  /// No description provided for @groupNetNoneYet.
  ///
  /// In fr, this message translates to:
  /// **'Rien pour l’instant.'**
  String get groupNetNoneYet;

  /// No description provided for @groupNetEvents90.
  ///
  /// In fr, this message translates to:
  /// **'Événements avec appel (3 mois)'**
  String get groupNetEvents90;

  /// No description provided for @groupNetPresenceRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de présence'**
  String get groupNetPresenceRate;

  /// No description provided for @groupNetAttendance.
  ///
  /// In fr, this message translates to:
  /// **'{present} présents · {absent} absents · {excused} excusés'**
  String groupNetAttendance(int present, int absent, int excused);

  /// No description provided for @groupNetReportIn.
  ///
  /// In fr, this message translates to:
  /// **'Rapport'**
  String get groupNetReportIn;

  /// No description provided for @groupNetFrom.
  ///
  /// In fr, this message translates to:
  /// **'De la part de {name}'**
  String groupNetFrom(String name);

  /// No description provided for @groupNetEventFromAbove.
  ///
  /// In fr, this message translates to:
  /// **'Événement de {name}, transmis à votre groupe. Il se modifie et l’appel se fait dans {name}.'**
  String groupNetEventFromAbove(String name);

  /// No description provided for @groupNetSendDown.
  ///
  /// In fr, this message translates to:
  /// **'Aussi pour les groupes rattachés'**
  String get groupNetSendDown;

  /// No description provided for @groupNetSendDownHint.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Le groupe rattaché la reçoit aussi, avec une notification.} other{Les {count} groupes rattachés (et ceux en dessous) la reçoivent aussi, avec une notification.}}'**
  String groupNetSendDownHint(int count);

  /// No description provided for @groupNetSendDownEventHint.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Il apparaît aussi dans le calendrier du groupe rattaché.} other{Il apparaît aussi dans le calendrier des {count} groupes rattachés et de ceux en dessous.}}'**
  String groupNetSendDownEventHint(int count);

  /// No description provided for @contingentsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Personnes demandées aux groupes'**
  String get contingentsTitle;

  /// No description provided for @contingentsAbout.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez combien de personnes chaque groupe rattaché doit envoyer. Son responsable du planning choisit qui ; vous voyez les noms ici.'**
  String get contingentsAbout;

  /// No description provided for @contingentsNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande pour l’instant'**
  String get contingentsNone;

  /// No description provided for @contingentLess.
  ///
  /// In fr, this message translates to:
  /// **'Une personne de moins'**
  String get contingentLess;

  /// No description provided for @contingentMore.
  ///
  /// In fr, this message translates to:
  /// **'Une personne de plus'**
  String get contingentMore;

  /// No description provided for @contingentSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer les demandes'**
  String get contingentSend;

  /// No description provided for @contingentAsked.
  ///
  /// In fr, this message translates to:
  /// **'Demandes envoyées. Les responsables du planning des groupes sont prévenus.'**
  String get contingentAsked;

  /// No description provided for @contingentWaiting.
  ///
  /// In fr, this message translates to:
  /// **'En attente des noms'**
  String get contingentWaiting;

  /// No description provided for @contingentNamed.
  ///
  /// In fr, this message translates to:
  /// **'{named}/{requested} : {names}'**
  String contingentNamed(int named, int requested, String names);

  /// No description provided for @contingentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Personnes demandées'**
  String get contingentTitle;

  /// No description provided for @contingentAsk.
  ///
  /// In fr, this message translates to:
  /// **'{from} demande {count, plural, =1{1 personne} other{{count} personnes}}'**
  String contingentAsk(String from, int count);

  /// No description provided for @contingentNamedLabel.
  ///
  /// In fr, this message translates to:
  /// **'{named} désignée(s) sur {requested}'**
  String contingentNamedLabel(int named, int requested);

  /// No description provided for @contingentNobody.
  ///
  /// In fr, this message translates to:
  /// **'Personne n’est encore désigné.'**
  String get contingentNobody;

  /// No description provided for @contingentChoose.
  ///
  /// In fr, this message translates to:
  /// **'Désigner les personnes'**
  String get contingentChoose;

  /// No description provided for @contingentChooseHint.
  ///
  /// In fr, this message translates to:
  /// **'Seulement des membres actifs de votre groupe. Ils reçoivent une notification ; le groupe qui demande voit leurs noms.'**
  String get contingentChooseHint;

  /// No description provided for @contingentSaved.
  ///
  /// In fr, this message translates to:
  /// **'Désignation enregistrée.'**
  String get contingentSaved;

  /// No description provided for @contingentYou.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes désigné(e)'**
  String get contingentYou;

  /// No description provided for @groupNetSharingNeighbours.
  ///
  /// In fr, this message translates to:
  /// **'Avec les groupes voisins (même groupe au-dessus)'**
  String get groupNetSharingNeighbours;

  /// No description provided for @groupNetSharingTwins.
  ///
  /// In fr, this message translates to:
  /// **'Avec les groupes jumelés'**
  String get groupNetSharingTwins;

  /// No description provided for @groupNetNeighbours.
  ///
  /// In fr, this message translates to:
  /// **'Groupes voisins'**
  String get groupNetNeighbours;

  /// No description provided for @groupNetTwins.
  ///
  /// In fr, this message translates to:
  /// **'Groupes jumelés'**
  String get groupNetTwins;

  /// No description provided for @groupNetNoTwins.
  ///
  /// In fr, this message translates to:
  /// **'Aucun jumelage. Deux groupes de n’importe quel réseau peuvent se jumeler pour partager ce qu’ils choisissent.'**
  String get groupNetNoTwins;

  /// No description provided for @groupNetTwinInvite.
  ///
  /// In fr, this message translates to:
  /// **'Jumeler'**
  String get groupNetTwinInvite;

  /// No description provided for @groupNetTwinAccept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter un jumelage'**
  String get groupNetTwinAccept;

  /// No description provided for @groupNetTwinJoinHint.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code de jumelage reçu de l’autre groupe.'**
  String get groupNetTwinJoinHint;

  /// No description provided for @groupNetTwinAskTitle.
  ///
  /// In fr, this message translates to:
  /// **'Jumeler votre groupe avec {name} ?'**
  String groupNetTwinAskTitle(String name);

  /// No description provided for @groupNetTwinAskBody.
  ///
  /// In fr, this message translates to:
  /// **'Chaque groupe choisit ce qu’il partage avec ses groupes jumelés (rien au départ). Chacun peut mettre fin au jumelage.'**
  String get groupNetTwinAskBody;

  /// No description provided for @groupNetTwin.
  ///
  /// In fr, this message translates to:
  /// **'Jumeler'**
  String get groupNetTwin;

  /// No description provided for @groupNetTwinned.
  ///
  /// In fr, this message translates to:
  /// **'Votre groupe est jumelé avec {name}.'**
  String groupNetTwinned(String name);

  /// No description provided for @groupNetTwinCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code de jumelage'**
  String get groupNetTwinCodeTitle;

  /// No description provided for @groupNetTwinCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Envoyez ce code au président de l’autre groupe : il le saisit dans Réseau → Accepter un jumelage. Valable jusqu’au {date}, une seule fois.'**
  String groupNetTwinCodeHint(String date);

  /// No description provided for @groupNetTwinEnd.
  ///
  /// In fr, this message translates to:
  /// **'Mettre fin au jumelage'**
  String get groupNetTwinEnd;

  /// No description provided for @groupNetTwinEndTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mettre fin au jumelage avec {name}'**
  String groupNetTwinEndTitle(String name);

  /// No description provided for @groupNetTwinEndBody.
  ///
  /// In fr, this message translates to:
  /// **'Les présidents des deux groupes seront prévenus ; plus rien n’est partagé entre vous.'**
  String get groupNetTwinEndBody;

  /// No description provided for @groupNetTwinEnded.
  ///
  /// In fr, this message translates to:
  /// **'Jumelage avec {name} terminé.'**
  String groupNetTwinEnded(String name);

  /// No description provided for @catNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Quotes-parts du réseau'**
  String get catNetwork;

  /// No description provided for @netDuesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quotes-parts du réseau'**
  String get netDuesTitle;

  /// No description provided for @netDuesRowHint.
  ///
  /// In fr, this message translates to:
  /// **'Ce que vous devez au groupe au-dessus, ce que vous demandez aux groupes rattachés'**
  String get netDuesRowHint;

  /// No description provided for @netDuesAbout.
  ///
  /// In fr, this message translates to:
  /// **'Régler une quote-part ajoute une sortie dans votre livre de caisse et une entrée dans celui du groupe qui la demande ; chacune est approuvée comme d’habitude. Elle est « reçue » quand le groupe au-dessus a validé son entrée.'**
  String get netDuesAbout;

  /// No description provided for @netDuesOwed.
  ///
  /// In fr, this message translates to:
  /// **'À payer au groupe au-dessus'**
  String get netDuesOwed;

  /// No description provided for @netDuesNothingOwed.
  ///
  /// In fr, this message translates to:
  /// **'Rien à payer.'**
  String get netDuesNothingOwed;

  /// No description provided for @netDuesAsked.
  ///
  /// In fr, this message translates to:
  /// **'Demandé aux groupes rattachés'**
  String get netDuesAsked;

  /// No description provided for @netDuesNothingAsked.
  ///
  /// In fr, this message translates to:
  /// **'Aucune quote-part demandée.'**
  String get netDuesNothingAsked;

  /// No description provided for @netDueNew.
  ///
  /// In fr, this message translates to:
  /// **'Demander une quote-part'**
  String get netDueNew;

  /// No description provided for @netDueNewHint.
  ///
  /// In fr, this message translates to:
  /// **'Demandée à chaque groupe rattaché directement au vôtre ; leur équipe des finances est prévenue.'**
  String get netDueNewHint;

  /// No description provided for @netDueTitleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Intitulé (ex. Quote-part 2027)'**
  String get netDueTitleLabel;

  /// No description provided for @netDueAmountLabel.
  ///
  /// In fr, this message translates to:
  /// **'Montant par groupe'**
  String get netDueAmountLabel;

  /// No description provided for @netDueNoDate.
  ///
  /// In fr, this message translates to:
  /// **'Sans date limite (toucher pour en choisir une)'**
  String get netDueNoDate;

  /// No description provided for @netDueBefore.
  ///
  /// In fr, this message translates to:
  /// **'avant le {date}'**
  String netDueBefore(String date);

  /// No description provided for @netDueFormError.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez un intitulé et un montant.'**
  String get netDueFormError;

  /// No description provided for @netDueSend.
  ///
  /// In fr, this message translates to:
  /// **'Demander'**
  String get netDueSend;

  /// No description provided for @netDueAsked.
  ///
  /// In fr, this message translates to:
  /// **'Quote-part demandée. Les équipes des finances des groupes sont prévenues.'**
  String get netDueAsked;

  /// No description provided for @netDuePay.
  ///
  /// In fr, this message translates to:
  /// **'Régler'**
  String get netDuePay;

  /// No description provided for @netDuePayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Régler {amount} ?'**
  String netDuePayTitle(String amount);

  /// No description provided for @netDuePayBody.
  ///
  /// In fr, this message translates to:
  /// **'« {title} » pour {group}. Une sortie est ajoutée à votre livre de caisse (à approuver) et une entrée à celui de {group}.'**
  String netDuePayBody(String group, String title);

  /// No description provided for @netDuePaid.
  ///
  /// In fr, this message translates to:
  /// **'Quote-part réglée. Elle attend l’approbation des deux livres de caisse.'**
  String get netDuePaid;

  /// No description provided for @netDueCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get netDueCancel;

  /// No description provided for @netDueCancelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la quote-part de {group} ?'**
  String netDueCancelTitle(String group);

  /// No description provided for @netDueCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Quote-part annulée ; le groupe est prévenu.'**
  String get netDueCancelled;

  /// No description provided for @netDueOpen.
  ///
  /// In fr, this message translates to:
  /// **'À payer'**
  String get netDueOpen;

  /// No description provided for @netDueLate.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get netDueLate;

  /// No description provided for @netDueSent.
  ///
  /// In fr, this message translates to:
  /// **'Payée, à confirmer'**
  String get netDueSent;

  /// No description provided for @netDueReceived.
  ///
  /// In fr, this message translates to:
  /// **'Reçue'**
  String get netDueReceived;

  /// No description provided for @netDueCancelledBadge.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get netDueCancelledBadge;

  /// No description provided for @reportNetPaid.
  ///
  /// In fr, this message translates to:
  /// **'Versée à {group}'**
  String reportNetPaid(String group);

  /// No description provided for @reportNetReceived.
  ///
  /// In fr, this message translates to:
  /// **'Reçue de {group}'**
  String reportNetReceived(String group);

  /// No description provided for @reportNetNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune quote-part réglée sur le trimestre'**
  String get reportNetNone;

  /// No description provided for @reportNetOwedOpen.
  ///
  /// In fr, this message translates to:
  /// **'Restant à verser au groupe au-dessus'**
  String get reportNetOwedOpen;

  /// No description provided for @reportNetAskedOpen.
  ///
  /// In fr, this message translates to:
  /// **'Restant à recevoir des groupes rattachés'**
  String get reportNetAskedOpen;
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
