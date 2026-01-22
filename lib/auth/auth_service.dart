class User {
  final String role;
  final String churchName;
  final String location;
  final String? logoUrl; // optional: if you want dynamic logos

  User({
    required this.role,
    required this.churchName,
    required this.location,
    this.logoUrl,
  });
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;

  /// Dummy login function
  Future<User> login({
    required String email,
    required String password,
    required String churchCode,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    String role;
    if (email.contains("official")) {
      role = 'official';
    } else if (email.contains("priest")) {
      role = 'priest';
    } else if (email.contains("admin")) {
      role = 'admin';
    } else {
      role = 'member';
    }

    String churchName = 'St. George Orthodox Church';
    String location = 'Edappally, Ernakulam';
    String? logoUrl = null;

    _currentUser = User(
      role: role,
      churchName: churchName,
      location: location,
      logoUrl: logoUrl,
    );

    return _currentUser!;
  }

  User? get currentUser => _currentUser;
  String? get role => _currentUser?.role;

  Future<void> logout() async {
    _currentUser = null;
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
