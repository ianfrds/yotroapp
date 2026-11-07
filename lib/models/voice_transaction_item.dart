import 'category_model.dart';

/// Single item parsed from voice input.
class VoiceTransactionItem {
  final String title;
  final double amount;
  final String suggestedCategory;
  final TransactionType type;
  final String rawSnippet;

  const VoiceTransactionItem({
    required this.title,
    required this.amount,
    required this.suggestedCategory,
    this.type = TransactionType.expense,
    this.rawSnippet = '',
  });

  VoiceTransactionItem copyWith({
    String? title,
    double? amount,
    String? suggestedCategory,
    TransactionType? type,
    String? rawSnippet,
  }) {
    return VoiceTransactionItem(
      title: title ?? this.title,
      amount: amount ?? this.amount,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      type: type ?? this.type,
      rawSnippet: rawSnippet ?? this.rawSnippet,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'amount': amount,
    'suggestedCategory': suggestedCategory,
    'type': type.name,
    'rawSnippet': rawSnippet,
  };

  factory VoiceTransactionItem.fromJson(Map<String, dynamic> json) {
    return VoiceTransactionItem(
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      suggestedCategory: json['suggestedCategory'] as String? ?? 'Makanan & Minuman',
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      rawSnippet: json['rawSnippet'] as String? ?? '',
    );
  }
}

/// Aggregated result of voice parsing.
class VoiceParseResult {
  final List<VoiceTransactionItem> items;
  final String rawTranscription;
  final bool isValid;
  final String? validationError;

  const VoiceParseResult({
    required this.items,
    required this.rawTranscription,
    required this.isValid,
    this.validationError,
  });

  double get totalAmount => items.fold(0.0, (sum, it) => sum + it.amount);

  bool get isSingleItem => items.length == 1;
  bool get isMultiItem => items.length > 1;
}
