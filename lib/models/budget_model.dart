class BudgetModel {
  double overallMonthlyLimit;
  Map<String, double> categoryBudgets;
  int monthlyResetDay;

  BudgetModel({
    this.overallMonthlyLimit = 2000.0,
    Map<String, double>? categoryBudgets,
    int? monthlyResetDay,
  })  : categoryBudgets = categoryBudgets ?? {},
        monthlyResetDay = (monthlyResetDay ?? 1).clamp(1, 31);

  Map<String, dynamic> toJson() {
    return {
      'overallMonthlyLimit': overallMonthlyLimit,
      'categoryBudgets': categoryBudgets,
      'monthlyResetDay': monthlyResetDay,
    };
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      overallMonthlyLimit: (json['overallMonthlyLimit'] as num?)?.toDouble() ?? 2000.0,
      categoryBudgets: (json['categoryBudgets'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ?? {},
      monthlyResetDay: ((json['monthlyResetDay'] as num?)?.toInt() ?? 1).clamp(1, 31),
    );
  }
}

