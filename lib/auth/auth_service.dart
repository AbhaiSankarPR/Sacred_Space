class AuthService {
  String? _role;

  /// Dummy login function
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String churchCode,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Dummy logic: return role based on email for testing
    if (email.contains("official")) {
      _role = 'official';
    } else if (email.contains("priest")) {
      _role = 'priest';
    } else if (email.contains("admin")) {
      _role = 'admin';
    } else {
      _role = 'member';
    }

    // Return dummy role
    return {'role': _role};
  }

  /// Save role locally (dummy)
  Future<void> saveRole(String role) async {
    _role = role;
  }

  /// Get saved role
  Future<String?> getRole() async {
    return _role;
  }

  /// Dummy logout
  Future<void> logout() async {
    _role = null;
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
