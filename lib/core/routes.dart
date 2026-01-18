import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../dashboard/member_dashboard.dart';
import '../dashboard/profile_screen.dart';
import '../auth/signup_screen.dart';
import '../announcements/announcements_screen.dart';

// import '../dashboard/official_dashboard.dart';
// import '../dashboard/priest_dashboard.dart';
// import '../dashboard/admin_dashboard.dart';

class Routes {
  static const login = '/';
  static const member = '/member';
  static const official = '/official';
  static const priest = '/priest';
  static const admin = '/admin';
  static const announcements = '/announcements';
  static const profile = '/profile'; // <-- new
  static const signup = '/signup';

  static Map<String, WidgetBuilder> get map => {
        login: (_) => const LoginScreen(),
        member: (_) => const MemberDashboard(),
        announcements: (_) => const AnnouncementsScreen(),
        profile: (_) => const ProfileScreen(),
        signup: (_)=> const SignupScreen(), // <-- new

        // official: (_) => const OfficialDashboard(),
        // priest: (_) => const PriestDashboard(),
        // admin: (_) => const AdminDashboard(),
      };
}
