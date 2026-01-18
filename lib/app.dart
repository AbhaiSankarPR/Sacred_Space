import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/routes.dart';

class SacredSpaceApp extends StatelessWidget {
  final String initialRoute;
  const SacredSpaceApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: Routes.map,
      theme: AppTheme.lightTheme,
    );
  }
}
