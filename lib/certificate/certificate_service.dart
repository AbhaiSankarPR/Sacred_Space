import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../auth/api_service.dart';
import 'certificate_model.dart';
import '../core/models/paginated_response.dart';

class CertificateService {
  // GET: Fetch all certificate requests for the current user
  Future<PaginatedResponse<CertificateRequest>> fetchMyRequests({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await apiService.get('/certificate/my-requests?page=$page&limit=$limit');

      // Safety check: ensure we have data
      if (response.data == null) {
        return PaginatedResponse(
          data: [],
          meta: PaginationMeta(page: page, limit: limit, hasMore: false),
        );
      }

      final decodedData = response.data is String
          ? json.decode(response.data)
          : response.data;

      List<dynamic> requestsList = [];
      PaginationMeta meta;

      if (decodedData is Map<String, dynamic>) {
        requestsList = decodedData['data'] ?? [];
        if (decodedData.containsKey('meta') && decodedData['meta'] != null) {
          meta = PaginationMeta.fromJson(decodedData['meta']);
        } else {
          final int count = decodedData['count'] ?? requestsList.length;
          final bool hasMore = (page * limit) < count;
          meta = PaginationMeta(page: page, limit: limit, hasMore: hasMore);
        }
      } else if (decodedData is List) {
        requestsList = decodedData;
        final bool hasMore = requestsList.length == limit;
        meta = PaginationMeta(page: page, limit: limit, hasMore: hasMore);
      } else {
        requestsList = [];
        meta = PaginationMeta(page: page, limit: limit, hasMore: false);
      }

      final data = requestsList
          .map((json) => CertificateRequest.fromJson(json))
          .toList();

      return PaginatedResponse(
        data: data,
        meta: meta,
      );
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
  Future<PaginatedResponse<CertificateRequest>> fetchChurchRequests({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'page': page,
        'limit': limit,
      };
      if (status != null && status != 'ALL') {
        params['status'] = status;
      }
      final response = await apiService.get('/certificate', params: params);

      if (response.data == null) {
        return PaginatedResponse(
          data: [],
          meta: PaginationMeta(page: page, limit: limit, hasMore: false),
        );
      }

      final decodedData = response.data is String
          ? json.decode(response.data)
          : response.data;

      List<dynamic> requestsList = [];
      PaginationMeta meta;

      if (decodedData is Map<String, dynamic>) {
        requestsList = decodedData['data'] ?? [];
        if (decodedData.containsKey('meta') && decodedData['meta'] != null) {
          meta = PaginationMeta.fromJson(decodedData['meta']);
        } else {
          final int count = decodedData['count'] ?? requestsList.length;
          final bool hasMore = (page * limit) < count;
          meta = PaginationMeta(page: page, limit: limit, hasMore: hasMore);
        }
      } else if (decodedData is List) {
        requestsList = decodedData;
        final bool hasMore = requestsList.length == limit;
        meta = PaginationMeta(page: page, limit: limit, hasMore: hasMore);
      } else {
        requestsList = [];
        meta = PaginationMeta(page: page, limit: limit, hasMore: false);
      }

      final data = requestsList
          .map((json) => CertificateRequest.fromJson(json))
          .toList();

      return PaginatedResponse(
        data: data,
        meta: meta,
      );
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

  // GET: Download approved certificate PDF
  Future<String> downloadCertificate(String id, String typeName) async {
    try {
      final response = await apiService.get(
        '/certificate/$id/download',
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      if (response.data == null) {
        throw Exception('No data received from the server');
      }

      final Uint8List bytes = Uint8List.fromList(response.data);
      
      String? initialDirectory;
      try {
        if (Platform.isAndroid) {
          final dir = await getExternalStorageDirectory();
          initialDirectory = dir?.path;
        } else {
          final dir = await getDownloadsDirectory();
          initialDirectory = dir?.path;
        }
      } catch (e) {
        debugPrint("Error getting directory: $e");
      }
      
      String? savePath = await FilePicker.saveFile(
        dialogTitle: 'Save Certificate',
        fileName: '${typeName.toLowerCase().replaceAll(' ', '_')}_$id.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        initialDirectory: initialDirectory,
        bytes: bytes,
      );

      if (savePath == null) {
        return "Download cancelled.";
      }

      if (!Platform.isAndroid && !Platform.isIOS) {
        final File file = File(savePath);
        await file.writeAsBytes(bytes);
      }

      debugPrint("File saved to: $savePath");
      
      try {
        final result = await OpenFilex.open(savePath);
        if (result.type == ResultType.noAppToOpen) {
          return "Certificate saved successfully! (No app installed to open PDF)";
        }
      } catch (e) {
        debugPrint("Auto-open failed: $e");
      }

      return "Certificate saved successfully!";
    } catch (e) {
      debugPrint("Error downloading certificate: $e");
      return "Failed to download certificate. Please check your connection.";
    }
  }
}

