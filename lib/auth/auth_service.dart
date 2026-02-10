import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- USER MODEL ---
class User {
  final String id;
  final String email;
  final String role;
  final String churchId;
  final String name;
  final String? logoUrl;
  final String churchName;
  final String location;
  
  final String? gender;
  final String? dob;
  final String? permanentAddress;
  final String? houseNumber;
  final String? residenceType;
  final String? houseName;
  final String? phone;

  User({
    required this.id, required this.email, required this.role,
    required this.churchId, required this.name, this.logoUrl,
    required this.churchName, required this.location,
    this.gender, this.dob, this.permanentAddress,
    this.houseNumber, this.residenceType, this.houseName, this.phone,
  });

  bool get isProfileIncomplete => 
      gender == null || residenceType == null || permanentAddress == null || phone == null;

  User copyWith({
    String? name, String? gender, String? dob, String? permanentAddress,
    String? houseNumber, String? residenceType, String? houseName, String? phone,
  }) {
    return User(
      id: id, email: email, role: role, churchId: churchId, location: location,
      logoUrl: logoUrl, churchName: churchName,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      houseNumber: houseNumber ?? this.houseNumber,
      residenceType: residenceType ?? this.residenceType,
      houseName: houseName ?? this.houseName,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'email': email, 'role': role, 'churchId': churchId,
    'name': name, 'logoUrl': logoUrl, 'churchName': churchName,
    'location': location, 'gender': gender, 'dob': dob,
    'permanentAddress': permanentAddress, 'houseNumber': houseNumber,
    'residenceType': residenceType, 'houseName': houseName, 'phone': phone,
  };

  factory User.fromJson(Map<String, dynamic> json) {
    // Access nested profile object if it exists (from your GET user/me output)
    final profile = json['profile'] ?? {};
    
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: json['role']?.toString().toLowerCase() ?? 'member',
      churchId: json['churchId'] ?? '',
      // Map name from profile if available, else root
      name: profile['name'] ?? json['name'] ?? '',
      logoUrl: json['logoUrl'],
      churchName: json['churchName'] ?? "Sacred Space",
      location: json['location'] ?? "Community",
      // Map fields from the nested profile object
      gender: profile['gender'],
      dob: profile['dob'],
      permanentAddress: profile['permanentAddress'],
      houseNumber: profile['houseNumber'],
      residenceType: profile['residenceType'],
      houseName: profile['houseName'],
      phone: json['phone'] ?? profile['phone'], 
    );
  }
}

// --- AUTH SERVICE ---
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;

  // --- Persistence Methods ---

  Future<void> _saveAuthData(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('auth_token')) return false;

    _token = prefs.getString('auth_token');
    final userData = prefs.getString('user_data');
    if (userData != null) {
      _currentUser = User.fromJson(jsonDecode(userData));
      // Optionally refresh user data from server
      try { await fetchCurrentUser(); } catch (e) { /* use cached */ }
      return true;
    }
    return false;
  }

  // --- API Methods ---

  // New Method: GET user/me (Protected)
  Future<User> fetchCurrentUser() async {
    if (_token == null) throw Exception("Unauthorized");

    final response = await http.get(
      Uri.parse('$_baseUrl/user/me'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _currentUser = User.fromJson(data);
      await _saveAuthData(_token!, _currentUser!);
      return _currentUser!;
    } else {
      throw Exception("Failed to fetch user data");
    }
  }

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

  Future<User> register({
    required String name, required String email, 
    required String password, required String churchId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name, 'email': email, 'password': password, 'churchId': churchId,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      _currentUser = User.fromJson(data['user']);
      await _saveAuthData(_token!, _currentUser!);
      return _currentUser!;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Signup failed');
    }
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
      await _saveAuthData(_token!, _currentUser!);
      return _currentUser!;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Login failed');
    }
  }

  Future<User> updateProfile({
    required String name, required String gender, required String dob,
    required String permanentAddress, required String houseNumber,
    required String residenceType, required String houseName, required String phone,
  }) async {
    if (_token == null) throw Exception("Unauthorized");

    final response = await http.put(
      Uri.parse('$_baseUrl/user/me/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'name': name, 'gender': gender, 'dob': dob,
        'permanentAddress': permanentAddress, 'houseNumber': houseNumber,
        'residenceType': residenceType, 'houseName': houseName, 'phone': phone,
      }),
    );

    if (response.statusCode == 200) {
      final updatedData = jsonDecode(response.body);
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          name: updatedData['name'],
          gender: updatedData['gender'],
          dob: updatedData['dob'],
          permanentAddress: updatedData['permanentAddress'],
          houseNumber: updatedData['houseNumber'],
          residenceType: updatedData['residenceType'],
          houseName: updatedData['houseName'],
          phone: phone,
        );
        await _saveAuthData(_token!, _currentUser!);
      }
      return _currentUser!;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Profile update failed');
    }
  }

  Future<void> logout() async { 
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _currentUser = null;
    _token = null;
  }
}