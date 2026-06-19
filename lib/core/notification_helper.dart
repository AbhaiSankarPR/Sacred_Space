import 'dart:async';
import 'package:flutter/foundation.dart';
import 'navigator_key.dart';
import 'routes.dart';

Map<String, dynamic>? pendingNotificationData;

final StreamController<Map<String, dynamic>> notificationStreamController =
    StreamController<Map<String, dynamic>>.broadcast();

void handleNotificationNavigation(Map<String, dynamic> data) {
  final String? type = data['type'];
  final String? id =
      data['id'] ??
      data['complaintId'] ??
      data['announcementId'] ??
      data['eventId'] ??
      data['bookingId'] ??
      data['requestId'] ??
      data['userId'];

  String? targetRoute;
  Object? arguments;

  switch (type) {
    case "COMPLAINT":
      if (id != null) {
        targetRoute = Routes.complaintDetail;
        arguments = id;
      } else {
        targetRoute = Routes.complaints;
      }
      break;

    case "ANNOUNCEMENT":
      if (id != null) {
        targetRoute = Routes.announcementDetail;
        arguments = id;
      } else {
        targetRoute = Routes.announcements;
      }
      break;

    case "NEW_EVENT":
      targetRoute = Routes.events;
      break;

    case "NEW_BOOKING_REQUEST":
    case "BOOKING_STATUS_UPDATE":
      targetRoute = Routes.bookings;
      break;

    case "NEW_USER_REQUEST":
      targetRoute = Routes.signupRequests;
      break;

    case "NEW_CERTIFICATE_REQUEST":
    case "CERTIFICATE_REJECTED":
    case "CERTIFICATE_APPROVED":
      targetRoute = Routes.certificate;
      break;

    case "FAMILY_REQUEST":
    case "FAMILY_CONNECTION_REQUEST":
    case "NEW_FAMILY_REQUEST":
    case "FAMILY_CONNECTION":
      targetRoute = Routes.familyConnections;
      break;
  }

  if (targetRoute != null) {
    debugPrint("Navigating to notification route: $targetRoute with args: $arguments");
    // Pop all routes until the first (Dashboard) to clean up the stack
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    // Push the target route
    navigatorKey.currentState?.pushNamed(targetRoute, arguments: arguments);
  } else {
    debugPrint("Unhandled or unknown notification type: $type");
    // Default fallback: send to announcements
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    navigatorKey.currentState?.pushNamed(Routes.announcements);
  }
}
