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
  
  // Profile Details
  final String? gender;         // MALE, FEMALE, OTHER
  final String? dob;            // ISO String
  final String? permanentAddress;
  final String? houseNumber;
  final String? residenceType;  // OWNED, RENTED
  final String? houseName;
  final String? phone;

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.churchId,
    required this.name,
    this.logoUrl,
    required this.churchName,
    required this.location,
    this.gender,
    this.dob,
    this.permanentAddress,
    this.houseNumber,
    this.residenceType,
    this.houseName,
    this.phone,
  });

  // Logic to check if profile needs completion
  // Added new fields to the check to ensure all required data is collected
  bool get isProfileIncomplete => 
      gender == null || 
      residenceType == null || 
      permanentAddress == null || 
      phone == null;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: json['role']?.toString().toLowerCase() ?? 'member',
      churchId: json['churchId'] ?? '',
      name: json['name'] ?? '',
      logoUrl: json['logoUrl'],
      churchName: json['churchName'] ?? "Sacred Space",
      location: json['location'] ?? "Community",
      gender: json['gender'],
      dob: json['dob'],
      permanentAddress: json['permanentAddress'],
      houseNumber: json['houseNumber'],
      residenceType: json['residenceType'],
      houseName: json['houseName'],
      phone: json['phone'],
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

  // --- 1. Get Church List ---
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

  // --- 2. Login ---
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

  // --- 3. Register ---
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

  // --- 4. Update Profile (Protected PUT Endpoint) ---
  Future<User> updateProfile({
    required String name,
    required String gender,
    required String dob,
    required String permanentAddress,
    required String houseNumber,
    required String residenceType,
    required String houseName,
    required String phone,
  }) async {
    if (_token == null) throw Exception("Session expired. Please login again.");

    final response = await http.put(
      Uri.parse('$_baseUrl/user/me/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'name': name,
        'gender': gender,
        'dob': dob,
        'permanentAddress': permanentAddress,
        'houseNumber': houseNumber,
        'residenceType': residenceType,
        'houseName': houseName,
        'phone': phone,
      }),
    );

    if (response.statusCode == 200) {
      // The output you provided contains the profile data. 
      // We update _currentUser locally to reflect these changes.
      final updatedProfileData = jsonDecode(response.body);
      
      // Usually, you might need to merge this with existing _currentUser data 
      // depending on if the PUT response returns the full user or just profile.
      // For now, we refresh the user state:
      if (_currentUser != null) {
        _currentUser = User(
          id: _currentUser!.id,
          email: _currentUser!.email,
          role: _currentUser!.role,
          churchId: _currentUser!.churchId,
          name: updatedProfileData['name'] ?? _currentUser!.name,
          logoUrl: _currentUser!.logoUrl,
          churchName: _currentUser!.churchName,
          location: _currentUser!.location,
          gender: updatedProfileData['gender'],
          dob: updatedProfileData['dob'],
          permanentAddress: updatedProfileData['permanentAddress'],
          houseNumber: updatedProfileData['houseNumber'],
          residenceType: updatedProfileData['residenceType'],
          houseName: updatedProfileData['houseName'],
          phone: phone, // phone was in params but maybe not in your output sample
        );
      }
      return _currentUser!;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Profile update failed');
    }
  }

  // --- 5. Logout ---
  Future<void> logout() async { 
    _currentUser = null;
    _token = null;
  }
}