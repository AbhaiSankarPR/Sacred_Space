import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'core/theme.dart';
import 'core/routes.dart';
import 'core/theme_provider.dart';
import 'core/locale_provider.dart';

class SacredSpaceApp extends StatelessWidget {
  final String initialRoute;
  const SacredSpaceApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    // Access Providers for Theme and Language
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    // Identify current language
    final isMalayalam = localeProvider.locale.languageCode == 'ml';

    // Logic to select Lora for English and Gayathri for Malayalam
    TextTheme getDynamicTextTheme(TextTheme baseTheme) {
      if (isMalayalam) {
        // Malayalam Font: Gayathri
        return GoogleFonts.gayathriTextTheme(baseTheme).copyWith(
          // Malayalam characters are taller; height: 1.4 prevents clipping
          bodyLarge: baseTheme.bodyLarge?.copyWith(height: 1.4),
          bodyMedium: baseTheme.bodyMedium?.copyWith(height: 1.4),
          titleLarge: baseTheme.titleLarge?.copyWith(height: 1.4, fontWeight: FontWeight.bold),
        );
      } else {
        // English Font: Lora (Google Serif font)
        return GoogleFonts.loraTextTheme(baseTheme);
      }
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
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate, // Important for localized DatePickers
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}