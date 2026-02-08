import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // 1. Add Google Fonts
import 'core/theme.dart';
import 'core/routes.dart';
import 'core/theme_provider.dart';
import 'core/locale_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SacredSpaceApp extends StatelessWidget {
  final String initialRoute;
  const SacredSpaceApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    // Access providers
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    // 2. Logic to select the font based on the language
    // 'ml' uses Manjari, others (like 'en') use Inter
    final isMalayalam = localeProvider.locale.languageCode == 'ml';
    
    // 3. Define the base TextTheme
    // Note: We use .copyWith(height: 1.4) because Malayalam script is vertically taller
    TextTheme getDynamicTextTheme(TextTheme base) {
      return isMalayalam 
        ? GoogleFonts.manjariTextTheme(base).apply(bodyColor: base.bodyLarge?.color)
        : GoogleFonts.interTextTheme(base).apply(bodyColor: base.bodyLarge?.color);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: Routes.map,

      // Theme logic with Dynamic Font injection
      theme: AppTheme.lightTheme.copyWith(
        textTheme: getDynamicTextTheme(AppTheme.lightTheme.textTheme),
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        textTheme: getDynamicTextTheme(AppTheme.darkTheme.textTheme),
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Locale logic
      locale: localeProvider.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}