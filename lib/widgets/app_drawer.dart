import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';

class AppDrawer extends StatelessWidget {
  final User user;

  const AppDrawer({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: theme.cardColor,
      child: Column(
        children: [
          _buildHeader(theme),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                _DrawerItem(
                  icon: Icons.dashboard_outlined,
                  title: loc.dashboard,
                  onTap: () => Navigator.pushReplacementNamed(context, Routes.member),
                  isSelected: currentRoute == Routes.member,
                ),
                _DrawerItem(
                  icon: Icons.bookmark_border_rounded,
                  title: loc.bookings,
                  onTap: () => Navigator.pushReplacementNamed(context, Routes.bookings),
                  isSelected: currentRoute == Routes.bookings,
                ),
                _DrawerItem(
                  icon: Icons.campaign_outlined,
                  title: loc.announcements,
                  onTap: () => Navigator.pushReplacementNamed(context, Routes.announcements),
                  isSelected: currentRoute == Routes.announcements,
                ),
                _DrawerItem(
                  icon: Icons.calendar_month_outlined,
                  title: loc.events,
                  onTap: () => Navigator.pushReplacementNamed(context, Routes.events),
                  isSelected: currentRoute == Routes.events,
                ),
                _DrawerItem(
                  icon: Icons.photo_library_outlined,
                  title: loc.gallery,
                  onTap: () => Navigator.pushReplacementNamed(context, Routes.gallery),
                  isSelected: currentRoute == Routes.gallery,
                ),
                _DrawerItem(
                  icon: Icons.warning_amber_rounded,
                  title: loc.emergencyAlerts,
                  onTap: () => Navigator.pushReplacementNamed(context, Routes.emergency),
                  isSelected: currentRoute == Routes.emergency,
                  isAlert: true,
                ),
                Divider(height: 32, color: isDark ? Colors.white24 : Colors.black12),
                _DrawerItem(
                  icon: Icons.person_outline,
                  title: loc.profile,
                  onTap: () => Navigator.pushReplacementNamed(context, Routes.profile),
                  isSelected: currentRoute == Routes.profile,
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  title: loc.settings,
                  onTap: () => Navigator.pushReplacementNamed(context, Routes.settings),
                  isSelected: currentRoute == Routes.settings,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: _LogoutButton(
              title: loc.signOut,
              onTap: () async {
                await AuthService().logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5D3A99), Color(0xFF8E44AD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              backgroundImage: (user.logoUrl != null && user.logoUrl!.isNotEmpty)
                  ? NetworkImage(user.logoUrl!)
                  : null,
              child: (user.logoUrl == null || user.logoUrl!.isEmpty)
                  ? const Icon(Icons.church, size: 32, color: Color(0xFF5D3A99))
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.churchName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.role.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isAlert;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isSelected = false,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isSelected ? const Color(0xFF9B59B6) : (isDark ? Colors.white70 : Colors.black87);
    final iconColor = isAlert ? Colors.red : (isSelected ? const Color(0xFF9B59B6) : (isDark ? Colors.white60 : Colors.grey[700]));
    final bgColor = isSelected ? const Color(0xFF5D3A99).withOpacity(isDark ? 0.2 : 0.1) : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: bgColor,
        leading: Icon(icon, color: iconColor, size: 26),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  final String title;

  const _LogoutButton({required this.onTap, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? Colors.red.withOpacity(0.15) : Colors.red.shade50,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}