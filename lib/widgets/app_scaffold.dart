import 'package:flutter/material.dart';
import 'app_drawer.dart';
import '../auth/auth_service.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final User user; // required user

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
      ),
      drawer: AppDrawer(user: user), // pass user here
      body: SafeArea(child: body),
    );
  }
}
