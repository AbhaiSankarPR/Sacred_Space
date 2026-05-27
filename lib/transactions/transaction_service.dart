import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../auth/api_service.dart';
import 'transaction_model.dart';

class TransactionService extends ChangeNotifier {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;

  TransactionService._internal();

  bool isLoading = false;
  TransactionResponse? lastResponse;

  Future<TransactionResponse> getTransactions() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.get('/transaction');
      final transactionResponse = TransactionResponse.fromJson(response.data);
      lastResponse = transactionResponse;
      
      isLoading = false;
      notifyListeners();
      return transactionResponse;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint("Error fetching transactions: $e");
      rethrow;
    }
  }

  Future<void> addTransaction(Map<String, dynamic> data) async {
    try {
      await apiService.post('/transaction', data);
      await getTransactions(); // Refresh the list
    } catch (e) {
      debugPrint("Error adding transaction: $e");
      rethrow;
    }
  }

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
