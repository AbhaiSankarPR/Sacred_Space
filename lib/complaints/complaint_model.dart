class ComplaintUser {
  final String name;
  final String? profilePicUrl;
  final String? role;

  ComplaintUser({
    required this.name,
    this.profilePicUrl,
    this.role,
  });

  factory ComplaintUser.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>? ?? json;
    return ComplaintUser(
      name: profile['name']?.toString() ?? '',
      profilePicUrl: profile['profilePicUrl']?.toString(),
      role: json['role']?.toString(),
    );
  }
}

class ComplaintReply {
  final String id;
  final String message;
  final String complaintId;
  final String userId;
  final DateTime createdAt;
  final ComplaintUser? user;

  ComplaintReply({
    required this.id,
    required this.message,
    required this.complaintId,
    required this.userId,
    required this.createdAt,
    this.user,
  });

  factory ComplaintReply.fromJson(Map<String, dynamic> json) {
    return ComplaintReply(
      id: json['id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      complaintId: json['complaintId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      user: json['user'] != null ? ComplaintUser.fromJson(json['user']) : null,
    );
  }
}

class Complaint {
  final String id;
  final String title;
  final String description;
  final String status; // OPEN, IN_PROGRESS, RESOLVED, CLOSED
  final String userId;
  final String churchId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ComplaintUser? user;
  final List<ComplaintReply> replies;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.userId,
    required this.churchId,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.replies = const [],
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    final repliesJson = json['replies'] as List? ?? [];
    final List<ComplaintReply> repliesList =
        repliesJson.map((r) => ComplaintReply.fromJson(r)).toList();

    return Complaint(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'OPEN',
      userId: json['userId']?.toString() ?? '',
      churchId: json['churchId']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      user: json['user'] != null ? ComplaintUser.fromJson(json['user']) : null,
      replies: repliesList,
    );
  }
}
