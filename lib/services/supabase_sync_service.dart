import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/wallet_model.dart';
import '../models/budget_model.dart';
import '../providers/transaction_provider.dart';
import 'supabase_auth_service.dart';

class SupabaseSyncService {
  static SupabaseClient? get _client => SupabaseConfig.client;

  static bool get canSync =>
      SupabaseConfig.isInitialized && SupabaseAuthService.isAuthenticated && _client != null;

  /// Upload all local state to Supabase
  static Future<bool> uploadAllLocalData(TransactionProvider provider) async {
    if (!canSync) return false;
    final user = SupabaseAuthService.currentUser;
    if (user == null) return false;

    try {
      final now = DateTime.now().toIso8601String();

      // 1. Upsert Profile
      await _client!.from('profiles').upsert({
        'id': user.id,
        'email': user.email ?? '',
        'name': provider.userName,
        'phone': provider.userPhone,
        'gender': provider.userGender,
        'currency': provider.currency,
        'sync_wallet_to_transactions': provider.syncWalletToTransactions,
        'updated_at': now,
      });

      // 2. Upsert Wallets
      if (provider.wallets.isNotEmpty) {
        final walletRows = provider.wallets.map((w) => {
          'id': w.id,
          'user_id': user.id,
          'name': w.name,
          'type': w.type,
          'balance': w.balance,
          'updated_at': now,
        }).toList();
        await _client!.from('wallets').upsert(walletRows);
      }

      // 3. Upsert Categories
      if (provider.categories.isNotEmpty) {
        final categoryRows = provider.categories.map((c) => {
          'id': c.id,
          'user_id': user.id,
          'name': c.name,
          'type': c.type.name,
          'icon_name': c.iconName,
          'emoji': c.emoji,
          'color_value': c.colorValue,
          'is_default': c.isDefault,
        }).toList();
        await _client!.from('categories').upsert(categoryRows);
      }

      // 4. Upsert Transactions
      if (provider.transactions.isNotEmpty) {
        const batchSize = 50;
        for (var i = 0; i < provider.transactions.length; i += batchSize) {
          final chunk = provider.transactions.skip(i).take(batchSize).map((t) => {
            'id': t.id,
            'user_id': user.id,
            'title': t.title,
            'amount': t.amount,
            'type': t.type.name,
            'category_id': t.categoryId,
            'category_name': t.categoryName,
            'wallet_id': t.walletId,
            'from_wallet_id': t.fromWalletId,
            'to_wallet_id': t.toWalletId,
            'note': t.note,
            'timestamp': t.timestamp.toIso8601String(),
            'updated_at': now,
          }).toList();
          await _client!.from('transactions').upsert(chunk);
        }
      }

      // 5. Upsert Budget
      await _client!.from('budgets').upsert({
        'user_id': user.id,
        'overall_monthly_limit': provider.budget.overallMonthlyLimit,
        'category_budgets': provider.budget.categoryBudgets,
        'updated_at': now,
      });

      debugPrint('[SupabaseSyncService] Berhasil mengunggah data lokal ke Supabase.');
      return true;
    } catch (e) {
      debugPrint('[SupabaseSyncService] Error saat uploadAllLocalData: $e');
      return false;
    }
  }

  /// Check if the authenticated user has existing data or an established account in cloud
  static Future<bool> hasExistingUserData() async {
    if (!canSync) return false;
    final user = SupabaseAuthService.currentUser;
    if (user == null) return false;

    try {
      // 1. Check profile in Supabase
      final profileRes = await _client!
          .from('profiles')
          .select('id, name, phone')
          .eq('id', user.id)
          .maybeSingle();
      if (profileRes != null) {
        final name = (profileRes['name'] as String?)?.trim() ?? '';
        final phone = (profileRes['phone'] as String?)?.trim() ?? '';
        if (name.isNotEmpty || phone.isNotEmpty) {
          return true;
        }
      }

      // 2. Check if user already has wallets in Supabase
      final walletRes = await _client!
          .from('wallets')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);
      if ((walletRes as List).isNotEmpty) return true;

      // 3. Check if user already has transactions
      final txRes = await _client!
          .from('transactions')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);
      if ((txRes as List).isNotEmpty) return true;

