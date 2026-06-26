class SignupRequest {
  final String id;
  final String name;
  final String email;
  final String houseName;
  final String? profilePicUrl;

  SignupRequest({
    required this.id,
    required this.name,
    required this.email,
    required this.houseName,
    this.profilePicUrl,
  });

  factory SignupRequest.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    return SignupRequest(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: profile?['name'] ?? json['name'] ?? 'No Name',
      houseName: profile?['houseName'] ?? 'No House Name',
      profilePicUrl: profile?['profilePicUrl'] ?? json['profilePicUrl'],
    );
  }
}
