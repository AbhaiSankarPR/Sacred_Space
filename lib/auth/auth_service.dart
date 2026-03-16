import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Added Firebase dependency
import './api_service.dart';
import '../core/navigator_key.dart';
import '../core/routes.dart';
import '../events/event_model.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  User? _currentUser;
  User? get currentUser => _currentUser;
  final _storage = const FlutterSecureStorage();

  AuthService._internal() {
    apiService.onSessionExpired = () => logout(null);
    initializeTokenListeners();
  }
  Future<void> checkPermissionsAndSync() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // 1. Get CURRENT settings (this does NOT show a popup)
  NotificationSettings settings = await messaging.getNotificationSettings();
  String currentStatus = settings.authorizationStatus.toString();
  
  // 2. Get LAST SAVED settings and token
  String? lastStatus = prefs.getString('last_notification_status');
  String? lastSyncedToken = prefs.getString('lastSyncedToken');

  // 3. Get the current token
  String? currentToken = await messaging.getToken();

  // 4. CHECK FOR CHANGES
  // We sync if: Status changed OR the token itself changed
  bool hasStatusChanged = currentStatus != lastStatus;
  bool hasTokenChanged = currentToken != lastSyncedToken;

  if (hasStatusChanged || hasTokenChanged) {
    debugPrint("Notification Change Detected. Syncing...");

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      
      if (currentToken != null && _currentUser != null) {
        // Sync with backend
        await syncDeviceToken(currentToken);
        
        // Update local storage to remember this state
        await prefs.setString('last_notification_status', currentStatus);
        await prefs.setString('lastSyncedToken', currentToken);
        await prefs.setString('deviceToken', currentToken); // Keep your original key too
      }
    } 
    // Handle the case where they REVOKED permission (Optional but recommended)
    else if (settings.authorizationStatus == AuthorizationStatus.denied) {
       if (lastSyncedToken != null) {
         await unregisterDevice(lastSyncedToken);
         await prefs.remove('last_notification_status');
         await prefs.remove('lastSyncedToken');
       }
    }
  } else {
    debugPrint("Notifications in sync. No network call needed.");
  }
}

  // Restores session from local storage and triggers sync
  Future<bool> tryAutoLogin() async {
    final token = await _storage.read(key: 'token');
    if (token == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');

    if (userData != null) {
      _currentUser = User.fromJson(jsonDecode(userData));
      notifyListeners();

      // Sync user data and notification token in background
      fetchCurrentUser()
          .then((_) async {
            String? fcmToken = await FirebaseMessaging.instance.getToken();
            if (fcmToken != null) syncDeviceToken(fcmToken);
          })
          .catchError((e) => debugPrint("Sync failed: $e"));

      return true;
    }
    return false;
  }

  Future<User> fetchCurrentUser() async {
    final response = await apiService.get('/user/me');
    _currentUser = User.fromJson(response.data);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));
    await prefs.setString('userId', _currentUser!.id);
    notifyListeners();
    return _currentUser!;
  }

  Future<List<Map<String, String>>> getChurches() async {
    try {
      final response = await apiService.get('/churches');
      final List<dynamic> data = response.data;
      return data
          .map(
            (church) => {
              'code': church['id'].toString(),
              'name': church['name'].toString(),
            },
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<User> login({
    required String email,
    required String password,
    required String churchCode,
    String? deviceToken,
  }) async {
    final response = await apiService.post('/auth/login', {
      'email': email,
      'password': password,
      'churchId': churchCode,
      if (deviceToken != null) 'deviceToken': deviceToken,
    });

    final user = User.fromJson(response.data['user']);
    await _saveAuthData(response.data['accessToken'], user);

    // Sync notification settings after login
    // if (deviceToken != null) {
    //   syncDeviceToken(deviceToken);
    // }

    return user;
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String churchId,
    String? deviceToken,
  }) async {
    final response = await apiService.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'churchId': churchId,
      if (deviceToken != null) 'deviceToken': deviceToken,
    });
    final user = User.fromJson(response.data['user']);
    await _saveAuthData(response.data['accessToken'], user);
    return user;
  }

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
    final response = await apiService.put('/user/me/profile', {
      'name': name,
      'gender': gender,
      'dob': dob,
      'permanentAddress': permanentAddress,
      'houseNumber': houseNumber,
      'residenceType': residenceType,
      'houseName': houseName,
      'phone': phone,
    });
    _currentUser = _currentUser!.copyWith(
      name: name,
      gender: gender,
      dob: dob,
      phone: phone,
      permanentAddress: permanentAddress,
      houseNumber: houseNumber,
      residenceType: residenceType,
      houseName: houseName,
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
    await prefs.setString('userId', user.id); 
    _currentUser = user;
    notifyListeners();
  }

  Future<void> syncDeviceToken(String deviceToken) async {
    if (_currentUser == null) return;
    try {
      await apiService.post('/notification/sync', {'deviceToken': deviceToken});

      // Topic: church_ST_JOSEPHS_KOCHI
      String topic = "church_${_currentUser!.churchId}";
      await FirebaseMessaging.instance.subscribeToTopic(topic);

      debugPrint("Subscribed to topic: $topic");
    } catch (e) {
      debugPrint("Token sync failed: $e");
    }
  }

  // 1. Separate Unregister Method
  Future<void> unregisterDevice(String? deviceToken) async {
    if (deviceToken == null || deviceToken.isEmpty) return;

    try {
      await apiService.post("/notification/unregister", {
        "deviceToken": deviceToken,
      });
      debugPrint("Device token unregistered successfully.");
    } catch (e) {
      debugPrint("Error unregistering device: $e");
      // We don't throw here so logout can still proceed even if network fails
    }
  }

  // 2. Updated Logout Method
  Future<void> logout(String? deviceToken) async {
    // Call the logout API with the deviceToken in the body
    print(deviceToken);
    try {
      await apiService.post("/user/logout", {
        "deviceToken": deviceToken, // Sending device token along with logout
      });
    } catch (_) {}

    // Local Cleanup
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();

    // Make sure 'userId' is also removed if you're using it for self-notification filters
    await prefs.remove('user_data');
    await prefs.remove('userId');

    await _storage.delete(key: 'token');

    notifyListeners();

    // Navigate to Login and clear stack
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      Routes.login,
      (route) => false,
    );
  }

  void initializeTokenListeners() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // 1. Get the OLD token from storage before overwriting it
      String? oldToken = prefs.getString('deviceToken');

      // 2. If we have an old token and a user is logged in, unregister it
      if (_currentUser != null && oldToken != null && oldToken != newToken) {
        debugPrint("Refreshing token: Unregistering old token...");
        await unregisterDevice(oldToken);
      }

      // 3. Update Local Storage with the NEW token
      await prefs.setString('deviceToken', newToken);
      debugPrint("New token saved locally: $newToken");

      // 4. Sync the NEW token with the backend
      if (_currentUser != null) {
        try {
          await syncDeviceToken(newToken);
          debugPrint("New token synced with backend.");
        } catch (e) {
          debugPrint("Failed to sync new token: $e");
        }
      }
    });
  }
  // 1. Fetch all members for the Priest
  Future<List<dynamic>> getAllMembers() async {
    try {
      final response = await apiService.get('/priest/users');
      // The backend returns a List of user objects
      return response.data as List<dynamic>;
    } catch (e) {
      debugPrint("Error fetching members: $e");
      rethrow; 
    }
  }

  // 2. Delete a specific member
  Future<void> removeMember(String userId) async {
    try {
      await apiService.delete('/priest/$userId');
      debugPrint("Member $userId deleted successfully.");
    } catch (e) {
      debugPrint("Error deleting member: $e");
      rethrow;
    }
  }
  Future<void> changePassword({
  required String currentPassword,
  required String newPassword,
}) async {
  try {
    // Assuming your backend route is /user/change-password
    await apiService.post('/user/me/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  } catch (e) {
    // This will catch 401 (wrong current password) or other server errors
    rethrow;
  }
}
// --- EVENT SERVICE METHODS ---

  /// 1. Fetch Events (GET /event?type=upcoming or GET /event?type=past)
  /// 1. Fetch Events (GET /event?type=upcoming or GET /event?type=past)
Future<List<EventData>> getEvents({String type = 'upcoming'}) async {
  try {
    // Manually append the query parameter to the URL string
    final response = await apiService.get('/event?type=$type');
    
    final List<dynamic> data = response.data;
    return data.map((json) => EventData.fromJson(json)).toList();
  } catch (e) {
    debugPrint("Error fetching events: $e");
    rethrow;
  }
}

  /// 2. Fetch User Registrations (GET /event/my-registrations)
  Future<List<EventData>> getMyRegistrations() async {
    try {
      final response = await apiService.get('/event/my-registrations');
      final List<dynamic> data = response.data;
      
      // Based on your JSON, we map the inner 'event' object and set isRegistered to true
      return data.map((reg) {
        final event = EventData.fromJson(reg['event']);
        event.isRegistered = true; 
        return event;
      }).toList();
    } catch (e) {
      debugPrint("Error fetching registrations: $e");
      rethrow;
    }
  }

  /// 3. Register for Event (POST /event/:eventId/register)
  Future<bool> registerForEvent(String eventId) async {
    try {
      final response = await apiService.post('/event/$eventId/register', {});
      // Return true if status is 200 or 201
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Error registering for event: $e");
      return false;
    }
  }

  /// 4. Create Event (POST /event) - Priest Only
  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    try {
      final response = await apiService.post('/event', eventData);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint("Error creating event: $e");
      rethrow;
    }
  }
  
  /// 5. Delete Event (DELETE /event/:id) - Priest Only
  Future<void> deleteEvent(String eventId) async {
    try {
      await apiService.delete('/event/$eventId');
    } catch (e) {
      debugPrint("Error deleting event: $e");
      rethrow;
    }
  }

