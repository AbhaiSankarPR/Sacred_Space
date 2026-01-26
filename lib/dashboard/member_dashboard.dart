import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/routes.dart';
import '../auth/auth_service.dart';
import '../widgets/app_drawer.dart';

class MemberDashboard extends StatelessWidget {
  const MemberDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    if (user == null) {
      Future.microtask(() => Navigator.pushReplacementNamed(context, Routes.login));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Get the current theme to use dynamic colors
    final theme = Theme.of(context);

    return Scaffold(
      // Use the theme's background color (set in theme.dart)
      backgroundColor: theme.scaffoldBackgroundColor, 
      drawer: AppDrawer(user: user),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, user),
          _buildMenuGrid(context),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, User user) {
    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  // Avatar with Glow
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.white,
                      backgroundImage: (user.logoUrl != null && user.logoUrl!.isNotEmpty)
                          ? NetworkImage(user.logoUrl!)
                          : null,
                      child: (user.logoUrl == null || user.logoUrl!.isEmpty)
                          ? const Icon(Icons.church, color: Color(0xFF5D3A99), size: 36)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.churchName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.white.withOpacity(0.8)),
                      const SizedBox(width: 4),
                      Text(
                        user.location,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${user.role.toUpperCase()} ACCESS',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [
          _DashboardMenuItem(
            title: 'Announcements',
            icon: Icons.campaign_outlined,
            color: Colors.orange,
            onTap: () => Navigator.pushNamed(context, Routes.announcements),
          ),
          _DashboardMenuItem(
            title: 'Events',
            icon: Icons.calendar_month_outlined,
            color: Colors.green,
            onTap: () => Navigator.pushNamed(context, Routes.events),
          ),
          _DashboardMenuItem(
            title: 'My Profile',
            icon: Icons.person_outline,
            color: Colors.blue,
            onTap: () => Navigator.pushNamed(context, Routes.profile),
          ),
          _DashboardMenuItem(
            title: 'Bookings',
            icon: Icons.bookmark_border,
            color: Colors.purple,
            onTap: () => Navigator.pushNamed(context, Routes.bookings),
          ),
          _DashboardMenuItem(
            title: 'Emergency',
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
            isAlert: true,
            onTap: () => Navigator.pushNamed(context, Routes.emergency),
          ),
          _DashboardMenuItem(
            title: 'Support',
            icon: Icons.headset_mic_outlined,
            color: Colors.teal,
            onTap: () => Navigator.pushNamed(context, Routes.support),
          ),
        ],
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

  const _DashboardMenuItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    // Get theme context
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      // Dynamic Card Color (White in Light mode, Dark Grey in Dark mode)
      color: theme.cardColor,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                // Dynamic Text Color (Dark Grey in Light mode, White in Dark mode)
                color: isDark ? Colors.white70 : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}