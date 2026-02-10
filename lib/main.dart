import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme_provider.dart';
import 'core/locale_provider.dart'; 
import 'core/routes.dart';
import 'app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Ensure Flutter engine is ready before any async calls
  WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      // We set initialRoute to Routes.splash to show our new loading screen
      child: const SacredSpaceApp(initialRoute: Routes.splash),
    ),
  );
}