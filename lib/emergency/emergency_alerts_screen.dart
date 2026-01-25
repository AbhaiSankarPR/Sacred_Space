import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';
import '../widgets/app_drawer.dart';

class EmergencyAlertsScreen extends StatelessWidget {
  const EmergencyAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    if (user == null) {
      Future.microtask(() => Navigator.pushReplacementNamed(context, Routes.login));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Access dynamic theme
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Dynamic Background
      appBar: AppBar(
        title: const Text(
          'Emergency Alerts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red.shade700, // Keep Red for urgency
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      drawer: AppDrawer(user: user),
      
      // Floating SOS Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showSOSDialog(context);
        },
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.campaign, size: 28),
        label: const Text(
          "REPORT SOS", 
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: ACTIVE ALERTS ---
            const Text(
              "Active Alerts",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            
            // Mock Active Alert
            const _EmergencyCard(
              title: "Heavy Rain Warning",
              description: "Severe flooding expected in lower parking areas. Please move vehicles immediately.",
              time: "10 mins ago",
              isActive: true,
            ),
            
            const SizedBox(height: 30),

            // --- SECTION 2: PAST HISTORY ---
            Text(
              "Recent History",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                // Dynamic text color
                color: isDark ? Colors.white70 : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            
            const _EmergencyCard(
              title: "Fire Drill Completed",
              description: "The scheduled fire drill for the north wing has been successfully completed.",
              time: "2 days ago",
              isActive: false,
            ),
             const _EmergencyCard(
              title: "Power Maintenance",
              description: "Main hall power was restored at 4:00 PM.",
              time: "5 days ago",
              isActive: false,
            ),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showSOSDialog(BuildContext context) {
    // Theme context for dialog
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // Background handled by theme
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text("Confirm SOS"),
          ],
        ),
        content: const Text(
          "Are you sure you want to broadcast an emergency signal to all admins? This should only be used for serious situations.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: theme.hintColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("SOS Signal Sent! Admins notified."),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text("SEND ALERT"),
          ),
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final String title;
  final String description;
  final String time;
  final bool isActive;

  const _EmergencyCard({
    required this.title,
    required this.description,
    required this.time,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Define colors based on state and theme
    final cardColor = theme.cardColor;
    final borderColor = isActive ? Colors.red.shade200 : (isDark ? Colors.white12 : Colors.transparent);
    final headerColor = isActive 
        ? (isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50)
        : (isDark ? Colors.grey.withOpacity(0.1) : Colors.grey.shade100);
    
    final titleColor = isActive 
        ? (isDark ? Colors.red.shade200 : Colors.red.shade900)
        : (isDark ? Colors.white : Colors.black87);
        
    final textColor = isDark ? Colors.white70 : Colors.grey[800];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isActive ? Border.all(color: borderColor, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: isActive 
                ? Colors.red.withOpacity(0.1) 
                : Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.notification_important : Icons.history, 
                  color: isActive ? Colors.red : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              description,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}