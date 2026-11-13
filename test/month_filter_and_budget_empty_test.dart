import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/models/budget_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/budget_screen.dart';
import 'package:money_tracker/widgets/month_filter_sheet.dart';

Widget buildTestApp(Widget child, TransactionProvider provider) {
  return ChangeNotifierProvider<TransactionProvider>.value(
    value: provider,
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Month Filter Bottom Sheet Tests', () {
    testWidgets('AppMonthFilterPill opens bottom sheet and updates selected month', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestApp(
        Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => Consumer<TransactionProvider>(
                builder: (context, prov, _) => AppMonthFilterPill(
                  selectedDate: prov.selectedDashboardMonth,
                  isHeroCard: true,
                  onTap: () {
                    showAppMonthFilterSheet(
                      context: context,
                      initialDate: prov.selectedDashboardMonth,
                      onSelected: (date) => prov.setSelectedDashboardMonth(date),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        provider,
      ));
      await tester.pumpAndSettle();

      // Find the month filter pill in the hero card
      final monthFinder = find.textContaining('${DateTime.now().year}');
      expect(monthFinder, findsWidgets);

      // Tap on the month filter pill
      await tester.tap(monthFinder.first);
      await tester.pumpAndSettle();

      // Expect bottom sheet "Filter Bulanan" to open
      expect(find.text('Filter Bulanan'), findsOneWidget);
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Des'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);

      // Tap on 'Des'
      await tester.tap(find.text('Des'));
      await tester.pumpAndSettle();

      // Tap 'Simpan'
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Verify sheet is dismissed and provider month updated to 12
      expect(find.text('Filter Bulanan'), findsNothing);
      expect(provider.selectedDashboardMonth.month, equals(12));

      // Reopen sheet and test "Bulan Ini" button
      await tester.tap(monthFinder.first);
      await tester.pumpAndSettle();
      expect(find.text('Bulan Ini'), findsOneWidget);
      await tester.tap(find.text('Bulan Ini'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(provider.selectedDashboardMonth.month, equals(DateTime.now().month));
    });
  });

  group('BudgetScreen Empty State Tests', () {
    testWidgets('BudgetScreen shows empty state and no overall budget card when budget is zero', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      // Clear budgets
      await provider.updateOverallBudget(0.0);
      for (final cat in provider.budget.categoryBudgets.keys.toList()) {
        await provider.deleteCategoryBudget(cat);
      }
      expect(provider.budget.overallMonthlyLimit, equals(0.0));
      expect(provider.budget.categoryBudgets, isEmpty);

      await tester.pumpWidget(buildTestApp(const BudgetScreen(), provider));
      await tester.pumpAndSettle();

      // Verify Empty State is shown
      expect(find.text('Belum Ada Anggaran'), findsOneWidget);
      expect(find.text('Atur Anggaran Bulanan'), findsOneWidget);
      expect(find.text('Tambah Budget Kategori'), findsOneWidget);

      // Verify 'Batas Budget Keseluruhan' card is NOT shown
      expect(find.text('Batas Budget Keseluruhan'), findsNothing);
    });
  });
}

