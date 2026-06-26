class Member {
  final String id, name, email, phone, houseName;
  final String? profilePicUrl;

  Member({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.houseName,
    this.profilePicUrl,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    return Member(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: profile?['name'] ?? 'No Name',
      // Falls back to root phone if profile phone is missing
      phone: profile?['phone'] ?? (json['phone'] ?? 'No Phone'),
      houseName: profile?['houseName'] ?? 'No House Name',
      profilePicUrl: profile?['profilePicUrl'] ?? json['profilePicUrl'],
    );
  }
}
