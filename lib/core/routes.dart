import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../screens/complete_details_screen.dart'; // Ensure this import exists
import '../dashboard/member_dashboard.dart';
import '../dashboard/profile_screen.dart';
import '../announcements/announcements_screen.dart';
import '../bookings/bookings_screen.dart';
import '../bookings/newbooking_screen.dart';
import '../emergency/emergency_alerts_screen.dart';
import '../events/events_screen.dart';
import '../gallery/gallery_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/about_screen.dart';
import '../settings/support_screen.dart';

class Routes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const completeDetails = '/complete-details'; // ADDED THIS
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
  static const support = '/support';

  static Map<String, WidgetBuilder> get map => {
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    signup: (_) => const SignupScreen(),
    completeDetails: (_) => const CompleteDetailsScreen(), // ADDED THIS
    member: (_) => const MemberDashboard(),
    events: (_) => const EventsScreen(), 
    bookings: (_) => const BookingsScreen(),
    newBooking: (_) => const NewBookingScreen(),
    announcements: (_) => const AnnouncementsScreen(), 
    profile: (_) => const ProfileScreen(), 
    emergency: (_) => const EmergencyAlertsScreen(),
    about: (_) => const AboutScreen(),
    gallery: (_) => const GalleryScreen(),
    settings: (_) => const SettingsScreen(),
    support: (_) => const SupportScreen(),
  };
}