import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/theme_provider.dart';
import '../core/locale_provider.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';
import '../widgets/app_drawer.dart';
import '../widgets/water_drop_notification.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool _isUploading = false;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkNotificationPermissionStatus();
  }

  @override
  void dispose() {
    // Clean up observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 2. Automatically re-check when returning from System Settings app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNotificationPermissionStatus();
    }
  }

  // 3. Check actual OS permission state
  Future<void> _checkNotificationPermissionStatus() async {
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _notificationsEnabled = status.isGranted;
      });
    }
  }

  // 4. Handle Switch Toggle Action
  Future<void> _handleNotificationToggle(bool enable) async {
    final status = await Permission.notification.status;

    if (enable) {
      if (status.isPermanentlyDenied || status.isRestricted) {
        // OS blocked popups. Prompt user to open system settings.
        _showOpenSettingsDialog();
      } else {
        // Request system permission popup
        final result = await Permission.notification.request();
        setState(() {
          _notificationsEnabled = result.isGranted;
        });
      }
    } else {
      // Direct user to settings to manually revoke/disable OS-level permissions
      _showOpenSettingsDialog();
    }
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Notification Settings"),
            content: const Text(
              "To change notification permissions, please update them in your system settings.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings(); // Native method to launch app OS settings page
                },
                child: const Text("Open Settings"),
              ),
            ],
          ),
    );
  }

  Future<void> _pickAndUploadBackground() async {
    final loc = AppLocalizations.of(context)!;
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        _isUploading = true;
      });

      if (!mounted) return;
      final authService = context.read<AuthService>();
      await authService.updateChurchBackground(result.files.first);

      if (!mounted) return;
      final overlayState = Overlay.of(context);
      late OverlayEntry overlayEntry;
      overlayEntry = OverlayEntry(
        builder:
            (context) => WaterDropNotification(
              message: loc.backgroundUpdated,
              onDismiss: () => overlayEntry.remove(),
            ),
      );
      overlayState.insert(overlayEntry);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final loc = AppLocalizations.of(context)!;

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
          loc.settings,
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
              onTap: () {
                Navigator.pushNamed(context, Routes.changePassword);
              },
            ),
            _SettingsTile(
              icon: Icons.family_restroom,
              title: loc.familyConnections,
              onTap:
                  () => Navigator.pushNamed(context, Routes.familyConnections),
            ),

            // --- DYNAMIC NOTIFICATION TILE HERE ---
            _SettingsTile(
              icon: Icons.notifications_none,
              title: loc.notifications,
              trailing: Switch(
                value:
                    _notificationsEnabled, // Dynamically set by actual system permission status
                activeColor: const Color(0xFF9B59B6),
                onChanged: _handleNotificationToggle,
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
                localeProvider.locale.languageCode == 'en'
                    ? "English"
                    : "മലയാളം",
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => _showLanguageDialog(context, localeProvider),
            ),
          ]),

          const SizedBox(height: 24),

          // --- SECTION: CHURCH MANAGEMENT (Priest Only) ---
          if (user.role.toLowerCase() == 'priest') ...[
            _buildSectionHeader(loc.churchManagementSection),
            _buildSettingsGroup(context, [
              _SettingsTile(
                icon: Icons.image_outlined,
                title: loc.uploadBackground,
                trailing:
                    _isUploading
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF5D3A99),
                          ),
                        )
                        : null,
                onTap: _isUploading ? null : _pickAndUploadBackground,
              ),
            ]),
            const SizedBox(height: 24),
          ],

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

  void _showLanguageDialog(BuildContext context, LocaleProvider provider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Select Language / ഭാഷ"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.blue),
                  title: const Text("English"),
                  trailing:
                      provider.locale.languageCode == 'en'
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                  onTap: () {
                    provider.setLocale(const Locale('en'));
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.red),
                  title: const Text("മലയാളം"),
                  trailing:
                      provider.locale.languageCode == 'ml'
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
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
      trailing:
          trailing ??
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}
