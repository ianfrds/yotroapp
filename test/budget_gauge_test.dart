import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/budget_screen.dart';
import 'package:money_tracker/widgets/semicircle_budget_gauge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SemicircleBudgetGauge Widget Tests', () {
    testWidgets('renders semicircle gauge with remaining, total, and spent values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SemicircleBudgetGauge(
              remainingBudget: 615250,
              totalBudget: 1000000,
              spentAmount: 384750,
              formattedRemaining: 'Rp 615.250',
              formattedTotal: 'Rp 1.000.000',
              formattedSpent: 'Rp 384.750',
              usagePercentage: 38.5,
              isOver: false,
              isWarn: false,
              dateRange: '01/10/2024 - 31/10/2024',
              daysRemaining: 14,
            ),
          ),
        ),
      );

      expect(find.text('01/10/2024 - 31/10/2024'), findsOneWidget);
      expect(find.text('Anggaran Tersisa'), findsOneWidget);
      expect(find.text('Rp 615.250'), findsOneWidget);
      expect(find.text('14 Hari Lagi'), findsOneWidget);
      expect(find.text('Total Anggaran'), findsOneWidget);
      expect(find.text('Rp 1.000.000'), findsOneWidget);
      expect(find.text('Terpakai'), findsOneWidget);
      expect(find.text('Rp 384.750'), findsOneWidget);
    });

    testWidgets('BudgetScreen renders linear progress bar inside overall budget card without date range', (WidgetTester tester) async {
      final provider = TransactionProvider();
      await provider.updateOverallBudget(2500000);

      await tester.pumpWidget(
        ChangeNotifierProvider<TransactionProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: BudgetScreen(isStandalonePage: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SemicircleBudgetGauge), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsWidgets);
      expect(find.text('Batas Budget Keseluruhan'), findsOneWidget);
      expect(find.text('dari Rp 2.500.000'), findsOneWidget);
      expect(find.textContaining('Sisa: Rp 2.500.000'), findsOneWidget);
      expect(find.text('14 Hari Lagi'), findsNothing);
    });
  });
}
