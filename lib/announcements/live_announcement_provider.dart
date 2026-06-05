import 'package:flutter/material.dart';
import '../auth/api_service.dart';

class LiveAnnouncementProvider extends ChangeNotifier {
  String _liveMarqueeText = "";
  String get liveMarqueeText => _liveMarqueeText;

  String? _churchImage;
  String? get churchImage => _churchImage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> refreshLiveAnnouncements() async {
    _isLoading = true;
    notifyListeners();

    try {
      final nowStr = DateTime.now().toIso8601String();
      final response = await apiService.get(
        '/user/me/dashboard',
        params: {'clientNow': nowStr},
      );

      final data = response.data;
      if (data != null) {
        // Parse background image
        _churchImage = data['churchImage']?.toString();

        final List<dynamic> announcements = data['announcements'] ?? [];
        final List<dynamic> events = data['events'] ?? [];
        final List<dynamic> bookings = data['bookings'] ?? [];

        List<String> items = [];

        // Add general announcements
        for (var ann in announcements) {
          final title = ann['title']?.toString().trim() ?? '';
          if (title.isNotEmpty) {
            items.add("✨ $title");
          }
        }

        // Add events
        for (var ev in events) {
          final title = ev['title']?.toString().trim() ?? '';
          if (title.isNotEmpty) {
            items.add("📅 Event: $title");
          }
        }

        // Add bookings
        for (var b in bookings) {
          final title = b['title']?.toString().trim() ?? '';
          if (title.isNotEmpty) {
            items.add("🔒 Booked: $title");
          }
        }

        if (items.isEmpty) {
          _liveMarqueeText = "✨ Welcome to Sacred Space! No scheduled events or announcements for today.      ";
        } else {
          _liveMarqueeText = "${items.join('   •   ')}      ";
        }
      }
    } catch (e) {
      debugPrint("Error fetching live dashboard announcements: $e");
      // Fallback message if call fails
      if (_liveMarqueeText.isEmpty) {
        _liveMarqueeText = "✨ Welcome! Pull down to refresh today's updates.      ";
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