      // 4. Check if user has categories
      final catRes = await _client!
          .from('categories')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);
      if ((catRes as List).isNotEmpty) return true;

      // 5. Check auth metadata: returning user who has signed in before
      final lastSignIn = user.lastSignInAt;
      final createdAt = user.createdAt;
      if (lastSignIn != null && lastSignIn.isNotEmpty && createdAt.isNotEmpty) {
        if (lastSignIn != createdAt) {
          return true;
        }
      }

      // 6. Check if user account was created in the past (> 30 seconds ago)
      if (createdAt.isNotEmpty) {
        final createdDateTime = DateTime.tryParse(createdAt);
        if (createdDateTime != null) {
          final diff = DateTime.now().toUtc().difference(createdDateTime.toUtc());
          if (diff.inSeconds >= 30) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      debugPrint('[SupabaseSyncService] Error in hasExistingUserData: $e');
      return false;
    }
  }

  /// Pull data from Supabase into local provider
  static Future<bool> pullCloudData(TransactionProvider provider) async {
    if (!canSync) return false;
    final user = SupabaseAuthService.currentUser;
    if (user == null) return false;

    try {
      // 0. Fetch Profile
      String? profileName;
      String? profilePhone;
      String? profileGender;
      try {
        final profileRes = await _client!
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        if (profileRes != null) {
          profileName = profileRes['name'] as String?;
          profilePhone = profileRes['phone'] as String?;
          profileGender = profileRes['gender'] as String?;
        }
      } catch (e) {
        debugPrint('[SupabaseSyncService] Error fetching profile: $e');
      }

      // 1. Fetch Wallets
      final walletRes = await _client!
          .from('wallets')
          .select()
          .eq('user_id', user.id);
      final List<WalletModel> fetchedWallets = (walletRes as List)
          .map((row) => WalletModel(
                id: row['id'] as String,
                name: row['name'] as String,
                type: row['type'] as String,
                balance: (row['balance'] as num).toDouble(),
              ))
          .toList();

      // 2. Fetch Categories
      final catRes = await _client!
          .from('categories')
          .select()
          .eq('user_id', user.id);
      final List<CategoryModel> fetchedCategories = (catRes as List)
          .map((row) => CategoryModel(
                id: row['id'] as String,
                name: row['name'] as String,
                type: TransactionType.values.firstWhere(
                  (t) => t.name == (row['type'] as String? ?? 'expense'),
                  orElse: () => TransactionType.expense,
                ),
                emoji: row['emoji'] as String?,
                iconName: row['icon_name'] as String?,
                colorValue: row['color_value'] != null ? (row['color_value'] as num).toInt() : null,
                isDefault: row['is_default'] as bool? ?? false,
              ))
          .toList();

      // 3. Fetch Transactions
      final txRes = await _client!
          .from('transactions')
          .select()
          .eq('user_id', user.id)
          .order('timestamp', ascending: false);
      final List<TransactionModel> fetchedTransactions = (txRes as List)
          .map((row) => TransactionModel(
                id: row['id'] as String,
                title: row['title'] as String,
                amount: (row['amount'] as num).toDouble(),
                type: TransactionType.values.firstWhere(
                  (t) => t.name == (row['type'] as String? ?? 'expense'),
                  orElse: () => TransactionType.expense,
                ),
                categoryId: row['category_id'] as String,
                categoryName: row['category_name'] as String,
                walletId: row['wallet_id'] as String,
                fromWalletId: row['from_wallet_id'] as String?,
                toWalletId: row['to_wallet_id'] as String?,
                note: row['note'] as String? ?? '',
                timestamp: DateTime.tryParse(row['timestamp'] as String? ?? '') ?? DateTime.now(),
              ))
          .toList();

      // 4. Fetch Budget
      final budgetRes = await _client!
          .from('budgets')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      BudgetModel fetchedBudget = provider.budget;
      if (budgetRes != null) {
        final limit = (budgetRes['overall_monthly_limit'] as num?)?.toDouble() ?? 0.0;
        final rawCat = budgetRes['category_budgets'] as Map<String, dynamic>? ?? {};
        final Map<String, double> catBudgets = rawCat.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        );
        fetchedBudget = BudgetModel(
          overallMonthlyLimit: limit,
          categoryBudgets: catBudgets,
        );
      }

      // Merge / Apply to Provider
      provider.applyCloudSnapshot(
        wallets: fetchedWallets.isNotEmpty ? fetchedWallets : null,
        categories: fetchedCategories.isNotEmpty ? fetchedCategories : null,
        transactions: fetchedTransactions.isNotEmpty ? fetchedTransactions : null,
        budget: budgetRes != null ? fetchedBudget : null,
        userName: profileName,
        userPhone: profilePhone,
        userGender: profileGender,
      );

      debugPrint('[SupabaseSyncService] Berhasil menarik data cloud.');
      return true;
    } catch (e) {
      debugPrint('[SupabaseSyncService] Error saat pullCloudData: $e');
      return false;
    }
  }

  /// Sync single transaction mutation to Supabase in background
  static Future<void> syncSingleTransaction(
    TransactionModel tx, {
    bool isDelete = false,
  }) async {
    if (!canSync) return;
    final user = SupabaseAuthService.currentUser;
    if (user == null) return;

    try {
      if (isDelete) {
        await _client!
            .from('transactions')
            .delete()
            .eq('id', tx.id)
            .eq('user_id', user.id);
      } else {
        await _client!.from('transactions').upsert({
          'id': tx.id,
          'user_id': user.id,
          'title': tx.title,
          'amount': tx.amount,
          'type': tx.type.name,
          'category_id': tx.categoryId,
          'category_name': tx.categoryName,
          'wallet_id': tx.walletId,
          'from_wallet_id': tx.fromWalletId,
          'to_wallet_id': tx.toWalletId,
          'note': tx.note,
          'timestamp': tx.timestamp.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('[SupabaseSyncService] Error saat syncSingleTransaction: $e');
    }
  }
}
