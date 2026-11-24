import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/wallet_model.dart';
import '../models/budget_model.dart';
import '../models/subscription_model.dart';
import '../providers/transaction_provider.dart';
import 'encryption_service.dart';
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

      // 4. Upsert Transactions (with transparent E2EE encryption)
      if (provider.transactions.isNotEmpty) {
        const batchSize = 50;
        for (var i = 0; i < provider.transactions.length; i += batchSize) {
          final chunk = provider.transactions.skip(i).take(batchSize).map((t) => {
            'id': t.id,
            'user_id': user.id,
            'title': EncryptionService.encryptString(t.title, user.id),
            'amount': EncryptionService.encryptAmount(t.amount, user.id),
            'type': t.type.name,
            'category_id': t.categoryId,
            'category_name': t.categoryName,
            'wallet_id': t.walletId,
            'from_wallet_id': t.fromWalletId,
            'to_wallet_id': t.toWalletId,
            'note': t.note.isNotEmpty ? EncryptionService.encryptString(t.note, user.id) : '',
            'timestamp': t.timestamp.toIso8601String(),
            'updated_at': now,
          }).toList();
          await _client!.from('transactions').upsert(chunk);
        }
      }

      // 5. Upsert Budget
      final catBudgetsWithMeta = Map<String, dynamic>.from(provider.budget.categoryBudgets);
      catBudgetsWithMeta['_meta_reset_day'] = provider.budget.monthlyResetDay;
      await _client!.from('budgets').upsert({
        'user_id': user.id,
        'overall_monthly_limit': provider.budget.overallMonthlyLimit,
        'category_budgets': catBudgetsWithMeta,
        'updated_at': now,
      });

      // 6. Upsert Subscriptions (isolated try-catch in case table migration is pending)
      if (provider.subscriptions.isNotEmpty) {
        try {
          final subRows = provider.subscriptions
              .map((s) => _subscriptionToRow(s, user.id, now))
              .toList();
          await _client!.from('subscriptions').upsert(subRows);
        } catch (e) {
          debugPrint('[SupabaseSyncService] Skip/Error upsert subscriptions: $e');
        }
      }

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
      // 1. Check if user already has wallets in Supabase (Primary indicator of completed onboarding setup)
      final walletRes = await _client!
          .from('wallets')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);
      if ((walletRes as List).isNotEmpty) return true;

      // 2. Check if user already has transactions in Supabase
      final txRes = await _client!
          .from('transactions')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);
      if ((txRes as List).isNotEmpty) return true;

      // 3. Check if user has categories in Supabase
      final catRes = await _client!
          .from('categories')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);
      if ((catRes as List).isNotEmpty) return true;

      // Note: We do NOT use profiles.name because Google OAuth automatically
      // inserts profiles.name via database trigger on initial sign up.
      // A brand new user with 0 wallets, 0 transactions, and 0 categories must
      // be guided to complete the onboarding setup first.
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
      try {
        final profileRes = await _client!
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        if (profileRes != null) {
          profileName = profileRes['name'] as String?;
          profilePhone = profileRes['phone'] as String?;
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

      // 3. Fetch Transactions (decrypt title, amount, and note)
      bool hadUnencryptedData = false;
      final txRes = await _client!
          .from('transactions')
          .select()
          .eq('user_id', user.id)
          .order('timestamp', ascending: false);
      final List<TransactionModel> fetchedTransactions = (txRes as List)
          .map((row) {
            final rawTitle = row['title'] as String?;
            final rawAmount = row['amount'];
            if ((rawTitle != null && rawTitle.isNotEmpty && !rawTitle.startsWith(EncryptionService.prefix)) ||
                (rawAmount is String && !rawAmount.startsWith(EncryptionService.prefix)) ||
                rawAmount is num) {
              hadUnencryptedData = true;
            }
            return TransactionModel(
              id: row['id'] as String,
              title: EncryptionService.decryptString(rawTitle, user.id),
              amount: EncryptionService.decryptAmount(rawAmount, user.id),
              type: TransactionType.values.firstWhere(
                (t) => t.name == (row['type'] as String? ?? 'expense'),
                orElse: () => TransactionType.expense,
              ),
              categoryId: row['category_id'] as String,
              categoryName: row['category_name'] as String,
              walletId: row['wallet_id'] as String,
              fromWalletId: row['from_wallet_id'] as String?,
              toWalletId: row['to_wallet_id'] as String?,
              note: EncryptionService.decryptString(row['note'] as String?, user.id),
              timestamp: DateTime.tryParse(row['timestamp'] as String? ?? '') ?? DateTime.now(),
            );
          })
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
        final int? metaResetDay = (rawCat['_meta_reset_day'] as num?)?.toInt() ??
            (budgetRes['monthly_reset_day'] as num?)?.toInt();
        final Map<String, double> catBudgets = {};
        rawCat.forEach((k, v) {
          if (k != '_meta_reset_day' && v is num) {
            catBudgets[k] = v.toDouble();
          }
        });
        fetchedBudget = BudgetModel(
          overallMonthlyLimit: limit,
          categoryBudgets: catBudgets,
          monthlyResetDay: metaResetDay ?? 1,
        );
      }

      // 5. Fetch Subscriptions (isolated try-catch in case table migration is pending)
      List<SubscriptionModel>? fetchedSubscriptions;
      try {
        final subRes = await _client!
            .from('subscriptions')
            .select()
            .eq('user_id', user.id);
        fetchedSubscriptions = (subRes as List)
            .map((row) => _subscriptionFromRow(row as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[SupabaseSyncService] Skip/Error fetching subscriptions: $e');
      }

      // Merge / Apply to Provider
      provider.applyCloudSnapshot(
        wallets: fetchedWallets.isNotEmpty ? fetchedWallets : null,
        categories: fetchedCategories.isNotEmpty ? fetchedCategories : null,
        transactions: fetchedTransactions.isNotEmpty ? fetchedTransactions : null,
        budget: budgetRes != null ? fetchedBudget : null,
        subscriptions: fetchedSubscriptions,
        userName: profileName,
        userPhone: profilePhone,
      );

      // Auto-encrypt legacy data in background if any unencrypted transactions were detected
      if (hadUnencryptedData && fetchedTransactions.isNotEmpty) {
        debugPrint('[SupabaseSyncService] Mendeteksi data lama belum terenkripsi. Mengunggah versi terenkripsi ke cloud...');
        await uploadAllLocalData(provider);
      }

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
          'title': EncryptionService.encryptString(tx.title, user.id),
          'amount': EncryptionService.encryptAmount(tx.amount, user.id),
          'type': tx.type.name,
          'category_id': tx.categoryId,
          'category_name': tx.categoryName,
          'wallet_id': tx.walletId,
          'from_wallet_id': tx.fromWalletId,
          'to_wallet_id': tx.toWalletId,
          'note': tx.note.isNotEmpty ? EncryptionService.encryptString(tx.note, user.id) : '',
          'timestamp': tx.timestamp.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('[SupabaseSyncService] Error saat syncSingleTransaction: $e');
    }
  }

  /// Sync single wallet row to Supabase in background
  static Future<void> syncWallet(WalletModel wallet) async {
    if (!canSync) return;
    final user = SupabaseAuthService.currentUser;
    if (user == null) return;

    try {
      await _client!.from('wallets').upsert({
        'id': wallet.id,
        'user_id': user.id,
        'name': wallet.name,
        'type': wallet.type,
        'balance': wallet.balance,
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('[SupabaseSyncService] Synced wallet ${wallet.name} (balance: ${wallet.balance})');
    } catch (e) {
      debugPrint('[SupabaseSyncService] Error saat syncWallet: $e');
    }
  }

  /// Batch sync all wallets to Supabase in background
  static Future<void> syncWallets(List<WalletModel> wallets) async {
    if (!canSync || wallets.isEmpty) return;
    final user = SupabaseAuthService.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now().toIso8601String();
      final walletRows = wallets.map((w) => {
        'id': w.id,
        'user_id': user.id,
        'name': w.name,
        'type': w.type,
        'balance': w.balance,
        'updated_at': now,
      }).toList();
      await _client!.from('wallets').upsert(walletRows);
      debugPrint('[SupabaseSyncService] Synced ${wallets.length} wallets');
    } catch (e) {
      debugPrint('[SupabaseSyncService] Error saat syncWallets: $e');
    }
  }

  /// Delete wallet from Supabase in background
  static Future<void> deleteWalletFromCloud(String walletId) async {
    if (!canSync) return;
    final user = SupabaseAuthService.currentUser;
    if (user == null) return;

    try {
      await _client!
          .from('wallets')
          .delete()
          .eq('id', walletId)
          .eq('user_id', user.id);
      debugPrint('[SupabaseSyncService] Deleted wallet $walletId from cloud');
    } catch (e) {
      debugPrint('[SupabaseSyncService] Error saat deleteWalletFromCloud: $e');
    }
  }

  /// Sync single category row to Supabase in background
  static Future<void> syncCategory(CategoryModel category) async {
    if (!canSync) return;
    final user = SupabaseAuthService.currentUser;
    if (user == null) return;

    try {
      await _client!.from('categories').upsert({
        'id': category.id,
        'user_id': user.id,
        'name': category.name,
        'type': category.type.name,
        'icon_name': category.iconName,
        'emoji': category.emoji,
        'color_value': category.colorValue,
        'is_default': category.isDefault,
      });
      debugPrint('[SupabaseSyncService] Synced category ${category.name} (${category.id})');
    } catch (e) {
      debugPrint('[SupabaseSyncService] Error saat syncCategory: $e');
    }
  }

  /// Batch sync all categories to Supabase in background
  static Future<void> syncCategories(List<CategoryModel> categories) async {
    if (!canSync || categories.isEmpty) return;
    final user = SupabaseAuthService.currentUser;
    if (user == null) return;

    try {
      final categoryRows = categories.map((c) => {
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
      debugPrint('[SupabaseSyncService] Synced ${categories.length} categories to cloud');
    } catch (e) {
      debugPrint('[SupabaseSyncService] Error saat syncCategories: $e');
    }
  }

  /// Delete category from Supabase in background
  static Future<void> deleteCategoryFromCloud(String categoryId) async {
    if (!canSync) return;
    final user = SupabaseAuthService.currentUser;
    if (user == null) return;

    try {
      await _client!
          .from('categories')
          .delete()
          .eq('id', categoryId)
          .eq('user_id', user.id);
      debugPrint('[SupabaseSyncService] Deleted category $categoryId from cloud');
    } catch (e) {
      debugPrint('[SupabaseSyncService] Error saat deleteCategoryFromCloud: $e');
    }
  }

  /// Sync user budget limits and reset day to Supabase in background
  static Future<void> syncBudget(BudgetModel budget) async {
    if (!canSync) return;
    final user = SupabaseAuthService.currentUser;
    if (user == null) return;

    try {
      final catBudgetsWithMeta = Map<String, dynamic>.from(budget.categoryBudgets);
      catBudgetsWithMeta['_meta_reset_day'] = budget.monthlyResetDay;
      await _client!.from('budgets').upsert({
        'user_id': user.id,
        'overall_monthly_limit': budget.overallMonthlyLimit,
        'category_budgets': catBudgetsWithMeta,
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('[SupabaseSyncService] Synced budget (limit: ${budget.overallMonthlyLimit}, categories: ${budget.categoryBudgets.length})');
    } catch (e) {
      debugPrint('[SupabaseSyncService] Error saat syncBudget: $e');
    }
  }

  /// Sync user profile details to Supabase in background
  static Future<void> syncProfile({
    required String name,
    required String phone,
    String? currency,
    bool? syncWalletToTransactions,
  }) async {
    if (!canSync) return;
    final user = SupabaseAuthService.currentUser;
    if (user == null) return;

    try {
      final payload = <String, dynamic>{
        'id': user.id,
        'email': user.email ?? '',
        'name': name,
        'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (currency != null) payload['currency'] = currency;
      if (syncWalletToTransactions != null) {
        payload['sync_wallet_to_transactions'] = syncWalletToTransactions;
      }
      await _client!.from('profiles').upsert(payload);
      debugPrint('[SupabaseSyncService] Synced profile for ${user.id}');
    } catch (e) {
      debugPrint('[SupabaseSyncService] Error saat syncProfile: $e');
    }
  }

  static Map<String, dynamic> _subscriptionToRow(
    SubscriptionModel sub,
    String userId,
    String nowIso,
  ) {
    return {
      'id': sub.id,
      'user_id': userId,
      'name': sub.name,
      'amount': sub.amount,
      'billing_day': sub.billingDay,
      'cycle': sub.cycle.name,
      'category_id': sub.categoryId,
      'category_name': sub.categoryName,
      'wallet_id': sub.walletId,
      'reminder_enabled': sub.reminderEnabled,
      'reminder_days_before': sub.reminderDaysBefore,
      'last_paid_date': sub.lastPaidDate?.toIso8601String(),
      'created_at': sub.createdAt.toIso8601String(),
      'updated_at': nowIso,
    };
  }

  static SubscriptionModel _subscriptionFromRow(Map<String, dynamic> row) {
    return SubscriptionModel(
      id: row['id'] as String,
      name: row['name'] as String,
      amount: (row['amount'] as num).toDouble(),
      billingDay: (row['billing_day'] as num?)?.toInt() ?? 1,
      cycle: SubscriptionCycle.values.firstWhere(
        (c) => c.name == (row['cycle'] as String? ?? 'monthly'),
        orElse: () => SubscriptionCycle.monthly,
      ),
      categoryId: row['category_id'] as String? ?? '',
      categoryName: row['category_name'] as String? ?? 'Tagihan & Utilitas',
      walletId: row['wallet_id'] as String? ?? '',
      reminderEnabled: row['reminder_enabled'] as bool? ?? true,
      reminderDaysBefore: (row['reminder_days_before'] as num?)?.toInt() ?? 1,
      lastPaidDate: row['last_paid_date'] != null
          ? DateTime.tryParse(row['last_paid_date'] as String)
          : null,
      createdAt: row['created_at'] != null
          ? (DateTime.tryParse(row['created_at'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  /// Sync single subscription to Supabase in background
  static Future<void> syncSubscription(SubscriptionModel sub) async {
    if (!canSync) return;
    final user = SupabaseAuthService.currentUser;
    if (user == null) return;

    try {
      await _client!
          .from('subscriptions')
          .upsert(_subscriptionToRow(sub, user.id, DateTime.now().toIso8601String()));
      debugPrint('[SupabaseSyncService] Synced subscription ${sub.name} (${sub.id})');
    } catch (e) {
      debugPrint('[SupabaseSyncService] Error saat syncSubscription: $e');
    }
  }

  /// Batch sync all subscriptions to Supabase in background
  static Future<void> syncSubscriptions(List<SubscriptionModel> subs) async {
    if (!canSync || subs.isEmpty) return;
    final user = SupabaseAuthService.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now().toIso8601String();
      final rows = subs.map((s) => _subscriptionToRow(s, user.id, now)).toList();
      await _client!.from('subscriptions').upsert(rows);
      debugPrint('[SupabaseSyncService] Synced ${subs.length} subscriptions to cloud');
    } catch (e) {
      debugPrint('[SupabaseSyncService] Error saat syncSubscriptions: $e');
    }
  }

  /// Delete subscription from Supabase in background
  static Future<void> deleteSubscriptionFromCloud(String subscriptionId) async {
    if (!canSync) return;
    final user = SupabaseAuthService.currentUser;
    if (user == null) return;

    try {
      await _client!
          .from('subscriptions')
          .delete()
          .eq('id', subscriptionId)
          .eq('user_id', user.id);
      debugPrint('[SupabaseSyncService] Deleted subscription $subscriptionId from cloud');
    } catch (e) {
      debugPrint('[SupabaseSyncService] Error saat deleteSubscriptionFromCloud: $e');
    }
  }
}
