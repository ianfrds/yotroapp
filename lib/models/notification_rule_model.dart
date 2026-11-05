import 'package:flutter/material.dart';
import 'category_model.dart';

enum PendingNotificationStatus {
  pending,
  approved,
  rejected,
}

class NotificationRule {
  final String id;
  final String appName;
  final String? packageName;
  final IconData icon;
  final List<String> triggerKeywords;
  final List<String> ignoreKeywords;
  final String defaultWalletName;
  final String defaultCategoryName;
  final bool isEnabled;

  const NotificationRule({
    required this.id,
    required this.appName,
    this.packageName,
    required this.icon,
    required this.triggerKeywords,
    required this.ignoreKeywords,
    required this.defaultWalletName,
    required this.defaultCategoryName,
    this.isEnabled = true,
  });

  NotificationRule copyWith({
    String? id,
    String? appName,
    String? packageName,
    IconData? icon,
    List<String>? triggerKeywords,
    List<String>? ignoreKeywords,
    String? defaultWalletName,
    String? defaultCategoryName,
    bool? isEnabled,
  }) {
    return NotificationRule(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      icon: icon ?? this.icon,
      triggerKeywords: triggerKeywords ?? this.triggerKeywords,
      ignoreKeywords: ignoreKeywords ?? this.ignoreKeywords,
      defaultWalletName: defaultWalletName ?? this.defaultWalletName,
      defaultCategoryName: defaultCategoryName ?? this.defaultCategoryName,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appName': appName,
      'packageName': packageName,
      'iconCodePoint': icon.codePoint,
      'triggerKeywords': triggerKeywords,
      'ignoreKeywords': ignoreKeywords,
      'defaultWalletName': defaultWalletName,
      'defaultCategoryName': defaultCategoryName,
      'isEnabled': isEnabled,
    };
  }

  static IconData _resolveIcon(int? codePoint, String? appName) {
    if (codePoint != null) {
      if (codePoint == Icons.account_balance_outlined.codePoint) return Icons.account_balance_outlined;
      if (codePoint == Icons.phone_android_rounded.codePoint) return Icons.phone_android_rounded;
      if (codePoint == Icons.account_balance_rounded.codePoint) return Icons.account_balance_rounded;
      if (codePoint == Icons.shopping_bag_outlined.codePoint) return Icons.shopping_bag_outlined;
      if (codePoint == Icons.account_balance_wallet_outlined.codePoint) return Icons.account_balance_wallet_outlined;
    }
    final lower = (appName ?? '').toLowerCase();
    if (lower.contains('bca') || lower.contains('bank')) return Icons.account_balance_outlined;
    if (lower.contains('gopay') || lower.contains('ovo') || lower.contains('dana')) return Icons.phone_android_rounded;
    if (lower.contains('shopee')) return Icons.shopping_bag_outlined;
    return Icons.account_balance_wallet_outlined;
  }

