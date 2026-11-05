import 'category_model.dart';

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String categoryName;
  final String walletId;
  final String? fromWalletId;
  final String? toWalletId;
  final String note;
  final DateTime timestamp;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.walletId,
    this.fromWalletId,
    this.toWalletId,
    this.note = '',
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'walletId': walletId,
      'fromWalletId': fromWalletId,
      'toWalletId': toWalletId,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    TransactionType parsedType = TransactionType.expense;
    if (json['type'] == 'income') {
      parsedType = TransactionType.income;
    } else if (json['type'] == 'transfer') {
      parsedType = TransactionType.transfer;
    }

    return TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: parsedType,
      categoryId: json['categoryId'] as String? ?? 'others',
      categoryName: json['categoryName'] as String? ?? 'Others',
      walletId: json['walletId'] as String? ?? 'w_bank',
      fromWalletId: json['fromWalletId'] as String?,
      toWalletId: json['toWalletId'] as String?,
      note: (json['note'] as String?) ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
