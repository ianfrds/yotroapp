import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/models/voice_transaction_item.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/add_transaction_screen.dart';
import 'package:money_tracker/widgets/circular_spectrum_visualizer.dart';
import 'package:money_tracker/widgets/voice_multi_item_summary_sheet.dart';
import 'package:money_tracker/widgets/voice_recording_sheet.dart';

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

  group('CircularSpectrumVisualizer Tests', () {
    testWidgets('renders animated radial visualizer and mic icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularSpectrumVisualizer(
                isListening: true,
                soundLevel: 0.5,
                onCenterTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularSpectrumVisualizer), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('shows mic_off_rounded when isListening is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularSpectrumVisualizer(
                isListening: false,
                soundLevel: 0.0,
                onCenterTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.mic_off_rounded), findsOneWidget);
    });
  });

  group('VoiceMultiItemSummarySheet Tests', () {
    testWidgets('renders vertical list of 4 items with total, and allows edit', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final items = [
        const VoiceTransactionItem(title: 'Siomay', amount: 13000, suggestedCategory: 'Makanan & Minuman'),
        const VoiceTransactionItem(title: 'Tahu Tek', amount: 100000, suggestedCategory: 'Makanan & Minuman'),
        const VoiceTransactionItem(title: 'Keyboard', amount: 500000, suggestedCategory: 'Belanja'),
        const VoiceTransactionItem(title: 'HP', amount: 1000000, suggestedCategory: 'Belanja'),
      ];

      bool retryCalled = false;
      List<VoiceTransactionItem>? savedBatch;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  VoiceMultiItemSummarySheet.show(
                    context: ctx,
                    items: items,
                    onRetryRecording: () => retryCalled = true,
                    onSaveAll: (confirmed) => savedBatch = confirmed,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Ringkasan Transaksi Suara'), findsOneWidget);
      expect(find.text('4 item terdeteksi • Total: Rp 1.613.000'), findsOneWidget);
      expect(find.text('Siomay'), findsOneWidget);
      expect(find.text('Tahu Tek'), findsOneWidget);
      expect(find.text('Keyboard'), findsOneWidget);
      expect(find.text('HP'), findsOneWidget);

      // Verify buttons
      expect(find.byKey(const Key('btn_retry_speech')), findsOneWidget);
      expect(find.byKey(const Key('btn_save_all_speech')), findsOneWidget);

      // Tap on Tahu Tek to edit
      await tester.tap(find.byKey(const Key('item_card_1')));
      await tester.pumpAndSettle();

      expect(find.text('Koreksi Transaksi'), findsOneWidget);
      // Change nominal from 100000 to 10000
      await tester.enterText(find.widgetWithText(TextField, '100000'), '10000');
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      // Total now should be 13k + 10k + 500k + 1M = 1.523.000
      expect(find.text('4 item terdeteksi • Total: Rp 1.523.000'), findsOneWidget);

      // Tap Catat Semua
      await tester.tap(find.byKey(const Key('btn_save_all_speech')));
      await tester.pumpAndSettle();

      expect(savedBatch, isNotNull);
      expect(savedBatch!.length, 4);
      expect(savedBatch![1].amount, 10000.0);
    });

    testWidgets('Bicara Ulang triggers onRetryRecording callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final items = [
        const VoiceTransactionItem(title: 'Siomay', amount: 13000, suggestedCategory: 'Makanan & Minuman'),
        const VoiceTransactionItem(title: 'Tahu Tek', amount: 100000, suggestedCategory: 'Makanan & Minuman'),
      ];

      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  VoiceMultiItemSummarySheet.show(
                    context: ctx,
                    items: items,
                    onRetryRecording: () => retryCalled = true,
                    onSaveAll: (_) {},
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_retry_speech')));
      await tester.pumpAndSettle();

      expect(retryCalled, isTrue);
    });
  });

  group('VoiceRecordingSheet Integration with AddTransactionScreen Tests', () {
    testWidgets('tapping 1-item simulator chip fills AddTransactionScreen directly', (tester) async {
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

      // Tap Mic
      await tester.tap(find.byKey(const Key('btn_voice_input')));
      await tester.pumpAndSettle();

      expect(find.text('Perekam Transaksi Suara'), findsOneWidget);

      // Tap 1-item chip
      await tester.tap(find.byKey(const Key('chip_sim_single_item')));
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      // Form is populated
      expect(find.text('Kopi Kenangan'), findsWidgets);
      expect(find.textContaining('25'), findsWidgets);
    });

    testWidgets('tapping 4-item simulator chip opens VoiceMultiItemSummarySheet', (tester) async {
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

      // Tap Mic
      await tester.tap(find.byKey(const Key('btn_voice_input')));
      await tester.pumpAndSettle();

      // Tap 4-item chip
      await tester.tap(find.byKey(const Key('chip_sim_multi_item')));
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      // Multi-item summary sheet opens
      expect(find.text('Ringkasan Transaksi Suara'), findsOneWidget);
      expect(find.text('Siomay'), findsOneWidget);
      expect(find.text('Tahu Tek'), findsOneWidget);
      expect(find.text('Keyboard'), findsOneWidget);
      expect(find.text('HP'), findsOneWidget);
      expect(find.byKey(const Key('btn_save_all_speech')), findsOneWidget);
    });
  });
}

