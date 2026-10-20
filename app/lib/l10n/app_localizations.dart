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
  /// **'MSG Gestion'**
  String get appTitle;

  /// No description provided for @movementName.
  ///
  /// In fr, this message translates to:
  /// **'Mouvement Garde Suisse'**
  String get movementName;

  /// No description provided for @parishName.
  ///
  /// In fr, this message translates to:
  /// **'Paroisse Notre-Dame de Lourdes de Yapoma'**
  String get parishName;

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
  /// **'Connectez-vous avec le numéro de téléphone enregistré au mouvement.'**
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
  /// **'Pas encore de compte ? Le secrétaire général vous inscrit lors de l’assise du samedi.'**
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
  /// **'Demandez au secrétaire général de réinitialiser votre code lors de l’assise.'**
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
  /// **'Ce numéro n’est pas enregistré. Le secrétaire général vous inscrit lors de l’assise du samedi.'**
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
  /// **'Aucun code PIN pour ce compte. Demandez au secrétaire général de l’initialiser.'**
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
