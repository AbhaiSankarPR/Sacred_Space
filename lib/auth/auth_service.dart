import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './api_service.dart';
import '../core/navigator_key.dart';
import '../core/routes.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  User? _currentUser;
  User? get currentUser => _currentUser;
  final _storage = const FlutterSecureStorage();

  AuthService._internal() {
    apiService.onSessionExpired = logout;
  }

  // Restores session from local storage
// Updated tryAutoLogin: Restores full profile from SharedPreferences
Future<bool> tryAutoLogin() async {
  final token = await _storage.read(key: 'token');
  if (token == null) return false;

  final prefs = await SharedPreferences.getInstance();
  final userData = prefs.getString('user_data');
  
  if (userData != null) {
    _currentUser = User.fromJson(jsonDecode(userData));
    notifyListeners();
    // No mandatory fetchCurrentUser() here unless you want to sync in background
    return true;
  }
  return false;
}

  Future<User> fetchCurrentUser() async {
    final response = await apiService.get('/user/me');
    _currentUser = User.fromJson(response.data);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));
    notifyListeners();
    return _currentUser!;
  }

  Future<List<Map<String, String>>> getChurches() async {
    try {
      final response = await apiService.get('/churches');
      final List<dynamic> data = response.data;
      return data.map((church) => {
        'code': church['id'].toString(),
        'name': church['name'].toString(),
      }).toList();
    } catch (e) { return []; }
  }


  // Inside AuthService
Future<User> login({required String email, required String password, required String churchCode}) async {
  final response = await apiService.post('/auth/login', {
    'email': email, 
    'password': password, 
    'churchId': churchCode
  });

  // The 'user' key in your response already contains the profile data
  final user = User.fromJson(response.data['user']);
  
  // Save the accessToken and the user object locally
  await _saveAuthData(response.data['accessToken'], user);
  
  return user;
}

  Future<User> register({required String name, required String email, required String password, required String churchId}) async {
    final response = await apiService.post('/auth/register', {
      'name': name, 'email': email, 'password': password, 'churchId': churchId,
    });
    final user = User.fromJson(response.data['user']);
    await _saveAuthData(response.data['accessToken'], user);
    return user;
  }

  Future<User> updateProfile({
    required String name, required String gender, required String dob,
    required String permanentAddress, required String houseNumber,
    required String residenceType, required String houseName, required String phone,
  }) async {
    final response = await apiService.put('/user/me/profile', {
      'name': name, 'gender': gender, 'dob': dob,
      'permanentAddress': permanentAddress, 'houseNumber': houseNumber,
      'residenceType': residenceType, 'houseName': houseName, 'phone': phone,
    });
    _currentUser = _currentUser!.copyWith(
      name: name, gender: gender, dob: dob, phone: phone, 
      permanentAddress: permanentAddress, houseNumber: houseNumber,
      residenceType: residenceType, houseName: houseName,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));
    notifyListeners();
    return _currentUser!;
  }

  Future<void> _saveAuthData(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await _storage.write(key: 'token', value: token);
    await prefs.setString('user_data', jsonEncode(user.toJson()));
    _currentUser = user;
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await _storage.delete(key: 'token');
    notifyListeners();
    try { await apiService.post("/user/logout", {}); } catch (_) {}
    navigatorKey.currentState?.pushNamedAndRemoveUntil(Routes.login, (route) => false);
  }
}

class User {
  final String id, email, role, churchId, name, churchName, location;
  final String? logoUrl, gender, dob, permanentAddress, houseNumber, residenceType, houseName, phone;

  User({
    required this.id, required this.email, required this.role,
    required this.churchId, required this.name, this.logoUrl,
    required this.churchName, required this.location,
    this.gender, this.dob, this.permanentAddress,
    this.houseNumber, this.residenceType, this.houseName, this.phone,
  });


  User copyWith({
    String? name, String? gender, String? dob, String? permanentAddress,
    String? houseNumber, String? residenceType, String? houseName, String? phone,
  }) {
    return User(
      id: id, email: email, role: role, churchId: churchId, logoUrl: logoUrl,
      churchName: churchName, location: location,
      name: name ?? this.name, gender: gender ?? this.gender, dob: dob ?? this.dob,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      houseNumber: houseNumber ?? this.houseNumber, residenceType: residenceType ?? this.residenceType,
      houseName: houseName ?? this.houseName, phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'email': email, 'role': role, 'churchId': churchId, 'name': name,
    'logoUrl': logoUrl, 'churchName': churchName, 'location': location,
    'gender': gender, 'dob': dob, 'permanentAddress': permanentAddress,
    'houseNumber': houseNumber, 'residenceType': residenceType,
    'houseName': houseName, 'phone': phone,
  };
factory User.fromJson(Map<String, dynamic> json) {
final profile = json['profile'] as Map<String, dynamic>? ?? {};
  return User(
    id: json['id'] ?? '',
    email: json['email'] ?? '',
    // Converts "MEMBER" to "member"
    role: json['role']?.toString().toLowerCase() ?? 'member',
    churchId: json['churchId'] ?? '',
    name: profile['name'] ?? json['name'] ?? '',
    logoUrl: json['logoUrl'],
    churchName: json['churchName'] ?? "Sacred Space",
    location: json['location'] ?? "Community",
    gender: profile['gender'],
    dob: profile['dob'],
    permanentAddress: profile['permanentAddress'],
    houseNumber: profile['houseNumber'],
    residenceType: profile['residenceType'],
    houseName: profile['houseName'],
    // Safe handling since phone is missing in your JSON
    phone: json['phone'] ?? profile['phone'], 
  );
}

// Updated check: Since your JSON has nulls, this will correctly trigger
bool get isProfileIncomplete => gender == null || residenceType == null ;}