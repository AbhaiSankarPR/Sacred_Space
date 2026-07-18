import 'package:flutter/material.dart';
import 'package:sacred_space/announcements/announcement_detail_screen.dart';
import 'package:sacred_space/bookings/parish_calendar_screen.dart';
// Core Screens
import '../screens/splash_screen.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../screens/complete_details_screen.dart';
import '../settings/changePasswordScreen.dart';
import '../settings/forgot_password_screen.dart';
// Dashboard & Profile
import '../dashboard/dashboard_screen.dart';
import '../dashboard/profile_screen.dart';
// import '../dashboard/personal_info_screen.dart';
// Priest-Specific Features
import '../members/member_directory_screen.dart';
import '../signup_requests/signup_requests_screen.dart';
import '../gallery/priest/gallery_management_screen.dart';
import '../transactions/transactions_screen.dart';
import '../transactions/add_transaction_screen.dart';
// Shared Feature Screens
import '../announcements/announcements_screen.dart';
import '../bookings/bookings_screen.dart';
import '../bookings/newbooking_screen.dart';
import '../events/events_screen.dart';
import '../events/new_event_screen.dart';
import '../gallery/member/gallery_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/about_screen.dart';
import '../settings/support_screen.dart';
import '../screens/PrivacyPolicyScreen.dart';
import '../screens/TermsOfServiceScreen.dart';
import '../screens/editProfile.dart';
import '../settings/family_connections_screen.dart';
import '../screens/family_members_screen.dart';
import '../certificate/certificate_screen.dart';
import '../complaints/complaints_screen.dart';
import '../complaints/new_complaint_screen.dart';
import '../complaints/complaint_detail_screen.dart';

class Routes {
  // Authentication & Onboarding
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const completeDetails = '/complete-details';
  static const String changePassword = '/change-password';
  static const String forgotPassword = '/forgot-password';
  // Role-Based Dashboards (Both point to Dynamic Dashboard)
  static const member = '/member';
  static const priest = '/priest';

  // Shared Features
  static const announcements = '/announcements';
  static const profile = '/profile';
  static const personalInfo = '/personal-info';
  static const bookings = '/bookings';
  static const newBooking = '/new-booking';
  static const events = '/events';
  static const newEvent = '/events/new';
  static const gallery = '/gallery';
  static const String editProfile = '/edit-profile';
  static const complaints = '/complaints';
  static const newComplaint = '/complaints/new';
  static const complaintDetail = '/complaints/detail';

  // Priest/Official-Exclusive Features
  static const memberDirectory = '/priest/member-directory';
  static const signupRequests = '/priest/signup-requests';
  static const galleryAdmin = '/priest/gallery-admin';
  static const transactions = '/transactions';
  static const addTransaction = '/transactions/add';

  // Static & Support Pages
  static const settings = '/settings';
  static const about = '/about';
  static const support = '/support';
  static const privacyPolicy = '/privacy-policy';
  static const termsOfService = '/terms-of-service';
  static const familyConnections = '/family-connections';
  static const familyMembers = '/family-members';
  static const certificate = '/certificate';

  static const announcementDetail = '/announcementdetail';

  static const parishCalendar = '/parish-calendar';

  static Map<String, WidgetBuilder> get map => {
    // Auth & Splash
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    signup: (_) => const SignupScreen(),
    completeDetails: (_) => const CompleteDetailsScreen(),
    changePassword: (context) => const ChangePasswordScreen(),
    forgotPassword: (_) => const ForgotPasswordScreen(),
    // Unified Dashboard (Logic inside handles role differences)
    member: (_) => const DashboardScreen(),
    priest: (_) => const DashboardScreen(),
    '/president': (_) => const DashboardScreen(),
    '/secretary': (_) => const DashboardScreen(),
    '/treasurer': (_) => const DashboardScreen(),
    '/MEMBER': (_) => const DashboardScreen(),
    '/PRIEST': (_) => const DashboardScreen(),
    '/PRESIDENT': (_) => const DashboardScreen(),
    '/SECRETARY': (_) => const DashboardScreen(),
    '/TREASURER': (_) => const DashboardScreen(),

    // Profile & Personal Data
    profile: (_) => const ProfileScreen(),
    editProfile: (_) => const EditProfileScreen(),
    // personalInfo: (_) => const PersonalInfoScreen(),

    // Shared Functional Routes
    announcements: (_) => const AnnouncementsScreen(),
    bookings: (_) => const BookingsScreen(),
    newBooking: (_) => const NewBookingScreen(),
    events: (_) => const EventsScreen(),
    newEvent: (_) => const NewEventScreen(),
    gallery: (_) => const GalleryScreen(),
    complaints: (_) => const ComplaintsScreen(),
    newComplaint: (_) => const NewComplaintScreen(),
    complaintDetail: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as String;
      return ComplaintDetailScreen(complaintId: args);
    },

    // Priest-Only Routes
    memberDirectory: (_) => const MemberDirectoryScreen(),
    signupRequests: (_) => const SignupRequestsScreen(),
    galleryAdmin: (_) => const GalleryManagementScreen(),
    transactions: (_) => const TransactionsScreen(),
    addTransaction: (_) => const AddTransactionScreen(),

    // Info & Settings
    settings: (_) => const SettingsScreen(),
    about: (_) => const AboutScreen(),
    support: (_) => const SupportScreen(),
    privacyPolicy: (_) => const PrivacyPolicyScreen(),
    termsOfService: (_) => const TermsOfServiceScreen(),
    familyConnections: (_) => const FamilyConnectionsScreen(),
    familyMembers: (_) => const FamilyMembersScreen(),
    parishCalendar: (_) => const ParishCalendarScreen(),
    certificate: (_) => const CertificateScreen(),
  };
}
