import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/models/wallet_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Category Persistence & Cloud Sync Protection Tests', () {
    test('addCategory creates custom category and persists in provider', () async {
      final provider = TransactionProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final initialCount = provider.categories.length;
      final newCat = await provider.addCategory(
        name: 'Kopi & Nongkrong',
        type: TransactionType.expense,
        emoji: '☕',
      );

      expect(newCat.name, 'Kopi & Nongkrong');
      expect(newCat.isDefault, isFalse);
      expect(provider.categories.length, initialCount + 1);
      expect(provider.categories.any((c) => c.id == newCat.id), isTrue);
    });

    test('applyCloudSnapshot protects local custom categories from being wiped out by cloud', () async {
      final provider = TransactionProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      // Add a local custom category on Day 1
      final customCat = await provider.addCategory(
        name: 'Skincare',
        type: TransactionType.expense,
        emoji: '🧴',
      );
      expect(provider.categories.any((c) => c.name == 'Skincare'), isTrue);

      // Cloud snapshot on Day 2 only has default categories (missing Skincare)
      final cloudCategories = [
        ...CategoryModel.defaultExpenseCategories,
        ...CategoryModel.defaultIncomeCategories,
      ];

      provider.applyCloudSnapshot(
        categories: cloudCategories,
        wallets: [
          WalletModel(id: 'w1', name: 'Dompet Utama', type: 'Cash', balance: 500000),
        ],
      );

      // Skincare MUST NOT be deleted!
      expect(provider.categories.any((c) => c.name == 'Skincare'), isTrue,
          reason: 'Custom category Skincare must be preserved after cloud pull');
      expect(provider.categories.firstWhere((c) => c.name == 'Skincare').id, customCat.id);
    });

    test('applyCloudSnapshot self-heals missing custom categories from transactions', () async {
      final provider = TransactionProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      // Simulate cloud returning a transaction recorded with a custom category "Gym Member"
      // but categories list from cloud forgot the category
      final cloudTx = TransactionModel(
        id: 'tx_gym',
        title: 'Iuran Gym Bulanan',
        amount: 250000,
        type: TransactionType.expense,
        categoryId: 'cat_gym_custom',
        categoryName: 'Gym Member',
        walletId: 'w1',
        timestamp: DateTime.now(),
      );

      final cloudCategories = [
        ...CategoryModel.defaultExpenseCategories,
        ...CategoryModel.defaultIncomeCategories,
      ];

      provider.applyCloudSnapshot(
        categories: cloudCategories,
        transactions: [cloudTx],
      );

      expect(provider.categories.any((c) => c.name == 'Gym Member'), isTrue,
          reason: 'Custom category referenced in transaction must be self-healed');
      final healedCat = provider.categories.firstWhere((c) => c.name == 'Gym Member');
      expect(healedCat.id, 'cat_gym_custom');
      expect(healedCat.isDefault, isFalse);
    });

    test('Provider _loadData self-heals categories referenced by transactions from storage', () async {
      // Simulate stored JSON where categories array only has default categories,
      // but transactions array has a transaction with a custom category "Buku Pelajaran"
      final mockData = {
        'categories': [
          ...CategoryModel.defaultExpenseCategories.map((c) => c.toJson()),
        ],
        'transactions': [
          {
            'id': 'tx_buku',
            'title': 'Beli Buku Flutter',
            'amount': 150000.0,
            'type': 'expense',
            'categoryId': 'cat_buku_123',
            'categoryName': 'Buku Pelajaran',
            'walletId': 'w_main',
            'timestamp': DateTime.now().toIso8601String(),
          }
        ],
        'wallets': [
          {'id': 'w_main', 'name': 'Dompet Utama', 'type': 'Cash', 'balance': 200000.0}
        ],
        'isOnboardingCompleted': true,
      };

      SharedPreferences.setMockInitialValues({
        'money_tracker_pro_v2_1': jsonEncode(mockData),
      });

      final provider = TransactionProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.categories.any((c) => c.name == 'Buku Pelajaran'), isTrue,
          reason: 'Custom category must be recovered from stored transaction history on app start');
      expect(provider.categories.firstWhere((c) => c.name == 'Buku Pelajaran').id, 'cat_buku_123');
    });
  });
}
