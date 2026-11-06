import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/models/receipt_data_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/add_transaction_screen.dart';
import 'package:money_tracker/widgets/receipt_adjustment_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget({required Widget child, TransactionProvider? provider}) {
    final prov = provider ?? TransactionProvider();
    return ChangeNotifierProvider<TransactionProvider>.value(
      value: prov,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('AddTransactionScreen 3-Button Action Bar Tests', () {
    testWidgets('renders 3-button bottom bar: Camera, Simpan Transaksi, Mic', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.loadData();

      await tester.pumpWidget(buildTestWidget(
        child: const AddTransactionScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      // Find Camera button (Left)
      expect(find.byKey(const Key('btn_scan_receipt')), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);

      // Find Simpan Transaksi button (Middle)
      expect(find.byKey(const Key('btn_save_transaction')), findsOneWidget);
      expect(find.text('Simpan Transaksi'), findsOneWidget);

      // Find Microphone button (Right)
      expect(find.byKey(const Key('btn_voice_input')), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    });

    testWidgets('tapping Mic button displays voice note info snackbar', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.loadData();

      await tester.pumpWidget(buildTestWidget(
        child: const AddTransactionScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_voice_input')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Fitur input suara akan hadir di pembaruan berikutnya'), findsOneWidget);
    });

    testWidgets('tapping Camera button opens OCR source bottom sheet with Kamera & Galeri', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.loadData();

      await tester.pumpWidget(buildTestWidget(
        child: const AddTransactionScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_scan_receipt')));
      await tester.pumpAndSettle();

      expect(find.text('Pindai Struk Belanja (OCR)'), findsOneWidget);
      expect(find.byKey(const Key('btn_pick_camera')), findsOneWidget);
      expect(find.byKey(const Key('btn_pick_gallery')), findsOneWidget);
    });
  });

  group('ReceiptAdjustmentSheet Tests', () {
    testWidgets('renders receipt adjustment sheet with parsed data, alternative chips, and actions', (tester) async {
      final receiptData = ReceiptDataModel(
        totalAmount: 52800.0,
        alternativeAmounts: const [48000.0, 4800.0],
        merchantName: 'Kopi Kenangan Central Park',
        date: DateTime(2026, 11, 6),
        suggestedCategory: 'Makanan & Minuman',
      );

      ReceiptDataModel? approvedData;
      ReceiptDataModel? formAppliedData;

      final provider = TransactionProvider();
      await provider.loadData();

      await tester.pumpWidget(buildTestWidget(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              ReceiptAdjustmentSheet.show(
                context,
                receiptData: receiptData,
                onApproveAndSave: (data, walletId) => approvedData = data,
                onApplyToForm: (data, walletId) => formAppliedData = data,
              );
            },
            child: const Text('Buka Sheet'),
          ),
        ),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Hasil Pindai Struk'), findsOneWidget);
      expect(find.text('52.800'), findsOneWidget);
      expect(find.text('Kopi Kenangan Central Park'), findsOneWidget);
      expect(find.text('Makanan & Minuman'), findsWidgets);

      // Verify alternative amount chip
      expect(find.text('Rp 48.000'), findsOneWidget);
      await tester.tap(find.text('Rp 48.000'));
      await tester.pumpAndSettle();
      expect(find.text('48.000'), findsOneWidget);

      // Verify Buka di Form button
      expect(find.byKey(const Key('btn_receipt_apply_form')), findsOneWidget);
      expect(find.byKey(const Key('btn_receipt_approve_save')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_receipt_approve_save')));
      await tester.pumpAndSettle();

      expect(approvedData, isNotNull);
      expect(approvedData!.totalAmount, 48000.0);
      expect(approvedData!.merchantName, 'Kopi Kenangan Central Park');
    });
  });
}