  factory NotificationRule.fromJson(Map<String, dynamic> json) {
    final appName = json['appName'] as String? ?? 'Aplikasi';
    return NotificationRule(
      id: json['id'] as String? ?? UniqueKey().toString(),
      appName: appName,
      packageName: json['packageName'] as String?,
      icon: _resolveIcon(json['iconCodePoint'] as int?, appName),
      triggerKeywords: (json['triggerKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['QRIS', 'Transfer', 'Pembayaran', 'Berhasil'],
      ignoreKeywords: (json['ignoreKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['promo', 'diskon', 'cashback', 'voucher', 'penawaran'],
      defaultWalletName: json['defaultWalletName'] as String? ?? 'Dompet Utama',
      defaultCategoryName: json['defaultCategoryName'] as String? ?? 'Makanan & Minuman',
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  static List<NotificationRule> get defaultRules => [
        const NotificationRule(
          id: 'rule_bca',
          appName: 'myBCA',
          packageName: 'com.bca',
          icon: Icons.account_balance_outlined,
          triggerKeywords: ['QRIS', 'Transfer', 'Pembayaran', 'Debit', 'Berhasil', 'Sukses'],
          ignoreKeywords: ['promo', 'diskon', 'cashback', 'voucher', 'penawaran'],
          defaultWalletName: 'BCA Prioritas',
          defaultCategoryName: 'Makanan & Minuman',
          isEnabled: true,
        ),
        const NotificationRule(
          id: 'rule_seabank',
          appName: 'SeaBank',
          packageName: 'com.seabank.id',
          icon: Icons.account_balance_rounded,
          triggerKeywords: ['QRIS', 'Transfer', 'Pembayaran', 'Debit', 'Berhasil', 'Sukses'],
          ignoreKeywords: ['promo', 'diskon', 'cashback', 'voucher', 'penawaran'],
          defaultWalletName: 'BCA Prioritas',
          defaultCategoryName: 'Makanan & Minuman',
          isEnabled: true,
        ),
        const NotificationRule(
          id: 'rule_gopay',
          appName: 'GoPay',
          packageName: 'com.gojek.app',
          icon: Icons.phone_android_rounded,
          triggerKeywords: ['Pembayaran', 'Transfer', 'Order', 'Gojek', 'Berhasil', 'Sukses'],
          ignoreKeywords: ['promo', 'diskon', 'cashback', 'voucher', 'penawaran', 'klaim'],
          defaultWalletName: 'GoPay',
          defaultCategoryName: 'Transportasi',
          isEnabled: true,
        ),
        const NotificationRule(
          id: 'rule_mandiri',
          appName: 'Livin by Mandiri',
          packageName: 'id.bmri.livin',
          icon: Icons.account_balance_rounded,
          triggerKeywords: ['Debit', 'QRIS', 'Transfer', 'Bayar', 'Berhasil', 'Sukses'],
          ignoreKeywords: ['promo', 'diskon', 'cashback', 'voucher', 'undian'],
          defaultWalletName: 'BCA Prioritas',
          defaultCategoryName: 'Tagihan & Utilitas',
          isEnabled: true,
        ),
        const NotificationRule(
          id: 'rule_shopeepay',
          appName: 'ShopeePay',
          packageName: 'com.shopee.id',
          icon: Icons.shopping_bag_outlined,
          triggerKeywords: ['Pembayaran', 'Pesanan', 'QRIS', 'Berhasil', 'Sukses'],
          ignoreKeywords: ['promo', 'diskon', 'cashback', 'voucher', 'flash sale'],
          defaultWalletName: 'Dompet Tunai',
          defaultCategoryName: 'Belanja',
          isEnabled: true,
        ),
      ];
}

class PendingNotification {
  final String id;
  final String sourceApp;
  final String title;
  final String rawMessage;
  final double amount;
  final String walletName;
  final String categoryName;
  final DateTime timestamp;
  final PendingNotificationStatus status;
  final TransactionType type;

  const PendingNotification({
    required this.id,
    required this.sourceApp,
    required this.title,
    required this.rawMessage,
    required this.amount,
    required this.walletName,
    required this.categoryName,
    required this.timestamp,
    this.status = PendingNotificationStatus.pending,
    this.type = TransactionType.expense,
  });

  PendingNotification copyWith({
    String? id,
    String? sourceApp,
    String? title,
    String? rawMessage,
    double? amount,
    String? walletName,
    String? categoryName,
    DateTime? timestamp,
    PendingNotificationStatus? status,
    TransactionType? type,
  }) {
    return PendingNotification(
      id: id ?? this.id,
      sourceApp: sourceApp ?? this.sourceApp,
      title: title ?? this.title,
      rawMessage: rawMessage ?? this.rawMessage,
      amount: amount ?? this.amount,
      walletName: walletName ?? this.walletName,
      categoryName: categoryName ?? this.categoryName,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceApp': sourceApp,
      'title': title,
      'rawMessage': rawMessage,
      'amount': amount,
      'walletName': walletName,
      'categoryName': categoryName,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'type': type.name,
    };
  }

  factory PendingNotification.fromJson(Map<String, dynamic> json) {
    return PendingNotification(
      id: json['id'] as String? ?? UniqueKey().toString(),
      sourceApp: json['sourceApp'] as String? ?? 'Notifikasi',
      title: json['title'] as String? ?? 'Transaksi Otomatis',
      rawMessage: json['rawMessage'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      walletName: json['walletName'] as String? ?? 'Dompet Utama',
      categoryName: json['categoryName'] as String? ?? 'Food & Beverage',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: PendingNotificationStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'pending'),
        orElse: () => PendingNotificationStatus.pending,
      ),
      type: TransactionType.values.firstWhere(
        (t) => t.name == (json['type'] as String? ?? 'expense'),
        orElse: () => TransactionType.expense,
      ),
    );
  }
}

class ActivityNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final TransactionType? type;
  final double? amount;
  final bool isRead;

  const ActivityNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.type,
    this.amount,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type?.name,
      'amount': amount,
      'isRead': isRead,
    };
  }

  factory ActivityNotification.fromJson(Map<String, dynamic> json) {
    return ActivityNotification(
      id: json['id'] as String? ?? UniqueKey().toString(),
      title: json['title'] as String? ?? 'Notifikasi',
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      type: json['type'] != null
          ? TransactionType.values.firstWhere(
              (t) => t.name == json['type'],
              orElse: () => TransactionType.expense,
            )
          : null,
      amount: (json['amount'] as num?)?.toDouble(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}
