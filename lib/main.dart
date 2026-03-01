import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme_provider.dart';
import 'core/locale_provider.dart';
import 'core/routes.dart';
import 'app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:shared_preferences/shared_preferences.dart';
// IMPORTANT: Global navigator key for navigation
import 'core/navigator_key.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 2. Handle Notification Clicks when app is TERMINATED (Closed)
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    final String? id = initialMessage.data['announcementId'];
    if (id != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        navigatorKey.currentState?.pushNamed(
          Routes.announcementDetail,
          arguments: id,
        );
      });
    }
  }

  // 3. Foreground Notification Listener
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    // Added 'async' here
    final notification = message.notification;
    final data = message.data;

    // --- SELF-NOTIFICATION CHECK ---
    final String? senderId = message.data['senderId'];

    // Fetch from Local Storage
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? localUserId = prefs.getString('userId');

    if (senderId != null && localUserId != null && senderId == localUserId) {
      debugPrint("Self-notification blocked.");
      return;
    }
    // -------------------------------

    if (notification != null) {
      late OverlaySupportEntry notificationEntry;
      void navigateToDetail() {
        final String? id = data['announcementId'];
        if (id != null) {
          notificationEntry.dismiss();
          navigatorKey.currentState?.pushNamed(
            Routes.announcementDetail,
            arguments: id,
          );
        }
      }

      notificationEntry = showSimpleNotification(
        Text(
          notification.title ?? "New Announcement",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          notification.body ?? "",
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        trailing: TextButton(
          onPressed: navigateToDetail,
          style: TextButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            "VIEW",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        background: const Color(0xFF5D3A99),
        duration: const Duration(seconds: 6),
      );
    }
  });

  // 4. Background State: Handle notification clicks when app is MINIMIZED
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final String? id = message.data['announcementId'];
    if (id != null) {
      navigatorKey.currentState?.pushNamed(
        Routes.announcementDetail,
        arguments: id,
      );
    } else {
      navigatorKey.currentState?.pushNamed(Routes.announcements);
    }
  });

  // 5. Load Environment variables
  await dotenv.load(fileName: ".env");

  runApp(
    OverlaySupport.global(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => AuthService()),
        ],
        child: const SacredSpaceApp(initialRoute: Routes.splash),
      ),
    ),
  );
}
