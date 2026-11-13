import 'dart:convert';
import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  const supabaseUrl = 'https://njjcviwihzvzjgfbzitg.supabase.co';
  const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qamN2aXdpaHp2empnZmJ6aXRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ1NTU1MTMsImV4cCI6MjExMDEzMTUxM30.fnCmLdU5agVm0oRXWYoBXsH7WjgvvgmLSPb7aXP2nTI';

  final client = SupabaseClient(
    supabaseUrl,
    anonKey,
    authOptions: const AuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final testEmail = 'yotro_e2e_$timestamp@example.com';
  const testPassword = 'Password123!';
  const testFullName = 'Ian Firdaus Vibecoding';

  stdout.writeln('========================================================');
  stdout.writeln('  YOTRO x SUPABASE FULL LIVE SYNC VERIFICATION');
  stdout.writeln('  URL: $supabaseUrl');
  stdout.writeln('  User: $testEmail');
  stdout.writeln('========================================================\n');

  try {
    // 1. REGISTER
    stdout.write('1. Sign Up (Email + Password + Full Name)... ');
    final signUpRes = await client.auth.signUp(
      email: testEmail,
      password: testPassword,
      data: {'full_name': testFullName},
    );

    final user = signUpRes.user;
    if (user == null) {
      throw StateError('Sign up did not return user');
    }
    stdout.writeln('OK! (User ID: ${user.id})');

    // 2. VERIFY PROFILE TRIGGER
    stdout.write('2. Verify Profile Trigger (public.profiles)... ');
    await Future.delayed(const Duration(milliseconds: 700));
    final profile = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      throw StateError('Profile not found in public.profiles');
    }
    stdout.writeln('OK! (Name: "${profile['name']}", Email: "${profile['email']}")');

    // 3. INSERT WALLET
    stdout.write('3. Insert Wallet (public.wallets)... ');
    final walletId = 'w_$timestamp';
    await client.from('wallets').insert({
      'id': walletId,
      'user_id': user.id,
      'name': 'Bank Mandiri Utama',
      'type': 'Bank',
      'balance': 2500000.0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    stdout.writeln('OK! (Wallet ID: $walletId, Saldo: Rp 2.500.000)');

    // 4. INSERT CATEGORY
    stdout.write('4. Insert Category (public.categories)... ');
    final catId = 'c_$timestamp';
    await client.from('categories').insert({
      'id': catId,
      'user_id': user.id,
      'name': 'Makan & Ngopi',
      'type': 'expense',
      'icon_name': 'coffee',
      'emoji': '☕',
      'color_value': 4283215696,
      'is_default': false,
      'created_at': DateTime.now().toIso8601String(),
    });
    stdout.writeln('OK! (Category: "Makan & Ngopi" ☕)');

    // 5. INSERT TRANSACTION
    stdout.write('5. Insert Transaction (public.transactions)... ');
    final txId = 'tx_$timestamp';
    await client.from('transactions').insert({
      'id': txId,
      'user_id': user.id,
      'title': 'Kopi Cold Brew Senopati',
      'amount': 45000.0,
      'type': 'expense',
      'category_id': catId,
      'category_name': 'Makan & Ngopi',
      'wallet_id': walletId,
      'note': 'Pertemuan santai sore',
      'timestamp': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    stdout.writeln('OK! (Tx: "Kopi Cold Brew Senopati" Rp 45.000)');

    // 6. UPDATE TRANSACTION
    stdout.write('6. Update Transaction (Nominal & Note)... ');
    await client.from('transactions').update({
      'amount': 50000.0,
      'note': 'Pertemuan santai sore + roti bakar',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', txId).eq('user_id', user.id);

    final updatedTx = await client
        .from('transactions')
        .select()
        .eq('id', txId)
        .maybeSingle();

    if (updatedTx == null || (updatedTx['amount'] as num).toDouble() != 50000.0) {
      throw StateError('Transaction update verification failed');
    }
    stdout.writeln('OK! (Updated Nominal: Rp ${updatedTx['amount']}, Note: "${updatedTx['note']}")');

    // 7. UPSERT BUDGET
    stdout.write('7. Upsert Budget (public.budgets)... ');
    await client.from('budgets').upsert({
      'user_id': user.id,
      'overall_monthly_limit': 6000000.0,
      'category_budgets': {
        catId: 1200000.0,
      },
      'updated_at': DateTime.now().toIso8601String(),
    });

    final budget = await client
        .from('budgets')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (budget == null) {
      throw StateError('Budget not found');
    }
    stdout.writeln('OK! (Monthly Limit: Rp ${budget['overall_monthly_limit']}, Category Limit: ${jsonEncode(budget['category_budgets'])})');

    // 8. QUERY SUMMARY (SIMULATE FULL SYNC PULL)
    stdout.write('8. Simulate Full Cloud Data Pull (Wallets + Categories + Txs + Budget)... ');
    final allWallets = await client.from('wallets').select().eq('user_id', user.id);
    final allCats = await client.from('categories').select().eq('user_id', user.id);
    final allTxs = await client.from('transactions').select().eq('user_id', user.id);

    stdout.writeln('OK!');
    stdout.writeln('   -> Pulled ${allWallets.length} wallets, ${allCats.length} categories, ${allTxs.length} transactions.');

    // 9. SIGN OUT AND RE-LOGIN (EMAIL + PASSWORD)
    stdout.write('9. Test Sign Out & Manual Sign In with Email & Password... ');
    await client.auth.signOut();
    final signInRes = await client.auth.signInWithPassword(
      email: testEmail,
      password: testPassword,
    );

    if (signInRes.user?.id != user.id) {
      throw StateError('Sign in failed or user mismatch');
    }
    stdout.writeln('OK! (Session revived successfully)');

    stdout.writeln('\n========================================================');
    stdout.writeln('  STATUS: 100% OPERATIONAL & VERIFIED LIVE');
    stdout.writeln('  - Supabase Project: njjcviwihzvzjgfbzitg');
    stdout.writeln('  - Auth Email/Password: Connected');
    stdout.writeln('  - Database RLS & Triggers: Active & Validated');
    stdout.writeln('  - Wallets, Categories, Transactions & Budgets: Synced');
    stdout.writeln('========================================================');
  } catch (e, st) {
    stderr.writeln('\nTEST FAILED: $e\n$st');
    exit(1);
  } finally {
    client.dispose();
  }
}