/// 6. Unregister from Event (DELETE /event/:eventId/unregister)
  Future<bool> unregisterFromEvent(String eventId) async {
    try {
      final response = await apiService.delete('/event/$eventId/unregister');
      // Return true if status is 200 or 204
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint("Error unregistering from event: $e");
      return false;
    }
  }

  Future<List<dynamic>> getEventAttendees(String eventId) async {
    try {
      // Hits GET /event/:eventId/attendees
      final response = await apiService.get('/event/$eventId/attendees');
      
      // The backend returns a List of registration objects
      if (response.data is List) {
        return response.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching event attendees: $e");
      // Return empty list so the UI doesn't crash
      return [];
    }
  }
}
// Add this inside the AuthService class in auth_service.dart

// --- ADD THIS METHOD ---
  
  /// Fetches the list of participants for a specific event
  

class User {
  final String id, email, role, churchId, name, churchName, location;
  final String? logoUrl,
      gender,
      dob,
      permanentAddress,
      houseNumber,
      residenceType,
      houseName,
      phone;

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

  User copyWith({
    String? name,
    String? gender,
    String? dob,
    String? permanentAddress,
    String? houseNumber,
    String? residenceType,
    String? houseName,
    String? phone,
  }) {
    return User(
      id: id,
      email: email,
      role: role,
      churchId: churchId,
      logoUrl: logoUrl,
      churchName: churchName,
      location: location,
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
    'id': id,
    'email': email,
    'role': role,
    'churchId': churchId,
    'name': name,
    'logoUrl': logoUrl,
    'churchName': churchName,
    'location': location,
    'gender': gender,
    'dob': dob,
    'permanentAddress': permanentAddress,
    'houseNumber': houseNumber,
    'residenceType': residenceType,
    'houseName': houseName,
    'phone': phone,
  };

  factory User.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>? ?? json;
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
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
      phone: json['phone'] ?? profile['phone'],
    );
  }

  bool get isProfileIncomplete =>
      gender == null ||
      residenceType == null ||
      phone == null ||
      phone!.isEmpty;
}
