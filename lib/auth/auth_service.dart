import 'dart:convert';
import 'package:http/http.dart' as http;

class User {
  final String id;
  final String email;
  final String role;
  final String churchId;
  final String name;
  final String? logoUrl;
  final String churchName;
  final String location;

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.churchId,
    required this.name,
    this.logoUrl,
    required this.churchName,
    required this.location,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      role: json['role'].toString().toLowerCase(),
      churchId: json['churchId'],
      name: json['name'] ?? '',
      logoUrl: json['logoUrl'],
      // Fallbacks if backend doesn't provide these yet
      churchName: json['churchName'] ?? "Sacred Space",
      location: json['location'] ?? "Community",
    );
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final String _baseUrl = 'https://your-api-url.com'; 
  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

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
    } catch (e) { return []; }
  }

  Future<User> login({required String email, required String password, required String churchCode}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'churchId': churchCode}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      _currentUser = User.fromJson(data['user']);
      return _currentUser!;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Login failed');
    }
  }

  Future<User> register({required String name, required String email, required String password, required String churchId}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password, 'churchId': churchId}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      _currentUser = User.fromJson(data['user']);
      return _currentUser!;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Signup failed');
    }
  }

  void logout() {
    _currentUser = null;
    _token = null;
  }
}