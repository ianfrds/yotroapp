import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:money_tracker/config/supabase_config.dart';
import 'package:money_tracker/models/budget_model.dart';
import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/models/wallet_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/settings_screen.dart';
import 'package:money_tracker/services/supabase_auth_service.dart';

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
        home: Scaffold(body: child),
      ),
    );
  }

  group('Supabase Configuration & Graceful Fallback Tests', () {
    test('SupabaseConfig defaults to project njjcviwihzvzjgfbzitg', () {
      expect(SupabaseConfig.defaultProjectRef, 'njjcviwihzvzjgfbzitg');
      expect(SupabaseConfig.defaultUrl, 'https://njjcviwihzvzjgfbzitg.supabase.co');
      expect(SupabaseConfig.supabaseUrl, contains('njjcviwihzvzjgfbzitg'));
    });

    test('SupabaseConfig handles unconfigured state without throwing', () async {
      final initialized = await SupabaseConfig.initialize(customAnonKey: '');
      // When customAnonKey is empty, it safely reports false and keeps app in offline mode
      expect(initialized, isFalse);
      expect(SupabaseConfig.isInitialized, isFalse);
    });

    test('TransactionProvider applies cloud snapshot and saves lastCloudSyncTime', () async {
      final provider = TransactionProvider();
      await provider.loadData();

      final cloudWallets = [
        WalletModel(id: 'w_cloud', name: 'Cloud Bank', type: 'Bank Account', balance: 750000.0),
      ];
      final cloudTx = [
        TransactionModel(
          id: 'tx_cloud_1',
          title: 'Cloud Transaction',
          amount: 50000.0,
          type: TransactionType.income,
          categoryId: 'salary',
          categoryName: 'Gaji',
          walletId: 'w_cloud',
          timestamp: DateTime.now(),
        ),
      ];
      final cloudBudget = BudgetModel(
        overallMonthlyLimit: 2500000.0,
        categoryBudgets: {'food': 500000.0},
      );

      provider.applyCloudSnapshot(
        wallets: cloudWallets,
        transactions: cloudTx,
        budget: cloudBudget,
      );

      expect(provider.wallets.any((w) => w.id == 'w_cloud'), isTrue);
      expect(provider.transactions.any((t) => t.id == 'tx_cloud_1'), isTrue);
      expect(provider.budget.overallMonthlyLimit, 2500000.0);
      expect(provider.lastCloudSyncTime, isNotNull);
    });

    test('SupabaseAuthService password management tests', () async {
      // updatePassword throws StateError when not authenticated
      expect(
        () => SupabaseAuthService.updatePassword('newPassword123'),
        throwsA(isA<StateError>()),
      );

      // formatAuthException handles password messages
      expect(
        SupabaseAuthService.formatAuthException(
          const AuthException('Password should be at least 6 characters'),
        ),
        'Kata sandi minimal 6 karakter.',
      );
      expect(
        SupabaseAuthService.formatAuthException(
          const AuthException('New password should be different from the old password'),
        ),
        'Kata sandi baru harus berbeda dari kata sandi lama.',
      );
    });
  });

  group('SettingsScreen Cloud UI Tests', () {
    testWidgets('Renders Sinkronisasi Cloud card without exposed credentials settings', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.loadData();

      await tester.pumpWidget(buildTestWidget(
        child: const SettingsScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Sinkronisasi Cloud'), findsOneWidget);
      expect(find.text('Sinkronisasi Cloud (Supabase)'), findsNothing);
      expect(find.text('Mode Offline (Lokal)'), findsOneWidget);
      expect(find.text('Masuk dengan Google'), findsOneWidget);
      expect(find.byTooltip('Pengaturan Kredensial Supabase'), findsNothing);
      expect(find.text('Ganti Kata Sandi'), findsNothing);
      expect(find.text('Database:'), findsNothing);
      expect(find.text('Privasi:'), findsNothing);
      expect(find.text('Lisensi:'), findsNothing);
    });

    testWidgets('Delete account sheet displays Akun Yotro branding', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.loadData();

      await tester.pumpWidget(buildTestWidget(
        child: const SettingsScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      final deleteRow = find.text('Hapus Akun Pengguna');
      await tester.scrollUntilVisible(deleteRow, 300);
      await tester.pumpAndSettle();
      expect(deleteRow, findsOneWidget);
      expect(find.textContaining('Hapus akun Yotro'), findsOneWidget);
      expect(find.textContaining('Hapus akun Supabase'), findsNothing);

      await tester.tap(deleteRow);
      await tester.pumpAndSettle();

      expect(find.text('Hapus Akun Yotro?'), findsOneWidget);
      expect(find.textContaining('Akun Yotro Anda'), findsOneWidget);
      expect(find.textContaining('Akun Supabase'), findsNothing);
    });
  });
}
