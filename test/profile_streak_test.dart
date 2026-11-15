import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/settings_screen.dart';

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

  group('Recording Streak Calculation Tests', () {
    test('Zero transactions has 0 streak', () {
      final provider = TransactionProvider();
      expect(provider.recordingStreak, equals(0));
    });

    test('Transaction today gives 1 streak', () async {
      final provider = TransactionProvider();
      await provider.addTransaction(
        title: 'Kopi Pagi',
        amount: 20000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'makanan_minuman',
        walletId: 'w_bank',
        date: DateTime.now(),
      );
      expect(provider.recordingStreak, equals(1));
    });

    test('Transaction yesterday only gives 1 active streak', () async {
      final provider = TransactionProvider();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await provider.addTransaction(
        title: 'Makan Malam Kemarin',
        amount: 35000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'makanan_minuman',
        walletId: 'w_bank',
        date: yesterday,
      );
      expect(provider.recordingStreak, equals(1));
    });

    test('Consecutive transactions today, yesterday, and 2 days ago give 3 streak', () async {
      final provider = TransactionProvider();
      final now = DateTime.now();

      await provider.addTransaction(
        title: 'Hari Ini',
        amount: 15000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'makanan_minuman',
        walletId: 'w_bank',
        date: now,
      );

      await provider.addTransaction(
        title: 'Kemarin',
        amount: 25000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'makanan_minuman',
        walletId: 'w_bank',
        date: now.subtract(const Duration(days: 1)),
      );

      await provider.addTransaction(
        title: '2 Hari Lalu',
        amount: 40000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'makanan_minuman',
        walletId: 'w_bank',
        date: now.subtract(const Duration(days: 2)),
      );

      expect(provider.recordingStreak, equals(3));
    });

    test('Transaction 2 days ago without yesterday breaks streak to 0', () async {
      final provider = TransactionProvider();
      final now = DateTime.now();

      await provider.addTransaction(
        title: '2 Hari Lalu Saja',
        amount: 50000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'makanan_minuman',
        walletId: 'w_bank',
        date: now.subtract(const Duration(days: 2)),
      );

      expect(provider.recordingStreak, equals(0));
    });

    test('Multiple transactions on the same day count as single day in streak', () async {
      final provider = TransactionProvider();
      final now = DateTime.now();

      await provider.addTransaction(
        title: 'Sarapan',
        amount: 10000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'makanan_minuman',
        walletId: 'w_bank',
        date: now,
      );

      await provider.addTransaction(
        title: 'Makan Siang',
        amount: 25000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'makanan_minuman',
        walletId: 'w_bank',
        date: now,
      );

      await provider.addTransaction(
        title: 'Makan Malam',
        amount: 30000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'makanan_minuman',
        walletId: 'w_bank',
        date: now,
      );

      expect(provider.recordingStreak, equals(1));
    });
  });

  group('SettingsScreen Profile Streak Widget Tests', () {
    testWidgets('Renders Streak bar with fire emoji and eliminates mini stats', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.addTransaction(
        title: 'Makan Siang',
        amount: 20000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'makanan_minuman',
        walletId: 'w_bank',
        date: DateTime.now(),
      );

      await tester.pumpWidget(buildTestApp(const SettingsScreen(), provider));
      await tester.pumpAndSettle();

      // Verify Anti-Slop Minimal Streak Row with clean vector icon
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
      expect(find.text('Streak Pencatatan'), findsOneWidget);
      expect(find.text('1 Hari'), findsOneWidget);

      // Verify redundant badges and cheerleader text are absent
      expect(find.text('Streak 🔥'), findsNothing);
      expect(find.textContaining('Hebat!'), findsNothing);

      // Verify mini stats are removed
      expect(find.text('catatan'), findsNothing);
      expect(find.text('rekening'), findsNothing);
      expect(find.text('keluar'), findsNothing);
    });
  });
}
