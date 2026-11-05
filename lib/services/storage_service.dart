import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class StorageService {
  static const String _keyTransactions = 'money_tracker_storage_v2';

  static final List<TransactionModel> defaultSamples = [
    TransactionModel(
      id: 'tx_netflix',
      title: 'Netflix',
      amount: 10.99,
      type: TransactionType.expense,
      categoryId: 'subscription',
      categoryName: 'Subscription',
      walletId: 'w_bank',
      note: 'Netflix monthly subscription payment',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    TransactionModel(
      id: 'tx_starbucks',
      title: 'Starbucks',
      amount: 3.29,
      type: TransactionType.expense,
      categoryId: 'food',
      categoryName: 'Food & Drinks',
      walletId: 'w_cash',
      note: 'Caramel Macchiato',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    TransactionModel(
      id: 'tx_uber',
      title: 'Uber',
      amount: 16.99,
      type: TransactionType.expense,
      categoryId: 'transport',
      categoryName: 'Transport',
      walletId: 'w_ewallet',
      note: 'Ride to downtown',
      timestamp: DateTime.now().subtract(const Duration(hours: 7)),
    ),
    TransactionModel(
      id: 'tx_amazon',
      title: 'Amazon',
      amount: 92.99,
      type: TransactionType.expense,
      categoryId: 'shopping',
      categoryName: 'Shopping',
      walletId: 'w_bank',
      note: 'Office wireless keyboard',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TransactionModel(
      id: 'tx_topup',
      title: 'Salary Deposit',
      amount: 8036.31,
      type: TransactionType.income,
      categoryId: 'salary',
      categoryName: 'Gaji / Salary',
      walletId: 'w_bank',
      note: 'Monthly direct payroll deposit',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  static Future<List<TransactionModel>> loadTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_keyTransactions);
      if (rawJson != null && rawJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawJson);
        return decoded.map((item) => TransactionModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      await saveTransactions(defaultSamples);
      return defaultSamples;
    } catch (_) {
      return defaultSamples;
    }
  }

  static Future<void> saveTransactions(List<TransactionModel> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = jsonEncode(transactions.map((t) => t.toJson()).toList());
      await prefs.setString(_keyTransactions, rawJson);
    } catch (_) {}
  }
}
