import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/data_settings.dart';
import 'data/group_controller.dart';
import 'data/locale_controller.dart';
import 'data/offline.dart';
import 'data/theme_controller.dart';
import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleController.instance.load();
  await GroupController.instance.load();
  await ThemeController.instance.load();
  await initializeDateFormatting();
  await OfflineState.instance.load();
  await DataSettings.instance.load();
  runApp(const MsgApp());
}

class MsgApp extends StatelessWidget {
  const MsgApp({super.key, this.home});

  /// Tests pass a screen directly; the app starts at the splash.
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LocaleController.instance,
        ThemeController.instance,
      ]),
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        // The group's colour, or the member's own choice (ThemeController).
        theme: buildTheme(Brightness.light, ThemeController.instance.seed),
        darkTheme: buildTheme(Brightness.dark, ThemeController.instance.seed),
        // The member's choice (LocaleController); otherwise French unless the
        // phone is set to a language we also ship.
        locale: LocaleController.instance.locale,
        localeResolutionCallback: (device, supported) => supported.firstWhere(
          (l) => l.languageCode == device?.languageCode,
          orElse: () => const Locale('fr'),
        ),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home ?? const SplashScreen(),
      ),
    );
  }
}
