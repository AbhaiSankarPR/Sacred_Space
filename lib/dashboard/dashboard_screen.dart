import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../core/routes.dart';
import '../core/notification_helper.dart';
import 'package:provider/provider.dart'; // Added Provider
import '../auth/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../widgets/app_drawer.dart';
import 'package:marquee/marquee.dart';
import '../announcements/live_announcement_provider.dart';
import '../auth/activity_service.dart';

class DashboardScreen extends StatefulWidget {
  // Changed to StatefulWidget
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isExiting = false;

  Future<void> _handleSystemExit() async {
    if (_isExiting) return;
    setState(() {
      _isExiting = true;
    });

    try {
      await ActivityService().logActivity('LOGOUT');
      await ActivityService().syncQueue();
    } catch (e) {
      debugPrint("Error syncing activity on exit: $e");
    }

    SystemNavigator.pop();
  }

  Future<void> _handleDashboardRefresh() async {
    if (mounted) {
      await context.read<LiveAnnouncementProvider>().refreshLiveAnnouncements();
    }
  }

  @override
  void initState() {
    super.initState();

    // --- NOTIFICATION SYNC TRIGGER ---
    // This catches if the user enabled notifications in Phone Settings
    // or if the app needs to prompt for permission on the first arrival.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (pendingNotificationData != null) {
        final data = pendingNotificationData!;
        pendingNotificationData = null;
        handleNotificationNavigation(data);
      }

