import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../auth/api_service.dart';
import 'member_model.dart';
import '../core/models/paginated_response.dart';

class MemberService {
  // GET: Fetch members using standard paginated structure
  Future<PaginatedResponse<Member>> fetchMembers({
    int page = 1,
    int limit = 10,
    String? searchQuery,
  }) async {
    try {
      final queryParam = searchQuery != null && searchQuery.trim().isNotEmpty
          ? '&search=${Uri.encodeComponent(searchQuery.trim())}'
          : '';

      final response = await apiService.get(
        '/priest/users?page=$page&limit=$limit$queryParam',
      );

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

      final data = list.map((json) => Member.fromJson(json)).toList();

      return PaginatedResponse(data: data, meta: meta);
    } catch (e) {
      debugPrint("Error fetching members: $e");
      rethrow;
    }
  }

  // DELETE: Remove a member
  Future<void> removeMember(String memberId) async {
    try {
      await apiService.delete('/priest/$memberId');
    } catch (e) {
      debugPrint("Error removing member: $e");
      rethrow;
    }
  }
}
