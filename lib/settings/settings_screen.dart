import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme_provider.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Access the ThemeProvider state
    final themeProvider = Provider.of<ThemeProvider>(context);

    // 2. Fetch User safely
    final user = AuthService().currentUser;

    // Safety check: Redirect if no user found
    if (user == null) {
      Future.microtask(
        () => Navigator.pushReplacementNamed(context, Routes.login),
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      // Background color is handled automatically by the Theme
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: AppDrawer(user: user),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- SECTION: ACCOUNT ---
          _buildSectionHeader("ACCOUNT"),
          _buildSettingsGroup(context, [
            _SettingsTile(
              icon: Icons.person_outline,
              title: "Edit Profile",
              onTap: () => Navigator.pushNamed(context, Routes.profile),
            ),
            _SettingsTile(
              icon: Icons.lock_outline,
              title: "Change Password",
              onTap: () {}, // Add logic later
            ),
            _SettingsTile(
              icon: Icons.notifications_none,
              title: "Notifications",
              trailing: Switch(
                value: true,
                activeColor: const Color(0xFF9B59B6),
                onChanged: (v) {}, // Mock logic
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // --- SECTION: PREFERENCES ---
          _buildSectionHeader("PREFERENCES"),
          _buildSettingsGroup(context, [
            _SettingsTile(
              icon: Icons.dark_mode_outlined,
              title: "Dark Mode",
              // THE REAL SWITCH: Connects to ThemeProvider
              trailing: Switch(
                value: themeProvider.isDarkMode,
                activeColor: const Color(0xFF9B59B6),
                onChanged: (bool value) {
                  themeProvider.toggleTheme(value);
                },
              ),
            ),
            _SettingsTile(
              icon: Icons.fingerprint,
              title: "Biometric Login",
              trailing: Switch(
                value: false,
                activeColor: const Color(0xFF9B59B6),
                onChanged: (v) {}, // Mock logic
              ),
            ),
            _SettingsTile(
              icon: Icons.language,
              title: "Language",
              trailing: const Text(
                "English",
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 24),

          // --- SECTION: SUPPORT ---
          _buildSectionHeader("SUPPORT"),
          _buildSettingsGroup(context, [
            _SettingsTile(
              icon: Icons.help_outline,
              title: "Help & Support",
              onTap:
                  () => Navigator.pushNamed(
                    context,
                    Routes.support,
                  ), // UPDATE THIS
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: "Privacy Policy",
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.info_outline,
              title: "About App",
              trailing: const Text(
                "v1.0.0",
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () => Navigator.pushNamed(context, Routes.about),
            ),
          ]),
        ],
      ),
    );
  }

  // --- HELPER 1: Section Header ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey, // Grey works well in both Light and Dark mode
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // --- HELPER 2: Group Container ---
  Widget _buildSettingsGroup(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Dynamic color based on theme
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

// --- HELPER 3: Individual Setting Tile ---
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine text color dynamically based on theme
    final textColor =
        Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF5D3A99).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF5D3A99), size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      trailing:
          trailing ??
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
