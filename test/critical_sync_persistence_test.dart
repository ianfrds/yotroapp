import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_tracker/models/budget_model.dart';
import 'package:money_tracker/models/subscription_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Critical Sync & Persistence Protection', () {
    test('applyCloudSnapshot preserves local subscriptions not yet in cloud and keeps newer lastPaidDate', () async {
      final provider = TransactionProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.addSubscription(
        name: 'Spotify Family',
        amount: 86900,
        billingDay: 15,
        cycle: SubscriptionCycle.monthly,
        categoryId: 'cat_bills',
        categoryName: 'Tagihan & Utilitas',
        walletId: 'w_bank',
      );

      final localPaidDate = DateTime(2026, 11, 20, 10, 0);
      final cloudSharedSub = SubscriptionModel(
        id: 'sub_cloud_1',
        name: 'Netflix',
        amount: 186000,
        billingDay: 25,
        cycle: SubscriptionCycle.monthly,
        categoryId: 'cat_bills',
        categoryName: 'Tagihan & Utilitas',
        walletId: 'w_bank',
        lastPaidDate: null,
        createdAt: DateTime(2026, 11, 1),
      );

      // Simulate local has sub_cloud_1 paid locally, plus Spotify Family only local
      await provider.updateSubscription(cloudSharedSub.copyWith(lastPaidDate: localPaidDate));
      // Add cloudSharedSub directly first if updateSubscription didn't insert it
      provider.applyCloudSnapshot(
        subscriptions: [cloudSharedSub.copyWith(lastPaidDate: localPaidDate)],
      );

      // Now simulate Day 2 cloud pull where cloud only has cloudSharedSub (unpaid) and doesn't have Spotify Family yet
      provider.applyCloudSnapshot(
        subscriptions: [cloudSharedSub],
      );

      final spotify = provider.subscriptions.where((s) => s.name == 'Spotify Family').toList();
      expect(spotify.length, 1);

      final netflix = provider.subscriptions.firstWhere((s) => s.id == 'sub_cloud_1');
      expect(netflix.lastPaidDate, isNotNull);
      expect(netflix.lastPaidDate!.year, 2026);
      expect(netflix.lastPaidDate!.month, 11);
      expect(netflix.lastPaidDate!.day, 20);
    });

    test('Budget mutations update local state and reset day cleanly', () async {
      final provider = TransactionProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.updateOverallBudget(5000000);
      await provider.updateCategoryBudget('Makanan & Minuman', 1500000);
      await provider.updateBudgetResetDay(25);

      expect(provider.budget.overallMonthlyLimit, 5000000);
      expect(provider.budget.categoryBudgets['Makanan & Minuman'], 1500000);
      expect(provider.budget.monthlyResetDay, 25);

      await provider.deleteCategoryBudget('Makanan & Minuman');
      expect(provider.budget.categoryBudgets.containsKey('Makanan & Minuman'), isFalse);

      await provider.deleteOverallBudget();
      expect(provider.budget.overallMonthlyLimit, 0.0);
    });

    test('Profile updates persist name and phone cleanly', () async {
      final provider = TransactionProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.updateProfile(
        name: 'Ian Firdaus Updated',
        phone: '081234567890',
      );

      expect(provider.userName, 'Ian Firdaus Updated');
      expect(provider.userPhone, '081234567890');
    });

    test('applyCloudSnapshot applies cloud budget cleanly', () async {
      final provider = TransactionProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final cloudBudget = BudgetModel(
        overallMonthlyLimit: 7500000,
        categoryBudgets: {'Transportasi': 800000},
        monthlyResetDay: 10,
      );

      provider.applyCloudSnapshot(budget: cloudBudget);

      expect(provider.budget.overallMonthlyLimit, 7500000);
      expect(provider.budget.categoryBudgets['Transportasi'], 800000);
      expect(provider.budget.monthlyResetDay, 10);
    });
  });
}
