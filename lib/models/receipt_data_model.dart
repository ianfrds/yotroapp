class ReceiptDataModel {
  final double totalAmount;
  final List<double> alternativeAmounts;
  final String merchantName;
  final DateTime date;
  final String suggestedCategory;
  final String rawText;
  final List<String> lines;

  const ReceiptDataModel({
    required this.totalAmount,
    this.alternativeAmounts = const [],
    this.merchantName = '',
    required this.date,
    this.suggestedCategory = 'Makanan & Minuman',
    this.rawText = '',
    this.lines = const [],
  });

  ReceiptDataModel copyWith({
    double? totalAmount,
    List<double>? alternativeAmounts,
    String? merchantName,
    DateTime? date,
    String? suggestedCategory,
    String? rawText,
    List<String>? lines,
  }) {
    return ReceiptDataModel(
      totalAmount: totalAmount ?? this.totalAmount,
      alternativeAmounts: alternativeAmounts ?? this.alternativeAmounts,
      merchantName: merchantName ?? this.merchantName,
      date: date ?? this.date,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      rawText: rawText ?? this.rawText,
      lines: lines ?? this.lines,
    );
  }
}

