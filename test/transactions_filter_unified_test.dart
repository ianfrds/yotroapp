import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/transactions_screen.dart';

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

  group('TransactionsScreen Unified Time Filter Tests', () {
    testWidgets('Opens filter bottom sheet and switches between tabs, applies month/year, date, and range', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestApp(const TransactionsScreen(), provider));
      await tester.pumpAndSettle();

      // Verify screen title
      expect(find.text('Riwayat Transaksi'), findsOneWidget);

      // Verify time filter button defaults to 'Semua Periode (Tahun / Bulan / Tanggal / Rentang)'
      expect(find.textContaining('Semua Periode'), findsOneWidget);

      // Tap on time filter trigger
      await tester.tap(find.textContaining('Semua Periode'));
      await tester.pumpAndSettle();

      // Expect unified bottom sheet
      expect(find.text('Filter Periode Transaksi'), findsOneWidget);
      expect(find.text('Bulan & Tahun'), findsOneWidget);
      expect(find.text('Tanggal'), findsOneWidget);
      expect(find.text('Rentang Tanggal'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);

      // Verify 12 month grid items exist
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Des'), findsOneWidget);

      // Tap on 'Tanggal' tab
      await tester.tap(find.text('Tanggal'));
      await tester.pumpAndSettle();

      // Verify calendar is shown
      expect(find.byType(CalendarDatePicker), findsOneWidget);

      // Switch to 'Rentang Tanggal'
      await tester.tap(find.text('Rentang Tanggal'));
      await tester.pumpAndSettle();

      // Verify range presets
      expect(find.text('7 Hari'), findsOneWidget);
      expect(find.text('30 Hari'), findsOneWidget);
      expect(find.text('Bulan Ini'), findsOneWidget);
      expect(find.text('Buka Kalender Rentang'), findsOneWidget);

      // Tap 'Bulan Ini'
      await tester.tap(find.text('Bulan Ini'));
      await tester.pumpAndSettle();

      // Tap 'Simpan'
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Verify bottom sheet is dismissed and button shows 'Rentang:'
      expect(find.text('Filter Periode Transaksi'), findsNothing);
      expect(find.textContaining('Rentang:'), findsOneWidget);

      // Tap Reset Filter
      expect(find.text('Reset Filter'), findsOneWidget);
      await tester.tap(find.text('Reset Filter'));
      await tester.pumpAndSettle();

      // Verify reverted to 'Semua Periode'
      expect(find.textContaining('Semua Periode'), findsOneWidget);

      // Now test Bulan & Tahun tab selection
      await tester.tap(find.textContaining('Semua Periode'));
      await tester.pumpAndSettle();

      expect(find.text('Filter Periode Transaksi'), findsOneWidget);
      // Tap on 'Pilih 1 Tahun Penuh'
      await tester.tap(find.textContaining('Pilih 1 Tahun Penuh'));
      await tester.pumpAndSettle();

      // Tap Simpan
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tahun:'), findsOneWidget);

      // Reset
      await tester.tap(find.text('Reset Filter'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Semua Periode'), findsOneWidget);
    });
  });
}
