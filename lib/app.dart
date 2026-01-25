import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'core/theme.dart';
import 'core/routes.dart';
import 'core/theme_provider.dart'; 

class SacredSpaceApp extends StatelessWidget {
  final String initialRoute;
  const SacredSpaceApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    // This line works now because main.dart provides the data!
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: Routes.map,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
    );
  }
}