import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';
import '../widgets/app_drawer.dart';
import 'announcement_service.dart';
import 'announcement.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  late Future<List<Announcement>> announcements;

  @override
  void initState() {
    super.initState();
    _refreshAnnouncements();
  }

  void _refreshAnnouncements() {
    setState(() {
      announcements = AnnouncementService().fetchAnnouncements();
    });
  }

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
    final bool isPriest = user.role.toLowerCase() == 'priest';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          loc.announcements, 
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      drawer: AppDrawer(user: user),
      
      // --- PRIEST FACILITY: FLOAT BUTTON (Localized) ---
      floatingActionButton: isPriest ? FloatingActionButton.extended(
        onPressed: () => _showCreateAnnouncementSheet(context, theme, loc),
        backgroundColor: const Color(0xFF5D3A99),
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: Text(loc.newNotice, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,

      body: FutureBuilder<List<Announcement>>(
        future: announcements,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: theme.colorScheme.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                loc.failedToLoadAnnouncements,
                style: TextStyle(color: theme.hintColor),
              ),
            );
          }
          final data = snapshot.data!;
          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: theme.hintColor),
                  const SizedBox(height: 16),
                  Text(
                    loc.noAnnouncementsAvailable,
                    style: TextStyle(color: theme.hintColor, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: data.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = data[index];
              final isLatest = index == 0; 
              
              return _AnnouncementCard(
                item: item, 
                isLatest: isLatest,
                theme: theme,
                isDark: isDark,
                loc: loc,
              );
            },
          );
        },
      ),
    );
  }

  // --- PRIEST FACILITY: COMPOSE BOTTOM SHEET (Localized) ---
  void _showCreateAnnouncementSheet(BuildContext context, ThemeData theme, AppLocalizations loc) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.composeNotice,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                )
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: loc.title,
                hintText: loc.enterAnnouncementHeading,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: loc.message,
                hintText: loc.shareWithParishHint,
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  // Logic for backend integration goes here
                  Navigator.pop(ctx);
                  _refreshAnnouncements();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.announcementPublishedSuccess),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF5D3A99),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D3A99),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(loc.postToParish, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement item;
  final bool isLatest;
  final ThemeData theme;
  final bool isDark;
  final AppLocalizations loc;

  const _AnnouncementCard({
    required this.item,
    required this.isLatest,
    required this.theme,
    required this.isDark,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey[700];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor, 
        borderRadius: BorderRadius.circular(16),
        border: isLatest 
            ? Border.all(color: const Color(0xFF5D3A99), width: 1.5) 
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLatest 
                  ? const Color(0xFF5D3A99).withOpacity(0.1) 
                  : Colors.transparent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isLatest ? const Color(0xFF5D3A99) : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLatest ? Icons.campaign : Icons.article_outlined,
                    color: isLatest ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.date,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isLatest ? const Color(0xFF5D3A99) : theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLatest)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      loc.newBadge,
                      style: const TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.red
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          if (!isLatest) Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey[200]),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              item.message,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: subTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}