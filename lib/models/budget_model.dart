class BudgetModel {
  double overallMonthlyLimit;
  Map<String, double> categoryBudgets;

  BudgetModel({
    this.overallMonthlyLimit = 2000.0,
    Map<String, double>? categoryBudgets,
  }) : categoryBudgets = categoryBudgets ?? {};

  Map<String, dynamic> toJson() {
    return {
      'overallMonthlyLimit': overallMonthlyLimit,
      'categoryBudgets': categoryBudgets,
    };
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      overallMonthlyLimit: (json['overallMonthlyLimit'] as num?)?.toDouble() ?? 2000.0,
      categoryBudgets: (json['categoryBudgets'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ?? {},
    );
  }
}

