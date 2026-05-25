import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../auth/api_service.dart';
import 'certificate_model.dart';

class CertificateService {
  // GET: Fetch all certificate requests for the current user
  Future<List<CertificateRequest>> fetchMyRequests() async {
    try {
      final response = await apiService.get('/certificate/my-requests');

      // Safety check: ensure we have data
      if (response.data == null) return [];

      final List<dynamic> requestsList = response.data is String
          ? json.decode(response.data)
          : response.data;

      return requestsList
          .map((json) => CertificateRequest.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Fetch Certificate Requests Error: $e');
      throw Exception('Failed to load certificate requests: $e');
    }
  }

  // POST: Create a new certificate request
  Future<String> createCertificateRequest({
    required String type,
    required Map<String, dynamic> details,
  }) async {
    try {
      final body = {
        'type': type,
        'details': details,
      };

      final response = await apiService.post('/certificate/request', body);

      final responseData = response.data is String
          ? json.decode(response.data)
          : response.data;

      return responseData['message'] ?? 'Certificate request submitted successfully';
    } catch (e) {
      debugPrint('Create Certificate Request Error: $e');
      throw Exception('Failed to submit certificate request');
    }
  }

  // GET: Fetch all certificate requests in the church (Priest/Officials only)
  Future<List<CertificateRequest>> fetchChurchRequests({String? status}) async {
    try {
      final Map<String, dynamic> params = {};
      if (status != null && status != 'ALL') {
        params['status'] = status;
      }
      final response = await apiService.get('/certificate', params: params);

      if (response.data == null) return [];

      final List<dynamic> requestsList = response.data is String
          ? json.decode(response.data)
          : response.data;

      return requestsList
          .map((json) => CertificateRequest.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Fetch Church Certificate Requests Error: $e');
      throw Exception('Failed to load certificate requests: $e');
    }
  }

  // PUT: Approve a certificate request (Priest/Officials only)
  Future<String> approveRequest(String id, {Map<String, dynamic>? body}) async {
    try {
      final response = await apiService.put('/certificate/$id/approve', body ?? {});
      
      final responseData = response.data is String
          ? json.decode(response.data)
          : response.data;
          
      return responseData['message'] ?? 'Certificate approved successfully';
    } catch (e) {
      debugPrint('Approve Certificate Request Error: $e');
      throw Exception('Failed to approve certificate request');
    }
  }

  // PUT: Reject a certificate request (Priest/Officials only)
  Future<String> rejectRequest(String id, String? reason) async {
    try {
      final Map<String, dynamic> body = {};
      if (reason != null && reason.trim().isNotEmpty) {
        body['reason'] = reason.trim();
      }
      final response = await apiService.put('/certificate/$id/reject', body);
      
      final responseData = response.data is String
          ? json.decode(response.data)
          : response.data;
          
      return responseData['message'] ?? 'Certificate rejected successfully';
    } catch (e) {
      debugPrint('Reject Certificate Request Error: $e');
      throw Exception('Failed to reject certificate request');
    }
  }
}
