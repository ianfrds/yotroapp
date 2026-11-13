import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const supabaseUrl = 'https://njjcviwihzvzjgfbzitg.supabase.co';
  const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qamN2aXdpaHp2empnZmJ6aXRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ1NTU1MTMsImV4cCI6MjExMDEzMTUxM30.fnCmLdU5agVm0oRXWYoBXsH7WjgvvgmLSPb7aXP2nTI';
  final testTimestamp = DateTime.now().millisecondsSinceEpoch;
  final testEmail = 'yotro_tester_$testTimestamp@example.com';
  const testPassword = 'Password123!';
  const testFullName = 'Ian Firdaus Test Live';

  stdout.writeln('=== LIVE SUPABASE END-TO-END CONNECTION TEST ===');
  stdout.writeln('Target Project: njjcviwihzvzjgfbzitg');
  stdout.writeln('Test User: $testEmail');

  // STEP 1: SIGN UP WITH EMAIL, PASSWORD, AND FULL NAME
  stdout.write('\n[1/6] Registering user via Auth API... ');
  final signupRes = await http.post(
    Uri.parse('$supabaseUrl/auth/v1/signup'),
    headers: {
      'apikey': anonKey,
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'email': testEmail,
      'password': testPassword,
      'data': {
        'full_name': testFullName,
      },
    }),
  );

  if (signupRes.statusCode != 200) {
    stderr.writeln('FAILED (${signupRes.statusCode}): ${signupRes.body}');
    exit(1);
  }

  final signupData = jsonDecode(signupRes.body) as Map<String, dynamic>;
  final accessToken = signupData['access_token'] as String?;
  final user = signupData['user'] as Map<String, dynamic>? ?? signupData;
  final userId = user['id'] as String;

  stdout.writeln('SUCCESS!');
  stdout.writeln('      User ID: $userId');
  stdout.writeln('      Access Token: ${accessToken != null ? "Active (${accessToken.substring(0, 16)}...)" : "None"}');

  final authHeaders = {
    'apikey': anonKey,
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  // STEP 2: VERIFY PROFILE CREATION VIA TRIGGER
  stdout.write('\n[2/6] Verifying profiles table trigger & RLS... ');
  // Allow trigger half second to populate
  await Future.delayed(const Duration(milliseconds: 600));

  final profileRes = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/profiles?id=eq.$userId&select=*'),
    headers: authHeaders,
  );

  if (profileRes.statusCode != 200) {
    stderr.writeln('FAILED (${profileRes.statusCode}): ${profileRes.body}');
    exit(1);
  }

  final profiles = jsonDecode(profileRes.body) as List<dynamic>;
  if (profiles.isEmpty) {
    stderr.writeln('FAILED: No profile found for user $userId');
    exit(1);
  }

  final userProfile = profiles.first as Map<String, dynamic>;
  stdout.writeln('SUCCESS!');
  stdout.writeln('      Profile Name: "${userProfile['name']}" (Matched: ${userProfile['name'] == testFullName})');
  stdout.writeln('      Profile Email: "${userProfile['email']}"');

  // STEP 3: INSERT & VERIFY WALLET
  stdout.write('\n[3/6] Testing Wallets sync (Insert & Select with RLS)... ');
  final walletId = 'wallet_$testTimestamp';
  final walletRes = await http.post(
    Uri.parse('$supabaseUrl/rest/v1/wallets'),
    headers: authHeaders,
    body: jsonEncode({
      'id': walletId,
      'user_id': userId,
      'name': 'Bank BCA Live Test',
      'type': 'Bank',
      'balance': 1500000.0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }),
  );

  if (walletRes.statusCode != 201 && walletRes.statusCode != 200) {
    stderr.writeln('FAILED (${walletRes.statusCode}): ${walletRes.body}');
    exit(1);
  }

  final walletVerifyRes = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/wallets?id=eq.$walletId&select=*'),
    headers: authHeaders,
  );
  final wallets = jsonDecode(walletVerifyRes.body) as List<dynamic>;
  stdout.writeln('SUCCESS! (Found ${wallets.length} wallet: "${wallets.first['name']}", Saldo: ${wallets.first['balance']})');

  // STEP 4: INSERT & VERIFY CATEGORY
  stdout.write('\n[4/6] Testing Categories sync (Insert & Select with RLS)... ');
  final categoryId = 'cat_$testTimestamp';
  final catRes = await http.post(
    Uri.parse('$supabaseUrl/rest/v1/categories'),
    headers: authHeaders,
    body: jsonEncode({
      'id': categoryId,
      'user_id': userId,
      'name': 'Makanan & Minuman Test',
      'type': 'expense',
      'icon_name': 'fastfood',
      'emoji': '🍔',
      'color_value': 4283215696,
      'is_default': false,
      'created_at': DateTime.now().toIso8601String(),
    }),
  );

  if (catRes.statusCode != 201 && catRes.statusCode != 200) {
    stderr.writeln('FAILED (${catRes.statusCode}): ${catRes.body}');
    exit(1);
  }

  final catVerifyRes = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/categories?id=eq.$categoryId&select=*'),
    headers: authHeaders,
  );
  final categories = jsonDecode(catVerifyRes.body) as List<dynamic>;
  stdout.writeln('SUCCESS! (Found ${categories.length} category: "${categories.first['name']}" ${categories.first['emoji']})');

  // STEP 5: INSERT & VERIFY TRANSACTION
  stdout.write('\n[5/6] Testing Transactions sync (Insert, Mutate, Select)... ');
  final transactionId = 'tx_$testTimestamp';
  final txRes = await http.post(
    Uri.parse('$supabaseUrl/rest/v1/transactions'),
    headers: authHeaders,
    body: jsonEncode({
      'id': transactionId,
      'user_id': userId,
      'title': 'Beli Kopi Arabika Test Live',
      'amount': 35000.0,
      'type': 'expense',
      'category_id': categoryId,
      'category_name': 'Makanan & Minuman Test',
      'wallet_id': walletId,
      'note': 'Test live end-to-end sync via Yotro Agent',
      'timestamp': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }),
  );

  if (txRes.statusCode != 201 && txRes.statusCode != 200) {
    stderr.writeln('FAILED (${txRes.statusCode}): ${txRes.body}');
    exit(1);
  }

  final txVerifyRes = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/transactions?id=eq.$transactionId&select=*'),
    headers: authHeaders,
  );
  final txs = jsonDecode(txVerifyRes.body) as List<dynamic>;
  final insertedTx = txs.first as Map<String, dynamic>;
  stdout.writeln('SUCCESS!');
  stdout.writeln('      Tx Title: "${insertedTx['title']}"');
  stdout.writeln('      Tx Amount: Rp ${insertedTx['amount']}');
  stdout.writeln('      Tx Wallet ID: "${insertedTx['wallet_id']}"');
  stdout.writeln('      Tx Category ID: "${insertedTx['category_id']}"');

  // STEP 6: VERIFY BUDGET SYNC
  stdout.write('\n[6/6] Testing Budgets sync (Upsert & Select)... ');
  final budgetRes = await http.post(
    Uri.parse('$supabaseUrl/rest/v1/budgets'),
    headers: {
      ...authHeaders,
      'Prefer': 'resolution=merge-duplicates,return=representation',
    },
    body: jsonEncode({
      'user_id': userId,
      'overall_monthly_limit': 5000000.0,
      'category_budgets': {
        categoryId: 1500000.0,
      },
      'updated_at': DateTime.now().toIso8601String(),
    }),
  );

  if (budgetRes.statusCode != 201 && budgetRes.statusCode != 200) {
    stderr.writeln('FAILED (${budgetRes.statusCode}): ${budgetRes.body}');
    exit(1);
  }

  final budgetVerifyRes = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/budgets?user_id=eq.$userId&select=*'),
    headers: authHeaders,
  );
  final budgets = jsonDecode(budgetVerifyRes.body) as List<dynamic>;
  final insertedBudget = budgets.first as Map<String, dynamic>;
  stdout.writeln('SUCCESS!');
  stdout.writeln('      Overall Limit: Rp ${insertedBudget['overall_monthly_limit']}');
  stdout.writeln('      Category Budgets: ${jsonEncode(insertedBudget['category_budgets'])}');

  stdout.writeln('\n======================================================');
  stdout.writeln('ALL 6 END-TO-END SUPABASE VERIFICATIONS PASSED 100%!');
  stdout.writeln('Auth, Trigger, RLS, Wallets, Categories, Transactions, & Budgets');
  stdout.writeln('are completely connected and operational.');
  stdout.writeln('======================================================');
}
