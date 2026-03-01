import 'announcement.dart';
import '../auth/api_service.dart';

class AnnouncementService {
  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() => _instance;
  AnnouncementService._internal();

  // Get all announcements for the user's church
  Future<List<Announcement>> getAnnouncements() async {
    try {
      final response = await apiService.get('/user/announcements');
      final List<dynamic> data = response.data;
      return data.map((item) => Announcement.fromJson(item)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Priest only: Post new announcement
  Future<Announcement> postAnnouncement(String title, String message) async {
    try {
      final response = await apiService.post('/priest/announcement', {
        'title': title,
        'message': message,
      });
      return Announcement.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
  Future<Announcement> getAnnouncementById(String id) async {
  try {
    final response = await apiService.get('/user/announcements/$id');
    // Your API returns a single object, so we parse it directly
    return Announcement.fromJson(response.data);
  } catch (e) {
    rethrow;
  }
}
}

