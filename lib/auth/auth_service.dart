import 'dart:convert';
import 'package:http/http.dart' as http;

class User {
  final String id;
  final String email;
  final String role;
  final String churchId;
  final String name;

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.churchId,
    required this.name,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      // Normalizing "MEMBER" to "member" to match Navigator routes
      role: json['role'].toString().toLowerCase(),
      churchId: json['churchId'],
      name: json['name'],
    );
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Replace with your actual backend URL (e.g., http://10.0.2.2:3000 for Android emulator)
  final String _baseUrl = 'https://your-api-url.com'; 
  
  User? _currentUser;
  String? _token;

  /// Fetch dynamic church list for the Autocomplete
  Future<List<Map<String, String>>> getChurches() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/churches'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((church) => {
          'code': church['id'].toString(),
          'name': church['name'].toString(),
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<User> login({
    required String email,
    required String password,
    required String churchCode,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'churchId': churchCode,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      _token = data['token'];
      _currentUser = User.fromJson(data['user']);
      return _currentUser!;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Login failed');
    }
  }

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
  }
  
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String churchId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'churchId': churchId,
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      _token = data['token'];
      _currentUser = User.fromJson(data['user']);
      return _currentUser!;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Registration failed');
    }
  }
}