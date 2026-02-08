import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';
import '../widgets/app_drawer.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = AuthService().currentUser;

    if (user == null) {
      Future.microtask(() => Navigator.pushReplacementNamed(context, Routes.login));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey[600];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.myProfile, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.editProfileComingSoon)),
              );
            },
          ),
        ],
      ),
      drawer: AppDrawer(user: user),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- PROFILE HEADER CARD ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF5D3A99).withOpacity(0.2), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                          backgroundImage: (user.logoUrl != null && user.logoUrl!.isNotEmpty)
                              ? NetworkImage(user.logoUrl!)
                              : null,
                          child: (user.logoUrl == null || user.logoUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 45, color: Color(0xFF5D3A99))
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5D3A99),
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.cardColor, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.churchName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D3A99).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5D3A99),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 16, color: subTextColor),
                      const SizedBox(width: 4),
                      Text(
                        user.location,
                        style: TextStyle(color: subTextColor, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- MENU SECTIONS ---
            _buildSectionTitle(loc.accountSettings, theme),
            _buildMenuCard(theme, [
              _ProfileMenuTile(
                icon: Icons.person_outline,
                title: loc.personalInformation,
                onTap: () {},
              ),
              _ProfileMenuTile(
                icon: Icons.lock_outline,
                title: loc.changePassword,
                onTap: () {},
              ),
              _ProfileMenuTile(
                icon: Icons.notifications_none,
                title: loc.notificationPreferences,
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 24),

            _buildSectionTitle(loc.appInfo, theme),
            _buildMenuCard(theme, [
              _ProfileMenuTile(
                icon: Icons.info_outline,
                title: loc.aboutUs,
                onTap: () {},
              ),
              _ProfileMenuTile(
                icon: Icons.privacy_tip_outlined,
                title: loc.privacyPolicy,
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 30),

            // --- LOGOUT BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Colors.red.withOpacity(0.2)),
                ),
                onPressed: () async {
                  await AuthService().logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
                  }
                },
                icon: const Icon(Icons.logout),
                label: Text(loc.logOut, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: theme.hintColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuCard(ThemeData theme, List<Widget> children) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

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
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: theme.hintColor),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}