import 'announcement.dart';

class AnnouncementService {
  Future<List<Announcement>> fetchAnnouncements() async {
    // simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    return [
      Announcement(
        id: 1,
        title: 'Sunday Mass',
        message: 'Mass at 7:00 AM',
        date: '15 Jan 2026',
      ),
      Announcement(
        id: 2,
        title: 'Youth Meeting',
        message: 'Meeting after evening mass',
        date: '18 Jan 2026',
      ),
      Announcement(
        id: 3,
        title: 'Feast Day',
        message: 'Parish feast celebrations all day',
        date: '25 Jan 2026',
      ),
    ];
  }
}
