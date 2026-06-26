import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../auth/api_service.dart';
import '../core/models/paginated_response.dart';
import 'signup_request_model.dart';

class SignupRequestService {
  Future<PaginatedResponse<SignupRequest>> getPendingSignups({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await apiService.get('/priest/pending-users?page=$page&limit=$limit');
      if (response.data == null) {
        return PaginatedResponse(
          data: [],
          meta: PaginationMeta(page: page, limit: limit, hasMore: false),
        );
      }

      final Map<String, dynamic> decodedData = response.data is String
          ? json.decode(response.data)
          : response.data;

      final List<dynamic> list = decodedData['data'] ?? [];
      final metaJson = decodedData['meta'] ?? {};
      final meta = PaginationMeta.fromJson(metaJson);

      final data = list.map((json) => SignupRequest.fromJson(json)).toList();
      return PaginatedResponse(data: data, meta: meta);
    } catch (e) {
      debugPrint("Error fetching pending signups: $e");
      rethrow;
    }
  }

  Future<void> handleSignupRequest(String userId, String action) async {
    try {
      if (action == 'approve') {
        await apiService.put('/priest/users/$userId/approve', {});
      } else {
        await apiService.put('/priest/users/$userId/reject', {});
      }
      debugPrint("Signup request $action for $userId successful.");
    } catch (e) {
      debugPrint("Error handling signup request: $e");
      rethrow;
    }
  }
}
