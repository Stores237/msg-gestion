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
}
