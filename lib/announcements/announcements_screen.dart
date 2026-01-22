import 'package:flutter/material.dart';
import '../widgets/app_scaffold.dart';
import '../auth/auth_service.dart';
import 'announcement_service.dart';
import 'announcement.dart';

class AnnouncementsScreen extends StatefulWidget {
  final User user; // <-- receive user

  const AnnouncementsScreen({super.key, required this.user});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  late Future<List<Announcement>> announcements;

  @override
  void initState() {
    super.initState();
    announcements = AnnouncementService().fetchAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Announcements',
      user: widget.user, // <-- pass user to AppScaffold
      body: FutureBuilder<List<Announcement>>(
        future: announcements,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load announcements'));
          }
          final data = snapshot.data!;
          if (data.isEmpty) {
            return const Center(child: Text('No announcements available'));
          }
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final a = data[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(a.title),
                  subtitle: Text(a.message),
                  trailing: Text(a.date),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
