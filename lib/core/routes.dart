import 'package:flutter/material.dart';
import 'package:sacred_space/bookings/newbooking_screen.dart';

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
import '../events/events_screen.dart';
import '../gallery/gallery_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/about_screen.dart';

class Routes {
  static const login = '/';
  static const signup = '/signup';
  static const member = '/member';
  static const announcements = '/announcements';
  static const profile = '/profile';
  static const bookings = '/bookings';
  static const emergency = '/emergency';
  static const newBooking = '/new-booking';
  static const events = '/events';
  static const gallery = '/gallery';
  static const settings = '/settings';
  static const about = '/about';
  static Map<String, WidgetBuilder> get map => {
    login: (_) => const LoginScreen(),
    signup: (_) => const SignupScreen(),
    member: (_) => const MemberDashboard(),
    events: (_) => const EventsScreen(), 
    bookings: (_) => const BookingsScreen(),
    newBooking: (_) => const NewBookingScreen(),
    announcements: (_) => AnnouncementsScreen(),
    profile: (_) => ProfileScreen(),
    emergency: (_) => const EmergencyAlertsScreen(),
    about: (_) => const AboutScreen(),
    gallery: (_) => const GalleryScreen(),
    settings: (_) => const SettingsScreen(),
  };
}
