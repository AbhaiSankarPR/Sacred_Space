import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../core/theme_provider.dart';
import '../core/locale_provider.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access Providers
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final loc = AppLocalizations.of(context)!;

    // Fetch User safely
    final user = AuthService().currentUser;

    if (user == null) {
      Future.microtask(
        () => Navigator.pushReplacementNamed(context, Routes.login),
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.settings, // Make sure 'settings' is in your ARB
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: AppDrawer(user: user),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- SECTION: ACCOUNT ---
          _buildSectionHeader(loc.accountSection),
          _buildSettingsGroup(context, [
            _SettingsTile(
              icon: Icons.person_outline,
              title: loc.editProfile,
              onTap: () => Navigator.pushNamed(context, Routes.profile),
            ),
            _SettingsTile(
              icon: Icons.lock_outline,
              title: loc.changePassword,
              onTap: () {}, 
            ),
            _SettingsTile(
              icon: Icons.notifications_none,
              title: loc.notifications,
              trailing: Switch(
                value: true,
                activeColor: const Color(0xFF9B59B6),
                onChanged: (v) {},
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // --- SECTION: PREFERENCES ---
          _buildSectionHeader(loc.preferencesSection),
          _buildSettingsGroup(context, [
            _SettingsTile(
              icon: Icons.dark_mode_outlined,
              title: loc.darkMode,
              trailing: Switch(
                value: themeProvider.isDarkMode,
                activeColor: const Color(0xFF9B59B6),
                onChanged: (bool value) {
                  themeProvider.toggleTheme(value);
                },
              ),
            ),
            _SettingsTile(
              icon: Icons.language,
              title: loc.language,
              trailing: Text(
                localeProvider.locale.languageCode == 'en' ? "English" : "മലയാളം",
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              onTap: () => _showLanguageDialog(context, localeProvider),
            ),
          ]),

          const SizedBox(height: 24),

          // --- SECTION: SUPPORT ---
          _buildSectionHeader(loc.supportSection),
          _buildSettingsGroup(context, [
            _SettingsTile(
              icon: Icons.help_outline,
              title: loc.helpSupport,
              onTap: () => Navigator.pushNamed(context, Routes.support),
            ),
            _SettingsTile(
              icon: Icons.info_outline,
              title: loc.aboutApp,
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

  // Language Selection Dialog
  void _showLanguageDialog(BuildContext context, LocaleProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Select Language / ഭാഷ"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.language, color: Colors.blue),
              title: const Text("English"),
              trailing: provider.locale.languageCode == 'en' ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                provider.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.red),
              title: const Text("മലയാളം"),
              trailing: provider.locale.languageCode == 'ml' ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                provider.setLocale(const Locale('ml'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}