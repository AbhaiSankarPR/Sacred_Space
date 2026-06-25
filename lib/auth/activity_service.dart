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
  Future<void>? _activeSyncFuture;

  ActivityService._internal() {
    _startPeriodicSync();
  }

  /// Logs a user activity of [type] ('LOGIN' or 'LOGOUT').
  /// The activity is queued locally only if the network response is negative.
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

      final queueKey = 'activity_queue_$userId';
      final queueJson = prefs.getStringList(queueKey) ?? [];

      if (queueJson.isNotEmpty) {
        // If there is already an unsynced queue, append to it to maintain correct chronological order
        final newLog = jsonEncode({
          'type': type,
          'timestamp': timestampStr,
        });
        queueJson.add(newLog);
        await prefs.setStringList(queueKey, queueJson);
        debugPrint("ActivityService: Queue is not empty. Appending '$type' and triggering sync.");
        await syncQueue();
      } else {
        // Queue is empty, attempt immediate direct send
        debugPrint("ActivityService: Queue is empty. Attempting immediate log for '$type'...");
        bool success = false;
        try {
          final response = await apiService.post('/user/me/activity', {
            'type': type,
            'timestamp': timestampStr,
          });

          if (response.statusCode != null &&
              response.statusCode! >= 200 &&
              response.statusCode! < 300) {
            success = true;
            debugPrint("ActivityService: Successfully logged '$type' directly to backend.");
          } else {
            debugPrint("ActivityService: Server returned negative status (${response.statusCode}) for '$type'.");
          }
        } catch (e) {
          debugPrint("ActivityService: Network error logging '$type' directly: $e");
        }

        if (!success) {
          // Store in queue only if response is negative/failed
          final newLog = jsonEncode({
            'type': type,
            'timestamp': timestampStr,
          });
          queueJson.add(newLog);
          await prefs.setStringList(queueKey, queueJson);
          debugPrint("ActivityService: Queued failed '$type' activity.");
        }
      }
    } catch (e) {
      debugPrint("ActivityService: Error in logActivity: $e");
    }
  }

  /// Synchronizes the user's queued activity logs with the backend.
  /// Sends them chronologically, halting on first failure to keep correct order.
  Future<void> syncQueue() async {
    if (_isSyncing) {
      debugPrint("ActivityService: Sync already in progress. Waiting for it to finish.");
      await _activeSyncFuture;
      return;
    }
    _isSyncing = true;
    final completer = Completer<void>();
    _activeSyncFuture = completer.future;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) {
        debugPrint("ActivityService: Cannot sync queue. No logged-in user.");
        completer.complete();
        return;
      }

      final queueKey = 'activity_queue_$userId';
      List<String> queueJson = prefs.getStringList(queueKey) ?? [];
      if (queueJson.isEmpty) {
        completer.complete();
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
      completer.complete();
    } catch (e) {
      debugPrint("ActivityService: Error in syncQueue: $e");
      completer.completeError(e);
    } finally {
      _isSyncing = false;
      _activeSyncFuture = null;
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
