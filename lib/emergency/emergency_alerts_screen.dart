import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../auth/auth_service.dart';

class EmergencyAlertsScreen extends StatelessWidget {
  final User? user; // <-- require user

  const EmergencyAlertsScreen({super.key, required this.user}); // <-- add required

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Alerts'),
      ),
      drawer: user != null ? AppDrawer(user: user!) : null, // <-- pass user explicitly
      body: const Center(
        child: Text(
          'No emergency alerts at the moment',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
