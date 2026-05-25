import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../core/routes.dart';
import 'package:provider/provider.dart'; // Added Provider
import '../auth/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../widgets/app_drawer.dart';
import 'package:marquee/marquee.dart';

class DashboardScreen extends StatefulWidget {
  // Changed to StatefulWidget
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    // --- NOTIFICATION SYNC TRIGGER ---
    // This catches if the user enabled notifications in Phone Settings
    // or if the app needs to prompt for permission on the first arrival.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final loc = AppLocalizations.of(context)!; // Define loc here
      if (mounted) {
        // Calls the method we added to AuthService
        final authService = context.read<AuthService>();

        // 1. Run the silent check (Syncs only if token/status changed since last run)
        await authService.checkPermissionsAndSync();

        // 2. Check current status to see if we should prompt the user
        NotificationSettings settings =
            await FirebaseMessaging.instance.getNotificationSettings();

        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          _showNotificationPrompt(loc);
        }
      }
    });
  }

  void _showNotificationPrompt(AppLocalizations loc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          loc.notificationsDisabled ?? "Enable notifications to stay updated!",
        ),
        backgroundColor: const Color(0xFF5D3A99),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: loc.enable ?? "ENABLE",
          textColor: Colors.white,
          onPressed: () async {
            // Trigger the system permission popup
            NotificationSettings settings = await FirebaseMessaging.instance
                .requestPermission(alert: true, badge: true, sound: true);

            if (settings.authorizationStatus ==
                    AuthorizationStatus.authorized ||
                settings.authorizationStatus ==
                    AuthorizationStatus.provisional) {
              // Now that they granted permission, trigger the sync
              if (mounted) {
                context.read<AuthService>().checkPermissionsAndSync();
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = AuthService().currentUser;

    if (user == null) {
      Future.microtask(
        () => Navigator.pushReplacementNamed(context, Routes.login),
      );
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
          _buildLiveAnnouncementBar(context, loc),
          _buildDynamicMenuGrid(context, loc, isPriest),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  // --- 1. HEADER SECTION ---
  Widget _buildSliverAppBar(
    BuildContext context,
    User user,
    AppLocalizations loc,
    bool isPriest,
  ) {
    return SliverAppBar(
      expandedHeight: 260.0,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF5D3A99),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5D3A99), Color(0xFF7B1FA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Welcome, ${user.name}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRoleBadge(loc, user.role),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 2. DYNAMIC MENU GRID ---
  Widget _buildDynamicMenuGrid(
    BuildContext context,
    AppLocalizations loc,
    bool isPriest,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [
          _DashboardMenuItem(
            title: loc.parishCalendar ?? "Parish Calendar",
            icon: Icons.event_available_rounded,
            color: const Color(0xFF2E7D32), // Deep Church Green
            onTap: () => Navigator.pushNamed(context, Routes.parishCalendar),
          ),
          // ANNOUNCEMENTS
          _DashboardMenuItem(
            title: loc.announcements,
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
            _DashboardMenuItem(
              title: loc.signupRequests,
              icon: Icons.person_add_alt_1,
              color: const Color.fromARGB(255, 132, 42, 42),
              isAlert: true,
              onTap: () => Navigator.pushNamed(context, Routes.signupRequests),
            ),
            _DashboardMenuItem(
              title: loc.manageCertificates,
              icon: Icons.assignment_turned_in_rounded,
              color: const Color(0xFF009688), // Gorgeous Teal
              onTap: () => Navigator.pushNamed(context, Routes.certificate),
            ),
          ],
          _DashboardMenuItem(
            title: loc.events,
            icon: Icons.calendar_month_outlined,
            color: Colors.green,
            onTap: () => Navigator.pushNamed(context, Routes.events),
          ),
          // MEMBER-ONLY (EVENTS & PROFILE)
          if (!isPriest) ...[
            // _DashboardMenuItem(
            //   title: loc.myProfile,
            //   icon: Icons.person_outline,
            //   color: Colors.blue,
            //   onTap: () => Navigator.pushNamed(context, Routes.profile),
            // ),
            _DashboardMenuItem(
              title: loc.gallery,
              icon: Icons.photo_library_outlined,
              color: Colors.indigo,
              onTap: () => Navigator.pushNamed(context, Routes.gallery),
            ),
            _DashboardMenuItem(
              title: loc.certificates,
              icon: Icons.card_membership_rounded,
              color: const Color(0xFF009688), // Gorgeous Teal
              onTap: () => Navigator.pushNamed(context, Routes.certificate),
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

          // SETTINGS
          _DashboardMenuItem(
            title: loc.settings,
            icon: Icons.settings_outlined,
            color: Colors.blueGrey,
            onTap: () => Navigator.pushNamed(context, Routes.settings),
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
        backgroundImage:
            (user.logoUrl != null && user.logoUrl!.isNotEmpty)
                ? NetworkImage(user.logoUrl!)
                : null,
        child:
            (user.logoUrl == null || user.logoUrl!.isEmpty)
                ? Icon(
                  isPriest ? Icons.person : Icons.church,
                  color: const Color(0xFF5D3A99),
                  size: 36,
                )
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
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLiveAnnouncementBar(BuildContext context, AppLocalizations loc) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white, // Or theme.cardColor
            borderRadius: BorderRadius.circular(25), // Rounded pill shape
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left "Label" Badge
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5D3A99), Color(0xFF9B59B6)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  loc.announcements.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // The Marquee
              Expanded(
                child: Marquee(
                  text:
                      "✨ New Parish feast dates announced! • Sunday School starts at 9 AM • Welcome our new members!    ",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Colors.grey[800],
                  ),
                  blankSpace: 50.0,
                  velocity: 40.0,
                  pauseAfterRound: const Duration(seconds: 2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.15 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? Colors.white.withOpacity(0.9) : Colors.grey[800],
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
