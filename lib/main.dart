import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. Import Provider
import 'core/theme_provider.dart';     // 2. Import your ThemeProvider
import 'core/routes.dart';
import 'auth/auth_service.dart';
import 'app.dart'; // 3. Import the file where SacredSpaceApp is defined

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check login status
  final authService = AuthService();
  final isLoggedIn = await authService.isLoggedIn();
  final initialRoute = isLoggedIn ? Routes.member : Routes.login;

  runApp(
    // 4. WRAP THE APP HERE
    // This injects the ThemeProvider into the app so SettingsScreen can find it.
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: SacredSpaceApp(initialRoute: initialRoute),
    ),
  );
}