enum SubscriptionCycle {
  monthly,
  yearly,
  weekly;

  String get label {
    switch (this) {
      case SubscriptionCycle.monthly:
        return 'Bulanan';
      case SubscriptionCycle.yearly:
        return 'Tahunan';
      case SubscriptionCycle.weekly:
        return 'Mingguan';
    }
  }

  String get shortUnit {
    switch (this) {
      case SubscriptionCycle.monthly:
        return '/bln';
      case SubscriptionCycle.yearly:
        return '/thn';
      case SubscriptionCycle.weekly:
        return '/mgg';
    }
  }
}

enum SubscriptionStatus {
  paid,
  dueToday,
  dueSoon,
  overdue,
  upcoming;

  String get label {
    switch (this) {
      case SubscriptionStatus.paid:
        return 'Lunas';
      case SubscriptionStatus.dueToday:
        return 'Hari Ini';
      case SubscriptionStatus.dueSoon:
        return 'Segera';
      case SubscriptionStatus.overdue:
        return 'Terlewat';
      case SubscriptionStatus.upcoming:
        return 'Mendatang';
    }
  }
}

class SubscriptionModel {
  final String id;
  final String name;
  final double amount;
  final int billingDay; // 1 to 31
  final SubscriptionCycle cycle;
  final String categoryId;
  final String categoryName;
  final String walletId;
  final bool reminderEnabled;
  final int reminderDaysBefore; // default 1
  final DateTime? lastPaidDate;
  final DateTime createdAt;

  const SubscriptionModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.billingDay,
    this.cycle = SubscriptionCycle.monthly,
    required this.categoryId,
    required this.categoryName,
    required this.walletId,
    this.reminderEnabled = true,
    this.reminderDaysBefore = 1,
    this.lastPaidDate,
    required this.createdAt,
  });

  bool isPaidInMonth(DateTime month) {
    if (lastPaidDate == null) return false;
    final local = lastPaidDate!.toLocal();
    return local.year == month.year && local.month == month.month;
  }

  DateTime nextDueDate(DateTime now) {
    final daysInThisMonth = DateTime(now.year, now.month + 1, 0).day;
    final clampedDay = billingDay.clamp(1, daysInThisMonth);
    final thisMonthDue = DateTime(now.year, now.month, clampedDay);
    final today = DateTime(now.year, now.month, now.day);

    if (thisMonthDue.isBefore(today) && isPaidInMonth(now)) {
      // Already paid this month, so next due is next month
      final nextMonth = now.month == 12
          ? DateTime(now.year + 1, 1, 1)
          : DateTime(now.year, now.month + 1, 1);
      final daysInNextMonth =
          DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
      return DateTime(
        nextMonth.year,
        nextMonth.month,
        billingDay.clamp(1, daysInNextMonth),
      );
    }
    return thisMonthDue;
  }

  SubscriptionStatus getStatus(DateTime now) {
    if (isPaidInMonth(now)) return SubscriptionStatus.paid;

    final daysInThisMonth = DateTime(now.year, now.month + 1, 0).day;
    final clampedDay = billingDay.clamp(1, daysInThisMonth);
    final thisMonthDue = DateTime(now.year, now.month, clampedDay);
    final today = DateTime(now.year, now.month, now.day);

    if (thisMonthDue.isBefore(today)) {
      return SubscriptionStatus.overdue;
    } else if (thisMonthDue.isAtSameMomentAs(today)) {
      return SubscriptionStatus.dueToday;
    } else {
      final diff = thisMonthDue.difference(today).inDays;
      if (diff <= 3) return SubscriptionStatus.dueSoon;
      return SubscriptionStatus.upcoming;
    }
  }

  int daysUntilDue(DateTime now) {
    final daysInThisMonth = DateTime(now.year, now.month + 1, 0).day;
    final clampedDay = billingDay.clamp(1, daysInThisMonth);
    final thisMonthDue = DateTime(now.year, now.month, clampedDay);
    final today = DateTime(now.year, now.month, now.day);
    return thisMonthDue.difference(today).inDays;
  }

  SubscriptionModel copyWith({
    String? id,
    String? name,
    double? amount,
    int? billingDay,
    SubscriptionCycle? cycle,
    String? categoryId,
    String? categoryName,
    String? walletId,
    bool? reminderEnabled,
    int? reminderDaysBefore,
    DateTime? lastPaidDate,
    bool clearLastPaidDate = false,
    DateTime? createdAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      billingDay: billingDay ?? this.billingDay,
      cycle: cycle ?? this.cycle,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      walletId: walletId ?? this.walletId,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      lastPaidDate: clearLastPaidDate ? null : (lastPaidDate ?? this.lastPaidDate),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'billingDay': billingDay,
      'cycle': cycle.name,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'walletId': walletId,
      'reminderEnabled': reminderEnabled,
      'reminderDaysBefore': reminderDaysBefore,
      'lastPaidDate': lastPaidDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      billingDay: (json['billingDay'] as num?)?.toInt() ?? 1,
      cycle: SubscriptionCycle.values.firstWhere(
        (c) => c.name == (json['cycle'] as String? ?? 'monthly'),
        orElse: () => SubscriptionCycle.monthly,
      ),
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? 'Tagihan & Utilitas',
      walletId: json['walletId'] as String? ?? '',
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      reminderDaysBefore: (json['reminderDaysBefore'] as num?)?.toInt() ?? 1,
      lastPaidDate: json['lastPaidDate'] != null
          ? DateTime.tryParse(json['lastPaidDate'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
