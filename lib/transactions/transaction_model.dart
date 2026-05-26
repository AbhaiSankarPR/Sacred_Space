import 'package:flutter/material.dart';

enum TransactionType { INCOME, EXPENSE }

enum PaymentMethod { CASH, BANK }

class Transaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String category;
  final PaymentMethod paymentMethod;
  final String status;
  final String? remarks;
  final DateTime date;
  final String churchId;
  final String createdById;
  final DateTime createdAt;
  final CreatedBy createdBy;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.paymentMethod,
    required this.status,
    this.remarks,
    required this.date,
    required this.churchId,
    required this.createdById,
    required this.createdAt,
    required this.createdBy,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      type: json['type'] == 'INCOME' ? TransactionType.INCOME : TransactionType.EXPENSE,
      category: json['category'],
      paymentMethod: json['paymentMethod'] == 'BANK' ? PaymentMethod.BANK : PaymentMethod.CASH,
      status: json['status'],
      remarks: json['remarks'],
      date: DateTime.parse(json['date']),
      churchId: json['churchId'],
      createdById: json['createdById'],
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: CreatedBy.fromJson(json['createdBy']),
    );
  }
}

class CreatedBy {
  final String email;
  final String role;
  final String name;

  CreatedBy({
    required this.email,
    required this.role,
    required this.name,
  });

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      name: json['profile']?['name'] ?? '',
    );
  }
}

class TransactionResponse {
  final List<Transaction> transactions;
  final double totalAmount;

  TransactionResponse({
    required this.transactions,
    required this.totalAmount,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    var list = json['transactions'] as List;
    List<Transaction> transactionsList = list.map((i) => Transaction.fromJson(i)).toList();
    
    return TransactionResponse(
      transactions: transactionsList,
      totalAmount: double.tryParse(json['totalAmount'].toString()) ?? 0.0,
    );
  }
}

class TransactionCategories {
  static const List<String> incomeCategories = [
    'ONLINE_OFFERING',
    'WEEKLY_KANIKKA',
    'WEEKLY_KAYCHAVAYPP',
    'MONTHLY_KURISHADI_KANIKKA',
    'MONTHLY_KANIKKA_INSIDE_CHURCH',
    'OTHER_INCOME'
  ];

  static const List<String> expenseCategories = [
    'BOOKING_PAYMENT',
    'PRIEST_SALARY',
    'OFFICIALS_SALARY',
    'CURRENT_BILL',
    'OTHER_EXPENSE'
  ];

  static List<String> getCategoriesForType(TransactionType type) {
    return type == TransactionType.INCOME ? incomeCategories : expenseCategories;
  }
  
  static String formatCategory(String category) {
    return category.split('_').map((word) {
      if (word.isEmpty) return '';
      return word[0] + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
