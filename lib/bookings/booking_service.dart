import '../auth/api_service.dart'; // Import your ApiService file
import '../auth/auth_service.dart';
import 'booking_model.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/models/paginated_response.dart';

class BookingService {
  // GET: Fetch all bookings using your Dio-based apiService
  Future<PaginatedResponse<BookingData>> fetchBookings({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final isOfficial = AuthService().currentUser?.isOfficial ?? false;
      final endpoint = isOfficial ? '/booking/church' : '/booking';
      final response = await apiService.get(
        '$endpoint?page=$page&limit=$limit',
      );

      // Safety check: ensure we have data
      if (response.data == null) {
        return PaginatedResponse(
          data: [],
          meta: PaginationMeta(page: page, limit: limit, hasMore: false),
        );
      }

      final Map<String, dynamic> decodedData =
          response.data is String ? json.decode(response.data) : response.data;

      final List<dynamic> bookingsList = decodedData['data'] ?? [];
      final metaJson = decodedData['meta'] ?? {};
      final meta = PaginationMeta.fromJson(metaJson);

      final data =
          bookingsList.map((json) => BookingData.fromJson(json)).toList();

      return PaginatedResponse(data: data, meta: meta);
    } catch (e) {
      // Re-throw so the FutureBuilder shows the error
      throw Exception('Failed to load bookings: $e');
    }
  }

  // POST: Create a new booking
  Future<BookingData> createBooking(Map<String, dynamic> bookingData) async {
    try {
      // Note: Most REST APIs use the base endpoint for POSTing new resources
      // Correct
      final response = await apiService.post('/booking', bookingData);
      final decodedData =
          response.data is String ? json.decode(response.data) : response.data;
      return BookingData.fromJson(decodedData);
    } catch (e) {
      debugPrint('Create Booking Error: $e');
      throw Exception('Failed to create booking');
    }
  }

  // PATCH: Update booking status (Priest only)
  Future<void> updateBookingStatus(
    String id,
    String status, {
    String? reason,
  }) async {
    try {
      final Map<String, dynamic> body = {"status": status};
      if (reason != null && reason.trim().isNotEmpty) {
        body["reason"] = reason.trim();
      }
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

  // DELETE: Cancel a booking request
  Future<void> cancelBooking(String bookingId) async {
    try {
      await apiService.delete('/booking/$bookingId');
    } catch (e) {
      debugPrint('Cancel Booking Error: $e');
      throw Exception('Failed to cancel booking');
    }
  }

  Future<List<BookingData>> fetchCalendarEvents(int month, int year) async {
    try {
      final response = await apiService.get(
        '/booking/calendar',
        params: {'month': month, 'year': year},
      );

      final List<dynamic> eventsJson = response.data['events'] ?? [];
      return eventsJson.map((json) => BookingData.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Calendar Fetch Error: $e');
      return [];
    }
  }
}
