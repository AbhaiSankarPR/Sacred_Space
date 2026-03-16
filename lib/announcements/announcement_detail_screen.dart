import 'package:flutter/material.dart';
import 'announcement.dart';
import 'announcement_service.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final String announcementId;

  const AnnouncementDetailScreen({super.key, required this.announcementId});

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  late Future<Announcement> _detailFuture;

  @override
  void initState() {
    super.initState();
    _refreshDetail();
  }

  void _refreshDetail() {
    _detailFuture = AnnouncementService().getAnnouncementById(widget.announcementId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Responsive background color
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Ensure back button is always visible against the gradient
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Announcement>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF5D3A99)));
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading details", style: TextStyle(color: theme.colorScheme.error)));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("Announcement not found"));
          }

          final announcement = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => setState(() => _refreshDetail()),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(announcement, theme),
                  const SizedBox(height: 70),
                  _buildContent(announcement, theme),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Announcement announcement, ThemeData theme) {
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
            child: Icon(
              Icons.campaign_rounded, 
              size: 120, 
              color: Colors.white.withValues(alpha: 0.15) // Gradient icons stay light
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: 20,
          right: 20,
          child: _buildInfoCard(announcement, theme),
        ),
      ],
    );
  }

  Widget _buildInfoCard(Announcement announcement, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor, // Responsive card background
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black12, 
            blurRadius: 20, 
            offset: const Offset(0, 10)
          )
        ],
        border: isDark 
            ? Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1) 
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            announcement.title, 
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color
            )
          ),
          const SizedBox(height: 16),
          Divider(color: theme.dividerColor),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF5D3A99).withValues(alpha: 0.1), 
                child: const Icon(Icons.person, color: Color(0xFF5D3A99))
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement.priestName ?? "Church Office", 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color
                    )
                  ),
                  Text(
                    announcement.formattedDate, 
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color, 
                      fontSize: 12
                    )
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Announcement announcement, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "MESSAGE", 
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 2.0, 
              color: Color(0xFF5D3A99)
            )
          ),
          const SizedBox(height: 16),
          Text(
            announcement.message, 
            style: TextStyle(
              fontSize: 18, 
              height: 1.7, 
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.9)
            )
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}