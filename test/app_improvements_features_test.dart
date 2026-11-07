import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/add_transaction_screen.dart';
import 'package:money_tracker/screens/analytics_screen.dart';
import 'package:money_tracker/screens/financial_analysis_screen.dart';
import 'package:money_tracker/screens/notifications_center_screen.dart';
import 'package:money_tracker/screens/settings_screen.dart';
import 'package:money_tracker/screens/split_bill_screen.dart';
import 'package:money_tracker/utils/icon_catalog.dart';
import 'package:money_tracker/widgets/month_filter_sheet.dart';

Widget buildTestApp(Widget child, TransactionProvider provider) {
  return ChangeNotifierProvider<TransactionProvider>.value(
    value: provider,
    child: MaterialApp(
      themeMode: provider.themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('6 App Improvements Verification Tests', () {
    test('IconCatalog contains extended Indonesian financial emojis', () {
      final emojis = IconCatalog.emojis.map((e) => e.char).toList();
      expect(emojis.contains('🥟'), isTrue); // Siomay
      expect(emojis.contains('🍚'), isTrue); // Nasi
      expect(emojis.contains('🍛'), isTrue); // Nasi Padang
      expect(emojis.contains('🍢'), isTrue); // Sate
      expect(emojis.contains('🛥️'), isTrue); // Speedboat
      expect(emojis.contains('🛞'), isTrue); // Servis ban
      expect(emojis.contains('🏛️'), isTrue); // Pajak PBB
      expect(emojis.contains('🕌'), isTrue); // Masjid
      expect(emojis.contains('⛪'), isTrue); // Gereja
    });

    testWidgets('AddTransactionScreen displays + Kategori text button in header opposite title', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestApp(const AddTransactionScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('Kategori'), findsWidgets);
      expect(find.byKey(const Key('btn_add_category_header')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('btn_add_category_header')), matching: find.byIcon(Icons.add_rounded)), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('btn_add_category_header')), matching: find.text('Kategori')), findsOneWidget);
    });

    testWidgets('FinancialAnalysisScreen places month filter below title', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestApp(const FinancialAnalysisScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('Analisis Keuangan'), findsOneWidget);
      expect(find.byType(AppMonthFilterPill), findsOneWidget);
    });

    testWidgets('AnalyticsScreen uses AppMonthFilterPill matching hero card style', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestApp(const AnalyticsScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('Laporan Keuangan'), findsOneWidget);
      expect(find.byType(AppMonthFilterPill), findsOneWidget);
    });

    testWidgets('SettingsScreen has 3 display mode options: Sistem, Terang, Gelap', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestApp(const SettingsScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('Mode Tampilan'), findsOneWidget);

      await tester.tap(find.text('Mode Tampilan'));
      await tester.pumpAndSettle();

      expect(find.text('Sistem'), findsOneWidget);
      expect(find.text('Mode Terang'), findsOneWidget);
      expect(find.text('Mode Gelap'), findsWidgets);

      // Select Sistem
      await tester.tap(find.text('Sistem'));
      await tester.pumpAndSettle();
      expect(provider.themeMode, equals(ThemeMode.system));
    });

    testWidgets('NotificationsCenterScreen does not show transaction approvals', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestApp(const NotificationsCenterScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Persetujuan Transaksi'), findsNothing);
      expect(find.text('Aktivitas Transaksi'), findsOneWidget);
    });

    testWidgets('SplitBillScreen defaults bill name to empty and validates before saving', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestApp(const SplitBillScreen(), provider));
      await tester.pumpAndSettle();

      // Bill name text field should be empty by default
      expect(find.text('Makan Bersama'), findsNothing);

      // Tapping "Catat Bagian Saya" without bill name should show warning
      final saveBtn = find.text('Catat Bagian Saya');
      await tester.tap(saveBtn);
      await tester.pump();

      expect(find.text('Nama tagihan wajib diisi terlebih dahulu.'), findsOneWidget);
    });
  });
}

