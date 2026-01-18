import 'package:flutter/material.dart';
import 'app.dart';
import 'auth/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final auth = AuthService();
  final role = await auth.getRole(); // member / official / priest / admin

  runApp(
    SacredSpaceApp(
      initialRoute: role != null ? '/$role' : '/',
    ),
  );
}
