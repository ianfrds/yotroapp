import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/dashboard_screen.dart';
import 'package:money_tracker/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(Widget child, TransactionProvider provider) {
    return ChangeNotifierProvider<TransactionProvider>.value(
      value: provider,
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('DashboardScreen & SettingsScreen Balance View Verification', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Dashboard shows Saldo saat ini, Pengeluaran, and Pemasukan on Complete View', (tester) async {
      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestableWidget(const DashboardScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('Saldo saat ini'), findsOneWidget);
      expect(find.text('Pengeluaran'), findsOneWidget);
      expect(find.text('Pemasukan'), findsOneWidget);
    });

    testWidgets('Dashboard hides Saldo saat ini but shows Pengeluaran and Pemasukan on incomeExpense mode', (tester) async {
      final provider = TransactionProvider();
      provider.setDashboardViewMode(DashboardViewMode.incomeExpense);

      await tester.pumpWidget(buildTestableWidget(const DashboardScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('Saldo saat ini'), findsNothing);
      expect(find.text('Pengeluaran'), findsOneWidget);
      expect(find.text('Pemasukan'), findsOneWidget);
    });

    testWidgets('Dashboard shows only Pengeluaran on expenseOnly mode', (tester) async {
      final provider = TransactionProvider();
      provider.setDashboardViewMode(DashboardViewMode.expenseOnly);

      await tester.pumpWidget(buildTestableWidget(const DashboardScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('Saldo saat ini'), findsNothing);
      expect(find.text('Total Pengeluaran'), findsOneWidget);
      expect(find.text('Pemasukan'), findsNothing);
    });

    testWidgets('Dashboard masks nominals when isBalanceVisible is toggled off', (tester) async {
      final provider = TransactionProvider();
      provider.toggleBalanceVisibility();

      await tester.pumpWidget(buildTestableWidget(const DashboardScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('Saldo saat ini'), findsOneWidget);
      expect(find.text('Rp ••••••••'), findsOneWidget);
      expect(find.text('Rp ••••••'), findsNWidgets(2));
    });

    testWidgets('SettingsScreen displays Preferensi Tampilan and opens bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();

      await tester.pumpWidget(buildTestableWidget(const SettingsScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('Preferensi Tampilan'), findsOneWidget);
      expect(find.text('Complete View'), findsWidgets);

      // Tap row to open bottom sheet
      await tester.tap(find.text('Preferensi Tampilan'));
      await tester.pumpAndSettle();

      // Check all 3 options on bottom sheet
      expect(find.text('Pemasukan dan Pengeluaran'), findsOneWidget);
      expect(find.text('Pengeluaran saja'), findsOneWidget);

      // Select 'Pengeluaran saja' and save
      await tester.tap(find.text('Pengeluaran saja'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan Preferensi'));
      await tester.pumpAndSettle();

      expect(provider.dashboardViewMode, equals(DashboardViewMode.expenseOnly));
    });
  });
}

