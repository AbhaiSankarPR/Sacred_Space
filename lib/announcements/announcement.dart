import 'package:intl/intl.dart';

class Announcement {
  final String id;
  final String title;
  final String message;
  final String churchId;
  final String createdBy;
  final DateTime createdAt;
  final String? priestName;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.churchId,
    required this.createdBy,
    required this.createdAt,
    this.priestName,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    // Handle the nested priest -> profile -> name structure
    String? pName;
    if (json['priest'] != null && json['priest']['profile'] != null) {
      pName = json['priest']['profile']['name'];
    }

    return Announcement(
      id: json['id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      churchId: json['churchId'] ?? '',
      createdBy: json['createdBy'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      priestName: pName,
    );
  }

  String get formattedDate => DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt);
}