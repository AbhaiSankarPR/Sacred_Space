import 'package:flutter/material.dart';
// Core Screens
import '../screens/splash_screen.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../screens/complete_details_screen.dart';
// Dashboard & Profile
import '../dashboard/dashboard_screen.dart';
import '../dashboard/profile_screen.dart';
// import '../dashboard/personal_info_screen.dart';
// Priest-Specific Features
import '../screens/priest/member_directory_screen.dart'; // Create these files
import '../gallery/priest/gallery_management_screen.dart';
// Shared Feature Screens
import '../announcements/announcements_screen.dart';
import '../bookings/bookings_screen.dart';
import '../bookings/newbooking_screen.dart';
import '../emergency/emergency_alerts_screen.dart';
import '../events/events_screen.dart';
import '../gallery/member/gallery_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/about_screen.dart';
import '../settings/support_screen.dart';
import '../screens/PrivacyPolicyScreen.dart';

class Routes {
  // Authentication & Onboarding
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const completeDetails = '/complete-details';

  // Role-Based Dashboards (Both point to Dynamic Dashboard)
  static const member = '/member';
  static const priest = '/priest';

  // Shared Features
  static const announcements = '/announcements';
  static const profile = '/profile';
  static const personalInfo = '/personal-info';
  static const bookings = '/bookings';
  static const newBooking = '/new-booking';
  static const emergency = '/emergency';
  static const events = '/events';
  static const gallery = '/gallery';

  // Priest-Exclusive Features
  static const memberDirectory = '/priest/member-directory';
  static const galleryAdmin = '/priest/gallery-admin';

  // Static & Support Pages
  static const settings = '/settings';
  static const about = '/about';
  static const support = '/support';
  static const privacyPolicy = '/privacy-policy';

  static Map<String, WidgetBuilder> get map => {
        // Auth & Splash
        splash: (_) => const SplashScreen(),
        login: (_) => const LoginScreen(),
        signup: (_) => const SignupScreen(),
        completeDetails: (_) => const CompleteDetailsScreen(),

        // Unified Dashboard (Logic inside handles role differences)
        member: (_) => const DashboardScreen(),
        priest: (_) => const DashboardScreen(),

        // Profile & Personal Data
        profile: (_) => const ProfileScreen(),
        // personalInfo: (_) => const PersonalInfoScreen(),

        // Shared Functional Routes
        announcements: (_) => const AnnouncementsScreen(),
        bookings: (_) => const BookingsScreen(),
        newBooking: (_) => const NewBookingScreen(),
        emergency: (_) => const EmergencyAlertsScreen(),
        events: (_) => const EventsScreen(),
        gallery: (_) => const GalleryScreen(),

        // Priest-Only Routes
        memberDirectory: (_) => const MemberDirectoryScreen(),
        galleryAdmin: (_) => const GalleryManagementScreen(),

        // Info & Settings
        settings: (_) => const SettingsScreen(),
        about: (_) => const AboutScreen(),
        support: (_) => const SupportScreen(),
        privacyPolicy: (_) => const PrivacyPolicyScreen(),
      };
}