import 'package:flutter/material.dart';
import '../core/routes.dart';
import '../auth/auth_service.dart';
import '../widgets/app_drawer.dart';

class MemberDashboard extends StatelessWidget {
  final User user;

  const MemberDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final themeGradientStart = Color(0xFF5D3A99); // deep purple
    final themeGradientEnd = Color(0xFF9B59B6);   // lighter purple

    return Scaffold(
      drawer: AppDrawer(user: user),
      body: SafeArea(
        child: Column(
          children: [
            // --- CUSTOM HEADER ---
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [themeGradientStart, themeGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 24,
                    left: 16,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: user.logoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                user.logoUrl!,
                                width: 68,
                                height: 68,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.church, color: Color(0xFF5D3A99), size: 36),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 110,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.churchName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.location,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Welcome ${user.role.toUpperCase()} 👋',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- DASHBOARD GRID (unchanged) ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _DashboardCard(
                      icon: Icons.announcement,
                      title: 'Announcements',
                      color: Colors.orange.shade300,
                      onTap: () => Navigator.pushNamed(context, Routes.announcements),
                    ),
                    _DashboardCard(
                      icon: Icons.event,
                      title: 'Events',
                      color: Colors.green.shade300,
                      onTap: () => ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Events coming soon!'))),
                    ),
                    _DashboardCard(
                      icon: Icons.person,
                      title: 'My Profile',
                      color: Colors.blue.shade300,
                      onTap: () => Navigator.pushNamed(context, Routes.profile),
                    ),
                    _DashboardCard(
                      icon: Icons.book_online,
                      title: 'Bookings',
                      color: Colors.purple.shade300,
                      onTap: () => Navigator.pushNamed(context, Routes.bookings),
                    ),
                    _DashboardCard(
                      icon: Icons.notifications,
                      title: 'Emergency Alerts',
                      color: Colors.red.shade300,
                      onTap: () => Navigator.pushNamed(context, Routes.emergency),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