      final loc = AppLocalizations.of(context)!; // Define loc here
      if (mounted) {
        // Calls the method we added to AuthService
        final authService = context.read<AuthService>();

        // 1. Run the silent check (Syncs only if token/status changed since last run)
        await authService.checkPermissionsAndSync();

        // 2. Fetch Live Announcements
        context.read<LiveAnnouncementProvider>().refreshLiveAnnouncements();

        // 3. Check current status to see if we should prompt the user
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
    final bool isOfficial = user.isOfficial && !isPriest;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleSystemExit();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: AppDrawer(user: user),
        body: RefreshIndicator(
          onRefresh: _handleDashboardRefresh,
          color: const Color(0xFF5D3A99),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, user, loc, isPriest, isOfficial),
              _buildLiveAnnouncementBar(context, loc),
              _buildDynamicMenuGrid(context, loc, isPriest, isOfficial),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. HEADER SECTION ---
  Widget _buildSliverAppBar(
    BuildContext context,
    User user,
    AppLocalizations loc,
    bool isPriest,
    bool isOfficial,
  ) {
    final churchImage = context.watch<LiveAnnouncementProvider>().churchImage;
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
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            image: churchImage != null && churchImage.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(churchImage),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF5D3A99).withOpacity(churchImage != null ? 0.75 : 1.0),
                  const Color(0xFF7B1FA2).withOpacity(churchImage != null ? 0.85 : 1.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                _buildProfileAvatar(user, isPriest || isOfficial),
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
    ),
  );
}

  // --- 2. DYNAMIC MENU GRID ---
  Widget _buildDynamicMenuGrid(
    BuildContext context,
    AppLocalizations loc,
    bool isPriest,
    bool isOfficial,
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
            title: isPriest || isOfficial ? loc.manageRequests : loc.bookings,
            icon: isPriest || isOfficial ? Icons.fact_check_outlined : Icons.bookmark_border,
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
          
          if (isPriest || isOfficial) ...[
            _DashboardMenuItem(
              title: loc.transactions,
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFFE65100), // Deep Orange
              onTap: () => Navigator.pushNamed(context, Routes.transactions),
            ),
          ],
          _DashboardMenuItem(
            title: loc.events,
            icon: Icons.calendar_month_outlined,
            color: Colors.green,
            onTap: () => Navigator.pushNamed(context, Routes.events),
          ),
          // MEMBER-ONLY (EVENTS & PROFILE)
          if (!isPriest && !isOfficial) ...[
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

          // SUPPORT (MEMBER ONLY)
          if (!isPriest && !isOfficial)
            _DashboardMenuItem(
              title: loc.support,
              icon: Icons.headset_mic_outlined,
              color: Colors.teal,
              onTap: () => Navigator.pushNamed(context, Routes.support),
            ),

          // COMPLAINTS
          _DashboardMenuItem(
            title: loc.complaints,
            icon: Icons.chat_bubble_outline,
            color: Colors.blueAccent,
            onTap: () => Navigator.pushNamed(context, Routes.complaints),
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
            (user.profilePicUrl != null && user.profilePicUrl!.isNotEmpty)
                ? NetworkImage(user.profilePicUrl!)
                : (user.logoUrl != null && user.logoUrl!.isNotEmpty)
                    ? NetworkImage(user.logoUrl!)
                    : null,
        child:
            (user.profilePicUrl == null || user.profilePicUrl!.isEmpty) &&
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

  void _showLiveUpdatesBottomSheet(BuildContext context) {
    final provider = Provider.of<LiveAnnouncementProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            final announcements = provider.announcements;
            final events = provider.events;
            final bookings = provider.bookings;
            final bool hasAnyData = announcements.isNotEmpty || events.isNotEmpty || bookings.isNotEmpty;

            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Today's Updates",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF5D3A99),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                Expanded(
                  child: !hasAnyData
                      ? Center(
                          child: Text(
                            "No announcements or events for today.",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          children: [
                            if (announcements.isNotEmpty) ...[
                              _buildBottomSheetSectionHeader(
                                context,
                                "Announcements",
                                Icons.campaign_rounded,
                                const Color(0xFF5D3A99),
                              ),
                              const SizedBox(height: 8),
                              ...announcements.map((ann) {
                                return _buildBottomSheetItem(
                                  context: context,
                                  title: ann['title']?.toString() ?? '',
                                  icon: Icons.chevron_right_rounded,
                                  color: const Color(0xFF5D3A99),
                                  onTap: () {
                                    Navigator.pop(context);
                                    if (ann['id'] != null) {
                                      Navigator.pushNamed(
                                        context,
                                        Routes.announcementDetail,
                                        arguments: ann['id'].toString(),
                                      );
                                    } else {
                                      Navigator.pushNamed(context, Routes.announcements);
                                    }
                                  },
                                );
                              }),
                              const SizedBox(height: 20),
                            ],
                            if (events.isNotEmpty) ...[
                              _buildBottomSheetSectionHeader(
                                context,
                                "Today's Events",
                                Icons.event_available_rounded,
                                const Color(0xFF2E7D32),
                              ),
                              const SizedBox(height: 8),
                              ...events.map((ev) {
                                return _buildBottomSheetItem(
                                  context: context,
                                  title: ev['title']?.toString() ?? '',
                                  icon: Icons.calendar_month_rounded,
                                  color: const Color(0xFF2E7D32),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(context, Routes.events);
                                  },
                                );
                              }),
                              const SizedBox(height: 20),
                            ],
                            if (bookings.isNotEmpty) ...[
                              _buildBottomSheetSectionHeader(
                                context,
                                "Today's Bookings",
                                Icons.bookmark_border_rounded,
                                Colors.purple,
                              ),
                              const SizedBox(height: 8),
                              ...bookings.map((b) {
                                return _buildBottomSheetItem(
                                  context: context,
                                  title: b['title']?.toString() ?? '',
                                  icon: Icons.bookmark_added_rounded,
                                  color: Colors.purple,
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(context, Routes.bookings);
                                  },
                                );
                              }),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBottomSheetSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSheetItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveAnnouncementBar(BuildContext context, AppLocalizations loc) {
    final announcementProvider = context.watch<LiveAnnouncementProvider>();
    final String text = announcementProvider.liveMarqueeText;
    final bool isLoading = announcementProvider.isLoading;

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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: () => _showLiveUpdatesBottomSheet(context),
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
                    child: const Text(
                      "LIVE",
                      style: TextStyle(
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
                    child: isLoading && text.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              "Loading updates...",
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          )
                        : Marquee(
                            text: text.isEmpty
                                ? "✨ Welcome! Pull down to refresh today's updates.      "
                                : text,
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
