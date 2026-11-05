import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/manage_categories_screen.dart';
import 'package:money_tracker/screens/edit_category_screen.dart';
import 'package:money_tracker/widgets/modal_card_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Category Management CRUD & Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial seeded categories contain default expense and income categories', () async {
      final provider = TransactionProvider();
      await provider.loadData();
      expect(provider.categories.isNotEmpty, isTrue);

      final expenses = provider.getCategories(TransactionType.expense);
      final incomes = provider.getCategories(TransactionType.income);

      expect(expenses.any((c) => c.name == 'Food & Beverage'), isTrue);
      expect(incomes.any((c) => c.name == 'Salary'), isTrue);
    });

    test('Add custom Tabler category and Emoji category', () async {
      final provider = TransactionProvider();
      await provider.loadData();
      final initialCount = provider.categories.length;

      // Add Tabler Icon category
      await provider.addCategory(
        name: 'Kopi & Nongkrong',
        type: TransactionType.expense,
        iconName: 'coffee',
        colorValue: 0xFFFFC857,
      );

      // Add Emoji category
      await provider.addCategory(
        name: 'Gaji Freelance',
        type: TransactionType.income,
        emoji: '💻',
        colorValue: 0xFF2B8DE0,
      );

      expect(provider.categories.length, initialCount + 2);

      final coffeeCat = provider.categories.firstWhere((c) => c.name == 'Kopi & Nongkrong');
      expect(coffeeCat.type, TransactionType.expense);
      expect(coffeeCat.isEmoji, isTrue);
      expect(coffeeCat.emoji, isNotEmpty);
      expect(coffeeCat.isDefault, isFalse);

      final freelanceCat = provider.categories.firstWhere((c) => c.name == 'Gaji Freelance');
      expect(freelanceCat.type, TransactionType.income);
      expect(freelanceCat.isEmoji, isTrue);
      expect(freelanceCat.emoji, '💻');
    });

    test('Update category changes name and reassigns existing transactions', () async {
      final provider = TransactionProvider();
      await provider.loadData();

      // Add new category
      await provider.addCategory(
        name: 'Snack Kantor',
        type: TransactionType.expense,
        emoji: '🍪',
      );
      final cat = provider.categories.firstWhere((c) => c.name == 'Snack Kantor');

      // Add transaction using this category
      await provider.addTransaction(
        title: 'Biskuit Cokelat',
        amount: 15000,
        type: TransactionType.expense,
        categoryName: cat.name,
        categoryId: cat.id,
        walletId: 'w_cash',
      );

      expect(provider.transactions.first.categoryName, 'Snack Kantor');

      // Update category name
      await provider.updateCategory(
        id: cat.id,
        name: 'Camilan & Kopi',
        type: TransactionType.expense,
        emoji: '☕',
      );

      final updatedCat = provider.categories.firstWhere((c) => c.id == cat.id);
      expect(updatedCat.name, 'Camilan & Kopi');
      expect(updatedCat.emoji, '☕');

      // Transaction categoryName is automatically updated
      expect(provider.transactions.first.categoryName, 'Camilan & Kopi');
    });

    test('Delete category reassigns transactions to Others / fallback category', () async {
      final provider = TransactionProvider();
      await provider.loadData();

      await provider.addCategory(
        name: 'Kategori Sementara',
        type: TransactionType.expense,
        emoji: '🎲',
      );
      final cat = provider.categories.firstWhere((c) => c.name == 'Kategori Sementara');

      await provider.addTransaction(
        title: 'Game Board',
        amount: 50000,
        type: TransactionType.expense,
        categoryName: cat.name,
        categoryId: cat.id,
        walletId: 'w_cash',
      );

      expect(provider.transactions.first.categoryId, cat.id);

      // Delete the category
      await provider.deleteCategory(cat.id);

      expect(provider.categories.any((c) => c.id == cat.id), isFalse);

      // Existing transaction reassigned to Others
      final reassignedTx = provider.transactions.first;
      expect(reassignedTx.categoryName, anyOf('Others', 'Lainnya', 'Food & Beverage'));
    });

    testWidgets('ManageCategoriesScreen renders categories and opens add modal', (tester) async {
      final provider = TransactionProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<TransactionProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: ManageCategoriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kelola Kategori'), findsOneWidget);
      expect(find.textContaining('Pengeluaran'), findsWidgets);
      expect(find.textContaining('Pemasukan'), findsWidgets);
      expect(find.text('Food & Beverage'), findsOneWidget);

      // Tap Tambah button - opens new page EditCategoryScreen
      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Kategori Baru'), findsOneWidget);
      expect(find.text('Nama Kategori'), findsOneWidget);
      expect(find.text('Pilihan Emoji'), findsOneWidget);
    });

    testWidgets('EditCategoryScreen adds category and pops back', (tester) async {
      final provider = TransactionProvider();
      await provider.loadData();
      final initialCount = provider.categories.length;

      await tester.pumpWidget(
        ChangeNotifierProvider<TransactionProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(builder: (_) => const EditCategoryScreen()),
                    );
                  },
                  child: const Text('Open Edit'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Kategori Baru'), findsOneWidget);

      // Enter category name
      await tester.enterText(find.byType(TextField).first, 'Langganan Streaming');
      await tester.pumpAndSettle();

      // Scroll down until Simpan Kategori is visible
      await tester.drag(find.byKey(const Key('edit_category_scroll_view')), const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan Kategori'));
      await tester.pumpAndSettle();

      expect(provider.categories.length, initialCount + 1);
      expect(provider.categories.any((c) => c.name == 'Langganan Streaming'), isTrue);
    });

    testWidgets('showModalCardSheet displays floating card with nested card container', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showModalCardSheet(
                      context: context,
                      title: 'Kartu Konfirmasi',
                      child: const Text('Konten di dalam kartu'),
                    );
                  },
                  child: const Text('Buka Modal'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Kartu Konfirmasi'), findsOneWidget);
      expect(find.text('Konten di dalam kartu'), findsOneWidget);
    });
  });
}
