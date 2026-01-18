import 'package:flutter/material.dart';
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
    announcements = AnnouncementService().fetchAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
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
