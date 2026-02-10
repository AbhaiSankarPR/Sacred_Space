import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../core/routes.dart';
import '../auth/auth_service.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = AuthService().currentUser;

    if (user == null) {
      Future.microtask(() => Navigator.pushReplacementNamed(context, Routes.login));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final bool isPriest = user.role.toLowerCase() == 'priest';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: AppDrawer(user: user),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, user, loc, isPriest),
          _buildDynamicMenuGrid(context, loc, isPriest),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  // --- 1. HEADER SECTION ---
  Widget _buildSliverAppBar(BuildContext context, User user, AppLocalizations loc, bool isPriest) {
    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      backgroundColor: const Color(0xFF5D3A99),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5D3A99), Color(0xFF9B59B6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                _buildProfileAvatar(user, isPriest),
                const SizedBox(height: 16),
                Text(
                  user.churchName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _buildRoleBadge(loc, user.role),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 2. DYNAMIC MENU GRID ---
  Widget _buildDynamicMenuGrid(BuildContext context, AppLocalizations loc, bool isPriest) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [
          // ANNOUNCEMENTS
          _DashboardMenuItem(
            title: isPriest ? loc.manageRequests : loc.announcements,
            icon: Icons.campaign_outlined,
            color: Colors.orange,
            onTap: () => Navigator.pushNamed(context, Routes.announcements),
          ),

          // BOOKINGS
          _DashboardMenuItem(
            title: isPriest ? loc.manageRequests : loc.bookings,
            icon: isPriest ? Icons.fact_check_outlined : Icons.bookmark_border,
            color: Colors.purple,
            onTap: () => Navigator.pushNamed(context, Routes.bookings),
          ),

          // PRIEST-ONLY (DIRECTORY & ADMIN)
          if (isPriest) ...[
            _DashboardMenuItem(
              title: loc.memberDirectory,
              icon: Icons.groups_outlined,
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, Routes.memberDirectory),
            ),
            _DashboardMenuItem(
              title: loc.galleryAdmin,
              icon: Icons.settings_applications_outlined,
              color: Colors.teal,
              onTap: () => Navigator.pushNamed(context, Routes.galleryAdmin),
            ),
          ],

          // MEMBER-ONLY (EVENTS & PROFILE)
          if (!isPriest) ...[
            _DashboardMenuItem(
              title: loc.events,
              icon: Icons.calendar_month_outlined,
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, Routes.events),
            ),
            _DashboardMenuItem(
              title: loc.myProfile,
              icon: Icons.person_outline,
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, Routes.profile),
            ),
          ],

          // EMERGENCY (SHARED)
          _DashboardMenuItem(
            title: loc.emergency,
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
            isAlert: true,
            onTap: () => Navigator.pushNamed(context, Routes.emergency),
          ),

          // SUPPORT (MEMBER ONLY)
          if (!isPriest)
            _DashboardMenuItem(
              title: loc.support,
              icon: Icons.headset_mic_outlined,
              color: Colors.teal,
              onTap: () => Navigator.pushNamed(context, Routes.support),
            ),
        ],
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildProfileAvatar(User user, bool isPriest) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
      ),
      child: CircleAvatar(
        radius: 38,
        backgroundColor: Colors.white,
        backgroundImage: (user.logoUrl != null && user.logoUrl!.isNotEmpty)
            ? NetworkImage(user.logoUrl!)
            : null,
        child: (user.logoUrl == null || user.logoUrl!.isEmpty)
            ? Icon(isPriest ? Icons.person : Icons.church, color: const Color(0xFF5D3A99), size: 36)
            : null,
      ),
    );
  }

  Widget _buildRoleBadge(AppLocalizations loc, String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        loc.accessType(role.toUpperCase()),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}

class _DashboardMenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isAlert;

  const _DashboardMenuItem({required this.title, required this.icon, required this.color, required this.onTap, this.isAlert = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: theme.cardColor,
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[800])),
          ],
        ),
      ),
    );
  }
}