import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';

class AppDrawer extends StatelessWidget {
  final User user;

  const AppDrawer({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    TextStyle drawerTextStyle = const TextStyle(
      fontFamily: 'Roboto', // modern font
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Colors.black87,
    );

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              user.churchName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(
              user.role.toUpperCase(),
              style: const TextStyle(fontSize: 14, letterSpacing: 1),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: user.logoUrl != null
                  ? Image.network(user.logoUrl!)
                  : const Icon(Icons.church, color: Colors.deepPurple, size: 36),
            ),
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.deepPurple),
            title: Text("Dashboard", style: drawerTextStyle),
            onTap: () => Navigator.pushNamed(context, '/${user.role}'),
          ),
          ListTile(
            leading: const Icon(Icons.book_online, color: Colors.deepPurple),
            title: Text("Bookings", style: drawerTextStyle),
            onTap: () => Navigator.pushNamed(context, Routes.bookings),
          ),
          ListTile(
            leading: const Icon(Icons.announcement, color: Colors.deepPurple),
            title: Text("Announcements", style: drawerTextStyle),
            onTap: () => Navigator.pushNamed(context, Routes.announcements),
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.deepPurple),
            title: Text("Emergency Alerts", style: drawerTextStyle),
            onTap: () => Navigator.pushNamed(context, Routes.emergency),
          ),
          const Spacer(),

          // Professional Logout button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  "Logout",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await AuthService().logout();
                  Navigator.pushNamedAndRemoveUntil(
                      context, Routes.login, (_) => false);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
