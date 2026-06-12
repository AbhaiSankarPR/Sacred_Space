import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;

  Timer? _syncTimer;
  bool _isSyncing = false;

  ActivityService._internal() {
    _startPeriodicSync();
  }

  /// Logs a user activity of [type] ('LOGIN' or 'LOGOUT').
  /// The activity is queued locally and then a sync attempt is triggered.
  Future<void> logActivity(String type, {DateTime? timestamp}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) {
        debugPrint("ActivityService: No logged-in user. Skipping activity log.");
        return;
      }

      final now = timestamp ?? DateTime.now();
      final timestampStr = now.toUtc().toIso8601String();

      // Throttling: Skip logging if the exact same activity occurred in the last 3 seconds
      final lastType = prefs.getString('last_activity_type');
      final lastTimeStr = prefs.getString('last_activity_time');
      if (lastType == type && lastTimeStr != null) {
        final lastTime = DateTime.tryParse(lastTimeStr);
        if (lastTime != null && now.difference(lastTime).inSeconds < 3) {
          debugPrint("ActivityService: Throttling duplicate '$type' log.");
          return;
        }
      }

      // Save as the last recorded activity
      await prefs.setString('last_activity_type', type);
      await prefs.setString('last_activity_time', timestampStr);

      // Add activity to user-specific queue
      final queueKey = 'activity_queue_$userId';
      final queueJson = prefs.getStringList(queueKey) ?? [];

      final newLog = jsonEncode({
        'type': type,
        'timestamp': timestampStr,
      });
      queueJson.add(newLog);
      await prefs.setStringList(queueKey, queueJson);

      debugPrint("ActivityService: Queued '$type' at $timestampStr for user: $userId");

      // Attempt to sync immediately
      syncQueue();
    } catch (e) {
      debugPrint("ActivityService: Error in logActivity: $e");
    }
  }

  /// Synchronizes the user's queued activity logs with the backend.
  /// Sends them chronologically, halting on first failure to keep correct order.
  Future<void> syncQueue() async {
    if (_isSyncing) {
      debugPrint("ActivityService: Sync already in progress. Skipping.");
      return;
    }
    _isSyncing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) {
        debugPrint("ActivityService: Cannot sync queue. No logged-in user.");
        return;
      }

      final queueKey = 'activity_queue_$userId';
      List<String> queueJson = prefs.getStringList(queueKey) ?? [];
      if (queueJson.isEmpty) {
        return;
      }

      debugPrint("ActivityService: Syncing ${queueJson.length} queued activities...");
      int successCount = 0;

      for (int i = 0; i < queueJson.length; i++) {
        final itemMap = jsonDecode(queueJson[i]) as Map<String, dynamic>;
        final type = itemMap['type'];
        final timestamp = itemMap['timestamp'];

        try {
          // Send to the backend endpoint
          final response = await apiService.post('/user/me/activity', {
            'type': type,
            'timestamp': timestamp,
          });

          // Check if response status indicates success (e.g. 200 or 204)
          if (response.statusCode != null &&
              response.statusCode! >= 200 &&
              response.statusCode! < 300) {
            successCount++;
          } else {
            debugPrint("ActivityService: Server error (${response.statusCode}) logging activity: ${response.data}");
            break; // Stop and retry later
          }
        } catch (e) {
          debugPrint("ActivityService: Network error logging activity: $e");
          break; // Stop and retry later
        }
      }

      if (successCount > 0) {
        // Fetch queue again to preserve any items added while syncing
        queueJson = prefs.getStringList(queueKey) ?? [];
        if (successCount >= queueJson.length) {
          await prefs.remove(queueKey);
        } else {
          await prefs.setStringList(queueKey, queueJson.sublist(successCount));
        }
        debugPrint("ActivityService: Successfully synced $successCount items.");
      }
    } catch (e) {
      debugPrint("ActivityService: Error in syncQueue: $e");
    } finally {
      _isSyncing = false;
    }
  }

  /// Sets up a periodic sync checker every 30 seconds
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      syncQueue();
    });
  }

  /// Stops the periodic timer (useful if needed for cleanup)
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}
