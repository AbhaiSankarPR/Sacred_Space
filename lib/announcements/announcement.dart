class Announcement {
  final int id;
  final String title;
  final String message;
  final String date;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      date: json['date'],
    );
  }
}
