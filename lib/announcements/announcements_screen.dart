import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'announcement.dart';
import './announcement_detail_screen.dart';
import 'announcement_service.dart';
import '../auth/auth_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  late Future<List<Announcement>> _announcementsFuture;

  @override
  void initState() {
    super.initState();
    _refreshAnnouncements();
  }

  void _refreshAnnouncements() {
    setState(() {
      _announcementsFuture = AnnouncementService().getAnnouncements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = AuthService().currentUser;
    final isPriest = user?.role == 'priest';

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.announcements),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAnnouncements,
          ),
        ],
      ),
      body: FutureBuilder<List<Announcement>>(
        future: _announcementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No announcements yet."));
          }

          final announcements = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final item = announcements[index];
              return _buildAnnouncementCard(item);
            },
          );
        },
      ),
      floatingActionButton:
          isPriest
              ? FloatingActionButton(
                backgroundColor: const Color(0xFF5D3A99),
                child: const Icon(Icons.add, color: Colors.white),
                onPressed: () => _showAddAnnouncementDialog(context),
              )
              : null,
    );
  }

  Widget _buildAnnouncementCard(Announcement item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: InkWell(
        // Added InkWell for tap effect
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AnnouncementDetailScreen(
                    announcementId: item.id, // Passing the ID here
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.campaign,
                    color: Color(0xFF5D3A99),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.message,
                maxLines: 2, // Limit preview text
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[800], fontSize: 15),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFF5D3A99).withOpacity(0.1),
                    child: const Icon(
                      Icons.person,
                      size: 14,
                      color: Color(0xFF5D3A99),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.priestName ?? "Church Office",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.formattedDate,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddAnnouncementDialog(BuildContext context) {
    final titleController = TextEditingController();
    final msgController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("New Announcement"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                ),
                TextField(
                  controller: msgController,
                  decoration: const InputDecoration(labelText: "Message"),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty &&
                      msgController.text.isNotEmpty) {
                    await AnnouncementService().postAnnouncement(
                      titleController.text,
                      msgController.text,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      _refreshAnnouncements();
                    }
                  }
                },
                child: const Text("Post"),
              ),
            ],
          ),
    );
  }
}
