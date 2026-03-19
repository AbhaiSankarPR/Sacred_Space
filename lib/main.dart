import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme_provider.dart';
import 'core/locale_provider.dart';
import 'core/routes.dart';
import 'app.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/navigator_key.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

// 1. UPDATED NAVIGATION HANDLER
void handleNotificationNavigation(Map<String, dynamic> data) {
  final String? type = data['type'];
  final String? id = data['id'] ?? data['announcementId'] ?? data['eventId'] ?? data['bookingId'];

  switch (type) {
    case "ANNOUNCEMENT":
      if (id != null) {
        navigatorKey.currentState?.pushNamed(Routes.announcementDetail, arguments: id);
      } else {
        navigatorKey.currentState?.pushNamed(Routes.announcements);
      }
      break;

    case "NEW_EVENT":
      navigatorKey.currentState?.pushNamed(Routes.events);
      break;

    case "NEW_BOOKING_REQUEST":
      // Priest navigates here to approve/reject
      navigatorKey.currentState?.pushNamed(Routes.bookings);
      break;

    case "BOOKING_STATUS_UPDATE":
      // Member navigates here to see confirmation
      navigatorKey.currentState?.pushNamed(Routes.bookings);
      break;

    default:
      debugPrint("Unknown notification type: $type");
      // Fallback: send them to home or announcements
      navigatorKey.currentState?.pushNamed(Routes.announcements);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 2. Terminated State: Handle notification clicks
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    Future.delayed(const Duration(milliseconds: 1000), () {
      handleNotificationNavigation(initialMessage.data);
    });
  }

  // 3. Foreground State: Custom UI Popups
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    // Self-notification check
    final String? senderId = data['senderId'];
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? localUserId = prefs.getString('userId');

    if (senderId != null && localUserId != null && senderId == localUserId) {
      return;
    }

    if (notification != null) {
      late OverlaySupportEntry notificationEntry;

      Color background = const Color(0xFF5D3A99); // Default Purple
      if (data['type'] == "BOOKING_STATUS_UPDATE") background = Colors.green;
      if (data['type'] == "NEW_BOOKING_REQUEST") background = Colors.orange[800]!;

      notificationEntry = showSimpleNotification(
        Text(
          notification.title ?? "Sacred Space Update",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Text(
          notification.body ?? "",
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        trailing: TextButton(
          onPressed: () {
            notificationEntry.dismiss();
            handleNotificationNavigation(data);
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            foregroundColor: Colors.white,
          ),
          child: const Text("VIEW", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        background: background,
        duration: const Duration(seconds: 6),
      );
    }
  });

  // 4. Background State: Handle clicks when app is Minimized
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    handleNotificationNavigation(message.data);
  });

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