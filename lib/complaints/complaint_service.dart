import 'package:dio/dio.dart';
import '../auth/api_service.dart';
import 'complaint_model.dart';
import 'package:flutter/foundation.dart';

class ComplaintService {
  Future<List<Complaint>> fetchComplaints({required bool isPriest, String? status}) async {
    try {
      final String path = isPriest ? '/priest/complaints' : '/user/complaints';
      final Map<String, dynamic> params = {};
      if (status != null && status != 'All' && status.isNotEmpty) {
        params['status'] = status.toUpperCase();
      }
      
      final response = await apiService.get(path, params: params);
      
      if (response.data == null) return [];
      
      final List<dynamic> list = response.data is List ? response.data : (response.data['data'] ?? []);
      return list.map((json) => Complaint.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Fetch Complaints Error: $e');
      throw Exception('Failed to load complaints');
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
