import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../auth/api_service.dart';
import 'transaction_model.dart';
import '../core/models/paginated_response.dart';

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;

  TransactionService._internal();

  // GET: Fetch transactions using the project-wide paginated wrapper
  Future<PaginatedResponse<Transaction>> fetchTransactions({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await apiService.get(
        '/transaction?page=$page&limit=$limit',
      );

      if (response.data == null) {
        return PaginatedResponse(
          data: [],
          meta: PaginationMeta(page: page, limit: limit, hasMore: false),
        );
      }

      final Map<String, dynamic> decodedData = response.data is String
          ? Map<String, dynamic>.from(json.decode(response.data) as Map)
          : Map<String, dynamic>.from(response.data as Map);

      final List<dynamic> list = decodedData['data'] ?? [];
      final metaJson = decodedData['meta'] != null
          ? Map<String, dynamic>.from(decodedData['meta'] as Map)
          : <String, dynamic>{};
      final meta = PaginationMeta.fromJson(metaJson);

      final data = list.map((json) => Transaction.fromJson(json)).toList();

      return PaginatedResponse(data: data, meta: meta);
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
      rethrow;
    }
  }

  // GET: Fetch total amount from the separate endpoint
  Future<double> fetchTotalAmount() async {
    try {
      final response = await apiService.get('/transaction/total');
      if (response.data == null) return 0.0;

      final Map<String, dynamic> decodedData = response.data is String
          ? Map<String, dynamic>.from(json.decode(response.data) as Map)
          : Map<String, dynamic>.from(response.data as Map);

      return double.tryParse((decodedData['totalAmount'] ?? 0.0).toString()) ??
          0.0;
    } catch (e) {
      debugPrint("Error fetching total balance: $e");
      return 0.0;
    }
  }

  // POST: Add a transaction
  Future<void> addTransaction(Map<String, dynamic> data) async {
    try {
      await apiService.post('/transaction', data);
    } catch (e) {
      debugPrint("Error adding transaction: $e");
      rethrow;
    }
  }

  // GET: Download report file
  Future<String> downloadReport(String month) async {
    try {
      // month should be in format 'YYYY-MM'
      final response = await apiService.get(
        '/transaction/report',
        params: {'month': month},
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

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
        dialogTitle: 'Save Transactions Report',
        fileName: 'transactions_report_$month.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
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
          return "Report saved successfully! (No app installed to open Excel)";
        }
      } catch (e) {
        debugPrint("Auto-open failed: $e");
      }

      return "Report saved successfully!";
    } catch (e) {
      debugPrint("Error downloading report: $e");
      return "Failed to download report. Please check your connection.";
    }
  }
}
