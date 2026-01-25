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
  static Map<String, WidgetBuilder> get map => {
        login: (_) => const LoginScreen(),
        signup: (_) => const SignupScreen(),
        
        member: (_) => const MemberDashboard(),
        events: (_) => const EventsScreen(), // Add this
        // ✅ FIXED: BookingsScreen handles user internally now too
        bookings: (_) => const BookingsScreen(),
newBooking: (_) => const NewBookingScreen(),
        // ⚠️ CAUTION: These still rely on 'currentUser!'. 
        // If you haven't updated these screens yet, keep them like this.
        // If you update them later, remove the arguments here.
        announcements: (_) => AnnouncementsScreen(user: AuthService().currentUser!),
        profile: (_) => ProfileScreen(user: AuthService().currentUser!),
emergency: (_) => const EmergencyAlertsScreen(),
gallery: (_) => const GalleryScreen(),
        settings: (_) => const SettingsScreen(),
      };
}