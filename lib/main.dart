import 'package:flutter/material.dart';
import 'core/routes.dart';

void main() {
  runApp(const SacredSpaceApp());
}

class SacredSpaceApp extends StatelessWidget {
  const SacredSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.login,
      routes: Routes.map,
    );
  }
}
