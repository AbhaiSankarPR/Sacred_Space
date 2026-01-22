import 'package:flutter/material.dart';

// Auth
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../auth/auth_service.dart';

// Dashboards
import '../dashboard/member_dashboard.dart';
import '../dashboard/profile_screen.dart';

// Features
import '../announcements/announcements_screen.dart';
import '../bookings/bookings_screen.dart';
import '../emergency/emergency_alerts_screen.dart';

class Routes {
  static const login = '/';
  static const signup = '/signup';
  static const member = '/member';
  static const announcements = '/announcements';
  static const profile = '/profile';
  static const bookings = '/bookings';
  static const emergency = '/emergency';

  static Map<String, WidgetBuilder> get map => {
        login: (_) => const LoginScreen(),
        signup: (_) => const SignupScreen(),
        member: (_) => MemberDashboard(user: AuthService().currentUser!),
        announcements: (_) => AnnouncementsScreen(user: AuthService().currentUser!),
        profile: (_) => ProfileScreen(user: AuthService().currentUser!),
        bookings: (_) => BookingsScreen(user: AuthService().currentUser!),
        emergency: (_) => EmergencyAlertsScreen(user: AuthService().currentUser!),
      };
}
