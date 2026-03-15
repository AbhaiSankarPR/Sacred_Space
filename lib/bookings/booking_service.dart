import 'package:dio/dio.dart';
import '../auth/api_service.dart'; // Import your ApiService file
import 'booking_model.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class BookingService {
  // GET: Fetch all bookings using your Dio-based apiService
  Future<List<BookingData>> fetchBookings() async {
    try {
      final response = await apiService.get('/booking');

      // Safety check: ensure we have data
      if (response.data == null) return [];

      // Access the 'data' list from the JSON response
      final Map<String, dynamic> responseBody =
          response.data is String ? json.decode(response.data) : response.data;

      final List<dynamic> bookingsList = responseBody['data'] ?? [];

      return bookingsList.map((json) => BookingData.fromJson(json)).toList();
    } catch (e) {
      // Re-throw so the FutureBuilder shows the error
      throw Exception('Failed to load bookings: $e');
    }
  }

  // POST: Create a new booking
  Future<void> createBooking(Map<String, dynamic> bookingData) async {
    try {
      // Note: Most REST APIs use the base endpoint for POSTing new resources
      // Correct
      await apiService.post('/booking', bookingData);
    } catch (e) {
      debugPrint('Create Booking Error: $e');
      throw Exception('Failed to create booking');
    }
  }

  // PATCH: Update booking status (Priest only)
  Future<void> updateBookingStatus(String id, String status, {String? reason}) async {
  try {
    final Map<String, dynamic> body = {"status": status};
    if (reason != null) body["reason"] = reason;
    if (reason != null && reason.isNotEmpty) {
      body["reason"] = reason;}
    // Using the positional argument format we corrected earlier
    await apiService.patch('/booking/$id', body); 
  } catch (e) {
    throw Exception('Failed to update booking: $e');
  }
}
  Future<List<BookingData>> checkConflicts(String bookingId) async {
  try {
    final response = await apiService.get('/booking/$bookingId/conflicts');
    final List<dynamic> conflictsJson = response.data['conflicts'] ?? [];
    return conflictsJson.map((json) => BookingData.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}
  Future<List<BookingData>> fetchCalendarEvents(int month, int year) async {
  try {
    final response = await apiService.get('/booking/calendar', params: {
      'month': month,
      'year': year,
    });
    
    final List<dynamic> eventsJson = response.data['events'] ?? [];
    return eventsJson.map((json) => BookingData.fromJson(json)).toList();
  } catch (e) {
    debugPrint('Calendar Fetch Error: $e');
    return [];
  }
}
}
