import 'dart:convert';
import 'package:dio/dio.dart';
import '../auth/api_service.dart';
import 'complaint_model.dart';
import 'package:flutter/foundation.dart';
import '../core/models/paginated_response.dart';

class ComplaintService {
  Future<PaginatedResponse<Complaint>> fetchComplaints({
    required bool isPriest,
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final String basePath = isPriest ? '/priest/complaints' : '/user/complaints';
      final String path = '$basePath?page=$page&limit=$limit';
      final Map<String, dynamic> params = {};
      if (status != null && status != 'All' && status.isNotEmpty) {
        params['status'] = status.toUpperCase();
      }
      
      final response = await apiService.get(path, params: params);
      
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
      
      final data = list.map((json) => Complaint.fromJson(json)).toList();
      return PaginatedResponse(data: data, meta: meta);
    } catch (e) {
      debugPrint('Fetch Complaints Error: $e');
      throw Exception('Failed to load complaints: $e');
    }
  }

  Future<Complaint> createComplaint(String title, String description) async {
    try {
      final response = await apiService.post('/user/complaints', {
        'title': title,
        'description': description,
      });
      return Complaint.fromJson(response.data);
    } catch (e) {
      debugPrint('Create Complaint Error: $e');
      throw Exception('Failed to submit complaint');
    }
  }

  Future<Complaint> fetchComplaintDetail(String id, {required bool isPriest}) async {
    try {
      final String path = isPriest ? '/priest/complaints/$id' : '/user/complaints/$id';
      final response = await apiService.get(path);
      return Complaint.fromJson(response.data);
    } catch (e) {
      debugPrint('Fetch Complaint Detail Error: $e');
      throw Exception('Failed to load complaint details');
    }
  }

  Future<ComplaintReply> sendReply(String id, String message, {required bool isPriest}) async {
    try {
      final String path = isPriest ? '/priest/complaints/$id/reply' : '/user/complaints/$id/reply';
      final response = await apiService.post(path, {
        'message': message,
      });
      return ComplaintReply.fromJson(response.data);
    } catch (e) {
      debugPrint('Send Reply Error: $e');
      throw Exception('Failed to send reply');
    }
  }

  Future<void> closeComplaint(String id) async {
    try {
      await apiService.patch('/user/complaints/$id/close', {});
    } catch (e) {
      debugPrint('Close Complaint Error: $e');
      throw Exception('Failed to close complaint');
    }
  }

  Future<void> resolveComplaint(String id) async {
    try {
      await apiService.patch('/priest/complaints/$id/resolve', {});
    } catch (e) {
      debugPrint('Resolve Complaint Error: $e');
      throw Exception('Failed to resolve complaint');
    }
  }
}
