import 'package:flutter/material.dart';
import 'announcement.dart';
import 'announcement_service.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final String announcementId; // We only need the ID now

  const AnnouncementDetailScreen({super.key, required this.announcementId});

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  late Future<Announcement> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = AnnouncementService().getAnnouncementById(widget.announcementId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Announcement>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF5D3A99)));
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading details: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("Announcement not found"));
          }

          final announcement = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(announcement),
                const SizedBox(height: 70),
                _buildContent(announcement),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Announcement announcement) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 280,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5D3A99), Color(0xFF8E44AD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: Center(
            child: Icon(Icons.campaign_rounded, size: 120, color: Colors.white.withOpacity(0.15)),
          ),
        ),
        Positioned(
          bottom: -50,
          left: 20,
          right: 20,
          child: _buildInfoCard(announcement),
        ),
      ],
    );
  }

  Widget _buildInfoCard(Announcement announcement) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(announcement.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Divider(),
          Row(
            children: [
              CircleAvatar(backgroundColor: const Color(0xFF5D3A99).withOpacity(0.1), child: const Icon(Icons.person, color: Color(0xFF5D3A99))),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(announcement.priestName ?? "Church Office", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(announcement.formattedDate, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Announcement announcement) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("MESSAGE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: Color(0xFF5D3A99))),
          const SizedBox(height: 16),
          Text(announcement.message, style: TextStyle(fontSize: 18, height: 1.7, color: Colors.grey[800])),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}