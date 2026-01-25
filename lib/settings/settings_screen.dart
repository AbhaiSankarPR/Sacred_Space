import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Mock States
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  bool _biometrics = false;

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) {
      Future.microtask(() => Navigator.pushReplacementNamed(context, Routes.login));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      drawer: AppDrawer(user: user),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- Account Section ---
          _buildSectionHeader("ACCOUNT"),
          _buildSettingsGroup([
            _SettingsTile(
              icon: Icons.person_outline,
              title: "Edit Profile",
              onTap: () => Navigator.pushNamed(context, Routes.profile),
            ),
            _SettingsTile(
              icon: Icons.lock_outline,
              title: "Change Password",
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.notifications_none,
              title: "Notifications",
              trailing: Switch(
                value: _notificationsEnabled,
                activeColor: const Color(0xFF5D3A99),
                onChanged: (val) => setState(() => _notificationsEnabled = val),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // --- App Settings ---
          _buildSectionHeader("PREFERENCES"),
          _buildSettingsGroup([
            _SettingsTile(
              icon: Icons.dark_mode_outlined,
              title: "Dark Mode",
              trailing: Switch(
                value: _darkMode,
                activeColor: const Color(0xFF5D3A99),
                onChanged: (val) => setState(() => _darkMode = val),
              ),
            ),
            _SettingsTile(
              icon: Icons.fingerprint,
              title: "Biometric Login",
              trailing: Switch(
                value: _biometrics,
                activeColor: const Color(0xFF5D3A99),
                onChanged: (val) => setState(() => _biometrics = val),
              ),
            ),
            _SettingsTile(
              icon: Icons.language,
              title: "Language",
              trailing: const Text("English", style: TextStyle(color: Colors.grey)),
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 24),

          // --- Support ---
          _buildSectionHeader("SUPPORT"),
          _buildSettingsGroup([
            _SettingsTile(
              icon: Icons.help_outline,
              title: "Help & Support",
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: "Privacy Policy",
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.info_outline,
              title: "About App",
              trailing: const Text("v1.0.0", style: TextStyle(color: Colors.grey)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

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
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF5D3A99).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF5D3A99), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}