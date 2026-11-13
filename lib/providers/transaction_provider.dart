import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/wallet_model.dart';
import '../models/budget_model.dart';
import '../models/notification_rule_model.dart';
import '../services/native_notification_service.dart';
import '../services/supabase_auth_service.dart';
import '../services/supabase_sync_service.dart';
import '../config/app_capabilities.dart';

bool get canUseNativePermission {
  if (kIsWeb) return false;
  try {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    return Platform.isAndroid || Platform.isIOS;
  } catch (_) {
    return false;
  }
}

enum DashboardViewMode {
  complete,
  incomeExpense,
  expenseOnly;

  String get label {
    switch (this) {
      case DashboardViewMode.complete:
        return 'Complete View';
      case DashboardViewMode.incomeExpense:
        return 'Pemasukan dan Pengeluaran';
      case DashboardViewMode.expenseOnly:
        return 'Pengeluaran Saja';
    }
  }

  String get shortLabel {
    switch (this) {
      case DashboardViewMode.complete:
        return 'Complete';
      case DashboardViewMode.incomeExpense:
        return 'Masuk & Keluar';
      case DashboardViewMode.expenseOnly:
        return 'Pengeluaran';
    }
  }

  String get description {
    switch (this) {
      case DashboardViewMode.complete:
        return 'Tampilan default (saldo saat ini, pemasukan, dan pengeluaran)';
      case DashboardViewMode.incomeExpense:
        return 'Sembunyikan view saldo saat ini di kartu beranda';
      case DashboardViewMode.expenseOnly:
        return 'Fokus pada tampilan pengeluaran saja (tanpa saldo & pemasukan)';
    }
  }
}

enum DashboardBalanceMode {
  monthly,
  total;

  String get label {
    switch (this) {
      case DashboardBalanceMode.monthly:
        return 'Bulanan';
      case DashboardBalanceMode.total:
        return 'Total Saldo';
    }
  }
}

class TransactionProvider with ChangeNotifier {
  static const String _storageKey = 'money_tracker_pro_v2_1';

  List<TransactionModel> _transactions = [];
  List<WalletModel> _wallets = [
    WalletModel(
        id: 'w_bank',
        name: 'BCA Prioritas',
        type: 'Bank Account',
        balance: 100000.0),
    WalletModel(
        id: 'w_cash', name: 'Dompet Tunai', type: 'Cash', balance: 32400.0),
    WalletModel(id: 'w_ewallet', name: 'GoPay', type: 'E-Wallet', balance: 0.0),
  ];
  List<CategoryModel> _categories = [
    ...CategoryModel.defaultExpenseCategories,
    ...CategoryModel.defaultIncomeCategories,
  ];
  BudgetModel _budget = BudgetModel();
  String _currency = 'IDR';
  String _userName = 'Ian Firdaus';
  String _userPhone = '';
  String _userGender = 'Pria';
  bool _isOnboardingCompleted = false;
  bool _isGuestMode = false;
  String _selectedPeriod = 'this_month';
  DateTime _selectedDashboardMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _isBalanceVisible = true;
  DashboardViewMode _dashboardViewMode = DashboardViewMode.complete;
  DashboardBalanceMode _dashboardBalanceMode = DashboardBalanceMode.monthly;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _hasNotificationPermission = false;
  bool _isDailyReminderEnabled = false;
  String _dailyReminderTime = '18:00';
  List<String> _dailyReminderTimes = ['18:00', '19:00'];
  bool _isNotificationReaderEnabled = true;
  List<NotificationRule> _notificationRules = NotificationRule.defaultRules;
  List<PendingNotification> _pendingNotifications = [];
  List<ActivityNotification> _activityNotifications = [];
  bool _syncWalletToTransactions = true;
  bool _isSyncingWithCloud = false;
  DateTime? _lastCloudSyncTime;
  bool _isLoading = true;
  TransactionType _analyticsTab = TransactionType.expense;
  Timer? _reminderTimer;
  String? _lastReminderDateStr;

  List<TransactionModel> get transactions => _transactions;
  List<WalletModel> get wallets => _wallets;
  List<CategoryModel> get categories => _categories;
  List<CategoryModel> getCategories(TransactionType type) =>
      _categories.where((c) => c.type == type).toList();
  CategoryModel? getCategoryByName(String name) {
    return _categories.cast<CategoryModel?>().firstWhere(
          (c) => c?.name == name,
          orElse: () => null,
        );
  }

  BudgetModel get budget => _budget;
  String get currency => _currency;
  String get userName => _userName;
  String get userPhone => _userPhone;
  String get userGender => _userGender;
  bool get isOnboardingCompleted => _isOnboardingCompleted;
  bool get isGuestMode => _isGuestMode;
  String get selectedPeriod => _selectedPeriod;
  DateTime get selectedDashboardMonth => _selectedDashboardMonth;
  bool get isBalanceVisible => _isBalanceVisible;
  DashboardViewMode get dashboardViewMode => _dashboardViewMode;
  DashboardBalanceMode get dashboardBalanceMode => _dashboardBalanceMode;
  bool get hideBalanceSection =>
      _dashboardViewMode != DashboardViewMode.complete;
  bool get showBalanceSection =>
      _dashboardViewMode == DashboardViewMode.complete;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
  bool get hasNotificationPermission => _hasNotificationPermission;
  bool get isDailyReminderEnabled => _isDailyReminderEnabled;
  String get dailyReminderTime => _dailyReminderTime;
  List<String> get dailyReminderTimes => List.unmodifiable(_dailyReminderTimes);
  bool get hasTransactionToday {
    final now = DateTime.now();
    return _transactions.any((tx) =>
        tx.timestamp.year == now.year &&
        tx.timestamp.month == now.month &&
        tx.timestamp.day == now.day);
  }

  bool get shouldShowDailyReminder =>
      _isDailyReminderEnabled && !hasTransactionToday;
  bool get isNotificationReaderEnabled => _isNotificationReaderEnabled;
  bool get syncWalletToTransactions => _syncWalletToTransactions;
  bool get isSyncingWithCloud => _isSyncingWithCloud;
  DateTime? get lastCloudSyncTime => _lastCloudSyncTime;
  List<NotificationRule> get notificationRules => _notificationRules;
  List<PendingNotification> get pendingNotifications => _pendingNotifications
      .where((n) => n.status == PendingNotificationStatus.pending)
      .toList();
  List<PendingNotification> get allNotifications => _pendingNotifications;
  int get pendingNotificationsCount => pendingNotifications.length;
  List<ActivityNotification> get activityNotifications =>
      _activityNotifications;

  void addActivityNotification({
    required String title,
    required String message,
    TransactionType? type,
    double? amount,
    DateTime? timestamp,
  }) {
    final item = ActivityNotification(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}_${_activityNotifications.length}',
      title: title,
      message: message,
      timestamp: timestamp ?? DateTime.now(),
      type: type,
      amount: amount,
    );
    _activityNotifications.insert(0, item);
    if (_activityNotifications.length > 100) {
      _activityNotifications.removeRange(100, _activityNotifications.length);
    }
    notifyListeners();
  }

  Future<void> clearActivityNotifications() async {
    _activityNotifications.clear();
    notifyListeners();
    await saveData();
  }

  bool get isLoading => _isLoading;
  TransactionType get analyticsTab => _analyticsTab;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    saveData();
  }

  void toggleThemeMode() {
    setThemeMode(
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  void setUserName(String name) {
    _userName = name.trim().isEmpty ? 'Ian Firdaus' : name.trim();
    notifyListeners();
    saveData();
  }

  void setAnalyticsTab(TransactionType tab) {
    _analyticsTab = tab;
    notifyListeners();
  }

  Map<String, double> getCategoryBreakdown() {
    final map = <String, double>{};
    for (final tx in _transactions.where((t) => t.type == _analyticsTab)) {
      map[tx.categoryName] = (map[tx.categoryName] ?? 0.0) + tx.amount;
    }
    return map;
  }

  // 4.1 Dashboard Metrics
  double get totalBalance {
    return _wallets.fold(0.0, (sum, w) => sum + w.balance);
  }

  double get totalIncome {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  void setSelectedDashboardMonth(DateTime month) {
    _selectedDashboardMonth = DateTime(month.year, month.month, 1);
    // Saat filter bulan dipilih, otomatis aktifkan mode bulanan
    _dashboardBalanceMode = DashboardBalanceMode.monthly;
    notifyListeners();
  }

  void setDashboardBalanceMode(DashboardBalanceMode mode) {
    if (_dashboardBalanceMode != mode) {
      _dashboardBalanceMode = mode;
      notifyListeners();
    }
  }

  void toggleDashboardBalanceMode() {
    _dashboardBalanceMode = _dashboardBalanceMode == DashboardBalanceMode.monthly
        ? DashboardBalanceMode.total
        : DashboardBalanceMode.monthly;
    notifyListeners();
  }

  double get dashboardMonthNetBalance =>
      dashboardMonthIncome - dashboardMonthExpense;

  double get bankWalletsTotalBalance {
    return _wallets
        .where((w) {
          final t = w.type.toLowerCase();
          return t == 'bank account' || t == 'savings' || t == 'bank';
        })
        .fold(0.0, (sum, w) => sum + w.balance);
  }

  double get cashAndDigitalWalletsTotalBalance {
    return _wallets
        .where((w) {
          final t = w.type.toLowerCase();
          return t != 'bank account' && t != 'savings' && t != 'bank';
        })
        .fold(0.0, (sum, w) => sum + w.balance);
  }

  double get heroCardDisplayBalance {
    if (_dashboardViewMode == DashboardViewMode.expenseOnly) {
      return _dashboardBalanceMode == DashboardBalanceMode.total
          ? totalExpense
          : dashboardMonthExpense;
    }
    return _dashboardBalanceMode == DashboardBalanceMode.total
        ? totalBalance
        : dashboardMonthNetBalance;
  }

  double get dashboardMonthIncome {
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.timestamp.year == _selectedDashboardMonth.year &&
            t.timestamp.month == _selectedDashboardMonth.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get dashboardMonthExpense {
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.timestamp.year == _selectedDashboardMonth.year &&
            t.timestamp.month == _selectedDashboardMonth.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get remainingBudget {
    final rem = _budget.overallMonthlyLimit - totalExpense;
    return rem > 0 ? rem : 0.0;
  }

  double get budgetUsagePercentage {
    if (_budget.overallMonthlyLimit <= 0) return 0.0;
    final pct = (totalExpense / _budget.overallMonthlyLimit) * 100;
    return pct > 100 ? 100 : pct;
  }

  TransactionProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(raw);
        _currency = data['currency'] as String? ?? 'IDR';
        _userName = data['userName'] as String? ?? 'Ian Firdaus';
        _userPhone = data['userPhone'] as String? ?? '';
        _userGender = data['userGender'] as String? ?? 'Pria';
        _isOnboardingCompleted = data['isOnboardingCompleted'] as bool? ??
            (data['userName'] != null &&
                (data['userName'] as String).trim().isNotEmpty);
        _isGuestMode = data['isGuestMode'] as bool? ?? false;
        if (data['themeMode'] != null) {
          final m = data['themeMode'].toString();
          if (m == 'system') {
            _themeMode = ThemeMode.system;
          } else if (m == 'light') {
            _themeMode = ThemeMode.light;
          } else {
            _themeMode = ThemeMode.dark;
          }
        }
        _hasNotificationPermission =
            data['hasNotificationPermission'] as bool? ?? false;
        _isDailyReminderEnabled =
            data['isDailyReminderEnabled'] as bool? ?? false;
        if (data['dailyReminderTimes'] != null) {
          _dailyReminderTimes = (data['dailyReminderTimes'] as List<dynamic>)
              .map((e) => e.toString())
              .toList();
        } else if (data['dailyReminderTime'] != null) {
          _dailyReminderTimes = [data['dailyReminderTime'] as String];
        } else {
          _dailyReminderTimes = ['18:00', '19:00'];
        }
        _dailyReminderTime = _dailyReminderTimes.isNotEmpty
            ? _dailyReminderTimes.first
            : '18:00';
        _isNotificationReaderEnabled =
            data['isNotificationReaderEnabled'] as bool? ?? true;
        if (data['notificationRules'] != null) {
          _notificationRules = (data['notificationRules'] as List<dynamic>)
              .map((r) => NotificationRule.fromJson(r as Map<String, dynamic>))
              .toList();
        } else {
          _notificationRules = NotificationRule.defaultRules;
        }
        if (data['pendingNotifications'] != null) {
          _pendingNotifications =
              (data['pendingNotifications'] as List<dynamic>)
                  .map((n) =>
                      PendingNotification.fromJson(n as Map<String, dynamic>))
                  .toList();
        } else {
          _pendingNotifications = [];
        }
        _syncWalletToTransactions =
            data['syncWalletToTransactions'] as bool? ?? true;
        if (data['lastCloudSyncTime'] != null) {
          _lastCloudSyncTime =
              DateTime.tryParse(data['lastCloudSyncTime'] as String);
        }
        if (data['dashboardViewMode'] != null) {
          final modeStr = data['dashboardViewMode'] as String;
          _dashboardViewMode = DashboardViewMode.values.firstWhere(
            (m) => m.name == modeStr,
            orElse: () => DashboardViewMode.complete,
          );
        } else {
          final hide = data['hideBalanceSection'] as bool? ??
              (data['showBalanceSection'] != null
                  ? !(data['showBalanceSection'] as bool)
                  : false);
          _dashboardViewMode = hide
              ? DashboardViewMode.incomeExpense
              : DashboardViewMode.complete;
        }
        _budget =
            BudgetModel.fromJson(data['budget'] as Map<String, dynamic>? ?? {});
        _categories = (data['categories'] as List<dynamic>?)
                ?.map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [
              ...CategoryModel.defaultExpenseCategories,
              ...CategoryModel.defaultIncomeCategories,
            ];
        _wallets = (data['wallets'] as List<dynamic>?)
                ?.map((w) => WalletModel.fromJson(w as Map<String, dynamic>))
                .toList() ??
            [];
        _transactions = (data['transactions'] as List<dynamic>?)
                ?.map(
                    (t) => TransactionModel.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [];
        if (data['activityNotifications'] != null) {
          _activityNotifications =
              (data['activityNotifications'] as List<dynamic>)
                  .map((a) =>
                      ActivityNotification.fromJson(a as Map<String, dynamic>))
                  .toList();
        } else {
          _activityNotifications = [];
          for (final t in _transactions.take(15)) {
            final typeText = t.type == TransactionType.expense
                ? 'Catat Pengeluaran Berhasil'
                : (t.type == TransactionType.income
                    ? 'Catat Pemasukan Berhasil'
                    : 'Transfer Berhasil');
            _activityNotifications.add(
              ActivityNotification(
                id: 'act_${t.id}',
                title: typeText,
                message:
                    '${t.title} senilai ${formatCurrency(t.amount)} dicatat ke ${t.categoryName}.',
                timestamp: t.timestamp,
                type: t.type,
                amount: t.amount,
              ),
            );
          }
        }
      } else {
        final isTest =
            !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
        if (isTest) {
          _seedDefaults();
          _isOnboardingCompleted = true;
        } else {
          _seedEmpty();
          _isOnboardingCompleted = false;
          _userName = '';
          _userPhone = '';
          _userGender = 'Pria';
        }
        await saveData();
      }
    } catch (_) {
      final isTest =
          !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
      if (isTest) {
        _seedDefaults();
        _isOnboardingCompleted = true;
      } else {
        _seedEmpty();
        _isOnboardingCompleted = false;
      }
    }

    if (canUseNativePermission) {
      try {
        final status = await Permission.notification.status.timeout(
          const Duration(milliseconds: 250),
          onTimeout: () => PermissionStatus.denied,
        );
        _hasNotificationPermission = status.isGranted;
      } catch (_) {}
    }

    _isLoading = false;
    notifyListeners();

    if (canUseNativePermission) {
      try {
        await NativeNotificationService.instance.initialize();
        if (_isDailyReminderEnabled) {
          _rescheduleDailyReminder();
        }
        if (_isNotificationReaderEnabled &&
            AppCapabilities.notificationReaderEnabled) {
          _startNotificationListener();
        }
      } catch (_) {}
    }
    if (canUseNativePermission) {
      _startReminderPeriodicTimer();
    }
  }

  void _startReminderPeriodicTimer() {
    _reminderTimer?.cancel();
    _reminderTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isDailyReminderEnabled || hasTransactionToday) return;

      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month}-${now.day}';
      final currentFormatted =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      if (_dailyReminderTimes.contains(currentFormatted)) {
        final reminderKey = '$todayStr-$currentFormatted';
        if (_lastReminderDateStr == reminderKey) return;
        _lastReminderDateStr = reminderKey;
        NativeNotificationService.instance.showPushNotification(
          id: 8889,
          title: 'Pengingat Transaksi Harian',
          body:
              'Kamu belum mencatat transaksi hari ini. Yuk catat pengeluaran & pemasukanmu di Yotro!',
          isReminder: true,
        );
      }
    });
  }

  Future<void> _rescheduleDailyReminder() async {
    if (!canUseNativePermission || !_isDailyReminderEnabled) return;
    try {
      for (int i = 0; i < 10; i++) {
        await NativeNotificationService.instance
            .cancelDailyReminder(id: 8880 + i);
      }
      for (int i = 0; i < _dailyReminderTimes.length; i++) {
        final parts = _dailyReminderTimes[i].split(':');
        final hour = int.tryParse(parts[0]) ?? 18;
        final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        await NativeNotificationService.instance.scheduleDailyReminder(
          id: 8880 + i,
          hour: hour,
          minute: minute,
          title: 'Pengingat Transaksi Harian',
          body:
              'Kamu belum mencatat transaksi hari ini. Yuk catat pengeluaran & pemasukanmu di Yotro!',
        );
      }
    } catch (_) {}
  }

  void _startNotificationListener() {
    if (!canUseNativePermission || !AppCapabilities.notificationReaderEnabled) {
      return;
    }
    NativeNotificationService.instance.startListening(
      (
          {required String sourceApp,
          required String message,
          required String packageName}) {
        processIncomingNotification(
          sourceApp: sourceApp,
          message: message,
          packageName: packageName,
        );
      },
    );
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    if (canUseNativePermission) {
      NativeNotificationService.instance.stopListening();
    }
    super.dispose();
  }

  void _seedEmpty() {
    _categories = [
      ...CategoryModel.defaultExpenseCategories,
      ...CategoryModel.defaultIncomeCategories,
    ];
    _wallets = [
      WalletModel(
          id: 'w_default', name: 'Dompet Utama', type: 'Dompet', balance: 0.0),
    ];
    _budget = BudgetModel(
      overallMonthlyLimit: 0.0,
      categoryBudgets: {},
    );
    _transactions = [];
    _pendingNotifications = [];
  }

  void _seedDefaults() {
    _categories = [
      ...CategoryModel.defaultExpenseCategories,
      ...CategoryModel.defaultIncomeCategories,
    ];
    _wallets = [
      WalletModel(
        id: 'w_bank',
        name: 'BCA Utama',
        type: 'Bank Account',
        balance: 14500000.0,
      ),
      WalletModel(
        id: 'w_cash',
        name: 'Dompet Tunai',
        type: 'Cash',
        balance: 650000.0,
      ),
      WalletModel(
        id: 'w_ewallet',
        name: 'GoPay / OVO',
        type: 'E-Wallet',
        balance: 820000.0,
      ),
      WalletModel(
        id: 'w_mandiri',
        name: 'Bank Mandiri',
        type: 'Bank Account',
        balance: 6200000.0,
      ),
    ];
    _budget = BudgetModel(
      overallMonthlyLimit: 5000000.0,
      categoryBudgets: {
        'Makanan & Minuman': 1500000.0,
        'Transportasi': 800000.0,
        'Belanja': 1200000.0,
        'Tagihan & Utilitas': 750000.0,
        'Hiburan': 500000.0,
      },
    );
    final now = DateTime.now();
    _transactions = [
      TransactionModel(
        id: 'tx_demo_4',
        title: 'Makan Siang Steak & Pasta',
        amount: 135000.0,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'Makanan & Minuman',
        walletId: 'w_bank',
        note: 'Tenderloin Steak + Iced Tea',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      TransactionModel(
        id: 'tx_demo_1',
        title: 'Gaji Pokok Bulanan',
        amount: 14500000.0,
        type: TransactionType.income,
        categoryId: 'salary',
        categoryName: 'Gaji',
        walletId: 'w_bank',
        note: 'Payroll Direct Deposit',
        timestamp: now.subtract(const Duration(days: 6)),
      ),
      TransactionModel(
        id: 'tx_demo_2',
        title: 'Proyek Desain UI Mobile',
        amount: 3500000.0,
        type: TransactionType.income,
        categoryId: 'freelance',
        categoryName: 'Pekerjaan Lepas',
        walletId: 'w_mandiri',
        note: 'Pembayaran Termin 1',
        timestamp: now.subtract(const Duration(days: 4)),
      ),
      TransactionModel(
        id: 'tx_demo_3',
        title: 'Bagi Hasil Usaha',
        amount: 1250000.0,
        type: TransactionType.income,
        categoryId: 'business',
        categoryName: 'Bisnis & Usaha',
        walletId: 'w_bank',
        note: 'Profit Sharing Q3',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      TransactionModel(
        id: 'tx_demo_5',
        title: 'Kopi Susu Kenangan',
        amount: 28000.0,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'Makanan & Minuman',
        walletId: 'w_cash',
        note: 'Large, Less Sugar',
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
      TransactionModel(
        id: 'tx_demo_6',
        title: 'MRT Jakarta Bundaran HI',
        amount: 14000.0,
        type: TransactionType.expense,
        categoryId: 'transport',
        categoryName: 'Transportasi',
        walletId: 'w_ewallet',
        note: 'Tiket QR Stasiun MRT',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      TransactionModel(
        id: 'tx_demo_7',
        title: 'Belanja Mingguan Super Indo',
        amount: 345000.0,
        type: TransactionType.expense,
        categoryId: 'shopping',
        categoryName: 'Belanja',
        walletId: 'w_bank',
        note: 'Daging, Sayuran, dan Buah',
        timestamp: now.subtract(const Duration(days: 1, hours: 5)),
      ),
      TransactionModel(
        id: 'tx_demo_8',
        title: 'Tagihan Listrik PLN',
        amount: 285000.0,
        type: TransactionType.expense,
        categoryId: 'bills',
        categoryName: 'Tagihan & Utilitas',
        walletId: 'w_bank',
        note: 'Token Listrik 2200VA',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      TransactionModel(
        id: 'tx_demo_9',
        title: 'Bensin Shell V-Power',
        amount: 150000.0,
        type: TransactionType.expense,
        categoryId: 'transport',
        categoryName: 'Transportasi',
        walletId: 'w_cash',
        note: 'Full Tank Ron 95',
        timestamp: now.subtract(const Duration(days: 2, hours: 6)),
      ),
      TransactionModel(
        id: 'tx_demo_10',
        title: 'Nonton Bioskop IMAX XXI',
        amount: 120000.0,
        type: TransactionType.expense,
        categoryId: 'entertainment',
        categoryName: 'Hiburan',
        walletId: 'w_ewallet',
        note: '2 Tiket Studio IMAX',
        timestamp: now.subtract(const Duration(days: 3)),
      ),
      TransactionModel(
        id: 'tx_demo_11',
        title: 'Paket Internet IndiHome',
        amount: 385000.0,
        type: TransactionType.expense,
        categoryId: 'bills',
        categoryName: 'Tagihan & Utilitas',
        walletId: 'w_bank',
        note: 'Tagihan Bulanan 50 Mbps',
        timestamp: now.subtract(const Duration(days: 3, hours: 4)),
      ),
      TransactionModel(
        id: 'tx_demo_12',
        title: 'Makan Malam Sushi Tei',
        amount: 215000.0,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'Makanan & Minuman',
        walletId: 'w_bank',
        note: 'Salmon Set + Ocha',
        timestamp: now.subtract(const Duration(days: 4, hours: 1)),
      ),
      TransactionModel(
        id: 'tx_demo_13',
        title: 'Beli Kemeja & Celana Uniqlo',
        amount: 499000.0,
        type: TransactionType.expense,
        categoryId: 'shopping',
        categoryName: 'Belanja',
        walletId: 'w_bank',
        note: 'Kemeja Katun & Chino',
        timestamp: now.subtract(const Duration(days: 5)),
      ),
      TransactionModel(
        id: 'tx_demo_14',
        title: 'Vitamin & Suplemen Guardian',
        amount: 78000.0,
        type: TransactionType.expense,
        categoryId: 'health',
        categoryName: 'Kesehatan',
        walletId: 'w_ewallet',
        note: 'Vitamin C & Zinc',
        timestamp: now.subtract(const Duration(days: 5, hours: 4)),
      ),
      TransactionModel(
        id: 'tx_demo_15',
        title: 'Parkir & Saldo E-Toll',
        amount: 50000.0,
        type: TransactionType.expense,
        categoryId: 'transport',
        categoryName: 'Transportasi',
        walletId: 'w_ewallet',
        note: 'Top Up Flazz Mandiri',
        timestamp: now.subtract(const Duration(days: 6, hours: 2)),
      ),
      TransactionModel(
        id: 'tx_demo_16',
        title: 'Buku Pemrograman Flutter',
        amount: 165000.0,
        type: TransactionType.expense,
        categoryId: 'education',
        categoryName: 'Pendidikan',
        walletId: 'w_mandiri',
        note: 'E-Book Gramedia',
        timestamp: now.subtract(const Duration(days: 7)),
      ),
      TransactionModel(
        id: 'tx_demo_17',
        title: 'Nasi Goreng Spesial',
        amount: 32000.0,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'Makanan & Minuman',
        walletId: 'w_cash',
        note: 'Makan Malam Santai',
        timestamp: now.subtract(const Duration(days: 7, hours: 3)),
      ),
    ];
  }

  Future<void> saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        'version': '2.0.0',
        'currency': _currency,
        'userName': _userName,
        'userPhone': _userPhone,
        'userGender': _userGender,
        'isOnboardingCompleted': _isOnboardingCompleted,
        'isGuestMode': _isGuestMode,
        'dashboardViewMode': _dashboardViewMode.name,
        'hideBalanceSection': hideBalanceSection,
        'showBalanceSection': showBalanceSection,
        'themeMode': _themeMode.name,
        'hasNotificationPermission': _hasNotificationPermission,
        'isDailyReminderEnabled': _isDailyReminderEnabled,
        'dailyReminderTime': _dailyReminderTime,
        'dailyReminderTimes': _dailyReminderTimes,
        'isNotificationReaderEnabled': _isNotificationReaderEnabled,
        'notificationRules': _notificationRules.map((r) => r.toJson()).toList(),
        'pendingNotifications':
            _pendingNotifications.map((n) => n.toJson()).toList(),
        'syncWalletToTransactions': _syncWalletToTransactions,
        'lastCloudSyncTime': _lastCloudSyncTime?.toIso8601String(),
        'activityNotifications':
            _activityNotifications.map((a) => a.toJson()).toList(),
        'budget': _budget.toJson(),
        'categories': _categories.map((c) => c.toJson()).toList(),
        'wallets': _wallets.map((w) => w.toJson()).toList(),
        'transactions': _transactions.map((t) => t.toJson()).toList(),
      };
      await prefs.setString(_storageKey, jsonEncode(map));
    } catch (_) {}
  }

  // 4.1.1 Backup & Restore
  String exportDataAsJson() {
    final map = {
      'app': 'Yotro',
      'version': '2.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'userName': _userName,
      'currency': _currency,
      'dashboardViewMode': _dashboardViewMode.name,
      'hideBalanceSection': hideBalanceSection,
      'showBalanceSection': showBalanceSection,
      'themeMode': _themeMode.name,
      'hasNotificationPermission': _hasNotificationPermission,
      'isDailyReminderEnabled': _isDailyReminderEnabled,
      'dailyReminderTime': _dailyReminderTime,
      'dailyReminderTimes': _dailyReminderTimes,
      'isNotificationReaderEnabled': _isNotificationReaderEnabled,
      'notificationRules': _notificationRules.map((r) => r.toJson()).toList(),
      'pendingNotifications':
          _pendingNotifications.map((n) => n.toJson()).toList(),
      'budget': _budget.toJson(),
      'categories': _categories.map((c) => c.toJson()).toList(),
      'wallets': _wallets.map((w) => w.toJson()).toList(),
      'transactions': _transactions.map((t) => t.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  Map<String, dynamic>? validateBackupJson(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return null;
      final txList = decoded['transactions'];
      final walletList = decoded['wallets'];
      if (txList is! List || walletList is! List) return null;
      return {
        'valid': true,
        'txCount': txList.length,
        'walletCount': walletList.length,
        'currency': decoded['currency'] ?? _currency,
        'userName': decoded['userName'] ?? _userName,
        'version': decoded['version'] ?? 'Unknown',
        'exportedAt': decoded['exportedAt'] ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  Future<bool> restoreFromJson(String rawJson, {required bool merge}) async {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return false;

      final newTxs = (decoded['transactions'] as List<dynamic>?)
              ?.map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [];
      final newWallets = (decoded['wallets'] as List<dynamic>?)
              ?.map((w) => WalletModel.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [];
      final newCategories = (decoded['categories'] as List<dynamic>?)
              ?.map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [
            ...CategoryModel.defaultExpenseCategories,
            ...CategoryModel.defaultIncomeCategories,
          ];
      final newBudget = BudgetModel.fromJson(
          decoded['budget'] as Map<String, dynamic>? ?? {});
      final newCurrency = decoded['currency'] as String? ?? _currency;
      final newName = decoded['userName'] as String?;

      if (merge) {
        // Merge transactions avoiding duplicates
        final existingIds = _transactions.map((t) => t.id).toSet();
        for (final tx in newTxs) {
          if (!existingIds.contains(tx.id)) {
            _transactions.add(tx);
            existingIds.add(tx.id);
          }
        }
        _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Merge wallets
        final existingWalletIds = _wallets.map((w) => w.id).toSet();
        for (final w in newWallets) {
          if (!existingWalletIds.contains(w.id)) {
            _wallets.add(w);
            existingWalletIds.add(w.id);
          }
        }

        // Merge categories
        final existingCatIds = _categories.map((c) => c.id).toSet();
        for (final c in newCategories) {
          if (!existingCatIds.contains(c.id)) {
            _categories.add(c);
            existingCatIds.add(c.id);
          }
        }
      } else {
        // Full replace
        _transactions = newTxs;
        _wallets = newWallets;
        _categories = newCategories;
        _budget = newBudget;
        _currency = newCurrency;
        if (decoded.containsKey('dashboardViewMode')) {
          final modeStr = decoded['dashboardViewMode'] as String;
          _dashboardViewMode = DashboardViewMode.values.firstWhere(
            (m) => m.name == modeStr,
            orElse: () => DashboardViewMode.complete,
          );
        } else if (decoded.containsKey('hideBalanceSection')) {
          final hide = decoded['hideBalanceSection'] as bool? ?? false;
          _dashboardViewMode = hide
              ? DashboardViewMode.incomeExpense
              : DashboardViewMode.complete;
        } else if (decoded.containsKey('showBalanceSection')) {
          final show = decoded['showBalanceSection'] as bool? ?? true;
          _dashboardViewMode = show
              ? DashboardViewMode.complete
              : DashboardViewMode.incomeExpense;
        }
        if (decoded.containsKey('themeMode')) {
          final m = decoded['themeMode'].toString();
          if (m == 'system') {
            _themeMode = ThemeMode.system;
          } else if (m == 'light') {
            _themeMode = ThemeMode.light;
          } else {
            _themeMode = ThemeMode.dark;
          }
        }
        if (decoded.containsKey('dailyReminderTimes')) {
          _dailyReminderTimes = (decoded['dailyReminderTimes'] as List<dynamic>)
              .map((e) => e.toString())
              .toList();
        }
        if (decoded.containsKey('isNotificationReaderEnabled')) {
          _isNotificationReaderEnabled =
              decoded['isNotificationReaderEnabled'] as bool? ?? true;
        }
        if (decoded.containsKey('notificationRules')) {
          _notificationRules = (decoded['notificationRules'] as List<dynamic>)
              .map((r) => NotificationRule.fromJson(r as Map<String, dynamic>))
              .toList();
        }
        if (decoded.containsKey('pendingNotifications')) {
          _pendingNotifications =
              (decoded['pendingNotifications'] as List<dynamic>)
                  .map((n) =>
                      PendingNotification.fromJson(n as Map<String, dynamic>))
                  .toList();
        }
        if (newName != null && newName.isNotEmpty) {
          _userName = newName;
        }
      }

      notifyListeners();
      await saveData();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> completeOnboarding({
    required String name,
    required String phone,
    required String gender,
  }) async {
    _userName = name.trim().isEmpty ? 'Pengguna Yotro' : name.trim();
    _userPhone = phone.trim();
    _userGender = gender.trim().isEmpty ? 'Pria' : gender.trim();
    _isOnboardingCompleted = true;
    notifyListeners();
    await saveData();
    final granted = await requestNotificationPermission();
    if (granted || _hasNotificationPermission) {
      await toggleDailyReminder(true);
    }
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String gender,
  }) async {
    _userName = name.trim().isEmpty ? 'Pengguna Yotro' : name.trim();
    _userPhone = phone.trim();
    _userGender = gender.trim().isEmpty ? 'Pria' : gender.trim();
    notifyListeners();
    await saveData();
  }

  Future<void> continueAsGuest({String? name}) async {
    _isGuestMode = true;
    if (name != null && name.trim().isNotEmpty) {
      _userName = name.trim();
    } else if (_userName.trim().isEmpty) {
      _userName = 'Pengguna Tamu';
    }
    _isOnboardingCompleted = true;
    notifyListeners();
    await saveData();
  }

  Future<void> handleAuthSuccess({String? fullName}) async {
    _isGuestMode = false;
    final name = fullName?.trim().isNotEmpty == true
        ? fullName!.trim()
        : (SupabaseAuthService.userName ?? _userName);
    if (name.isNotEmpty) {
      _userName = name;
    }
    _isOnboardingCompleted = true;
    notifyListeners();
    await saveData();
  }

  Future<void> logout() async {
    _isOnboardingCompleted = false;
    _isGuestMode = false;
    notifyListeners();
    await saveData();
  }

  Future<void> deleteAccount() async {
    if (SupabaseAuthService.isAuthenticated) {
      try {
        await SupabaseAuthService.deleteUserAccount();
      } catch (e) {
        debugPrint('[TransactionProvider] Error saat deleteUserAccount di Supabase: $e');
      }
    }
    _transactions.clear();
    for (final w in _wallets) {
      w.balance = 0.0;
    }
    _budget = BudgetModel(overallMonthlyLimit: 0.0, categoryBudgets: {});
    _pendingNotifications.clear();
    _activityNotifications.clear();
    _userName = '';
    _userPhone = '';
    _userGender = 'Pria';
    _isOnboardingCompleted = false;
    _isGuestMode = false;
    notifyListeners();
    await saveData();
  }

  Future<void> resetToDemoData() async {
    _seedDefaults();
    if (_userName.isEmpty) {
      _userName = 'Ian Firdaus';
    }
    _isOnboardingCompleted = true;
    notifyListeners();
    await saveData();
  }

  Future<void> clearAllData() async {
    _transactions.clear();
    for (final w in _wallets) {
      w.balance = 0.0;
    }
    _budget = BudgetModel(overallMonthlyLimit: 0.0, categoryBudgets: {});
    _pendingNotifications.clear();
    _activityNotifications.clear();
    notifyListeners();
    await saveData();
  }

  Future<void> resetToDefaults() async {
    _seedDefaults();
    _currency = 'IDR';
    _userName = 'John Doe';
    _dashboardViewMode = DashboardViewMode.complete;
    _themeMode = ThemeMode.dark;
    _hasNotificationPermission = false;
    _isDailyReminderEnabled = false;
    _dailyReminderTime = '20:00';
    _isNotificationReaderEnabled = true;
    _notificationRules = NotificationRule.defaultRules;
    _pendingNotifications = [];
    _activityNotifications.clear();
    notifyListeners();
    await saveData();
  }

  Future<bool> requestNotificationPermission() async {
    if (!canUseNativePermission) {
      _hasNotificationPermission = true;
      notifyListeners();
      await saveData();
      return true;
    }
    try {
      final status = await Permission.notification.request().timeout(
            const Duration(seconds: 5),
            onTimeout: () => PermissionStatus.denied,
          );
      _hasNotificationPermission = status.isGranted;
      if (_hasNotificationPermission && !_isDailyReminderEnabled) {
        _isDailyReminderEnabled = true;
        if (_dailyReminderTimes.isEmpty) {
          _dailyReminderTimes = ['18:00', '19:00'];
        }
        await _rescheduleDailyReminder();
      }
      notifyListeners();
      await saveData();
      return _hasNotificationPermission;
    } catch (_) {
      _hasNotificationPermission = true;
      if (!_isDailyReminderEnabled) {
        _isDailyReminderEnabled = true;
        if (_dailyReminderTimes.isEmpty) {
          _dailyReminderTimes = ['18:00', '19:00'];
        }
        await _rescheduleDailyReminder();
      }
      notifyListeners();
      await saveData();
      return true;
    }
  }

  Future<bool> checkDeviceNotificationPermission() async {
    if (!canUseNativePermission) {
      return _hasNotificationPermission;
    }
    try {
      final status = await Permission.notification.status.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () => PermissionStatus.denied,
      );
      _hasNotificationPermission = status.isGranted;
      notifyListeners();
      return _hasNotificationPermission;
    } catch (_) {
      return _hasNotificationPermission;
    }
  }

  Future<void> openDeviceSettings() async {
    try {
      await openAppSettings();
    } catch (_) {}
  }

  Future<void> revokeNotificationPermission() async {
    _hasNotificationPermission = false;
    _isDailyReminderEnabled = false;
    _isNotificationReaderEnabled = false;
    notifyListeners();
    await saveData();
  }

  Future<bool> toggleDailyReminder(bool enabled) async {
    if (enabled && !_hasNotificationPermission) {
      return false;
    }
    _isDailyReminderEnabled = enabled;
    if (enabled) {
      await _rescheduleDailyReminder();
    } else {
      await NativeNotificationService.instance.cancelDailyReminder();
    }
    notifyListeners();
    await saveData();
    return true;
  }

  Future<void> setDailyReminderTime(String time) async {
    _dailyReminderTime = time;
    if (!_dailyReminderTimes.contains(time)) {
      _dailyReminderTimes.add(time);
      _dailyReminderTimes.sort();
    }
    if (_isDailyReminderEnabled) {
      await _rescheduleDailyReminder();
    }
    notifyListeners();
    await saveData();
  }

  Future<void> setDailyReminderTimes(List<String> times) async {
    _dailyReminderTimes = List.from(times);
    if (_dailyReminderTimes.isNotEmpty) {
      _dailyReminderTime = _dailyReminderTimes.first;
    }
    if (_isDailyReminderEnabled) {
      await _rescheduleDailyReminder();
    }
    notifyListeners();
    await saveData();
  }

  Future<void> addDailyReminderTime(String time) async {
    if (!_dailyReminderTimes.contains(time)) {
      _dailyReminderTimes.add(time);
      _dailyReminderTimes.sort();
      _dailyReminderTime = _dailyReminderTimes.first;
      if (_isDailyReminderEnabled) {
        await _rescheduleDailyReminder();
      }
      notifyListeners();
      await saveData();
    }
  }

  Future<void> removeDailyReminderTime(String time) async {
    _dailyReminderTimes.remove(time);
    if (_dailyReminderTimes.isNotEmpty) {
      _dailyReminderTime = _dailyReminderTimes.first;
    }
    if (_isDailyReminderEnabled) {
      await _rescheduleDailyReminder();
    }
    notifyListeners();
    await saveData();
  }

  Future<void> sendTestPushNotification() async {
    await NativeNotificationService.instance.showPushNotification(
      id: 9991,
      title: 'Pengingat Transaksi Yotro (Tes)',
      body:
          'Notifikasi sistem berhasil terhubung dan siap mengingatkan Anda setiap $_dailyReminderTime.',
      isReminder: true,
    );
  }

  Future<bool> toggleNotificationReader(bool enabled) async {
    if (!AppCapabilities.notificationReaderEnabled) {
      _isNotificationReaderEnabled = false;
      notifyListeners();
      await saveData();
      return false;
    }
    _isNotificationReaderEnabled = enabled;
    if (enabled) {
      _startNotificationListener();
    } else {
      NativeNotificationService.instance.stopListening();
    }
    notifyListeners();
    await saveData();
    return true;
  }

  void addNotificationRule(NotificationRule rule) {
    _notificationRules.add(rule);
    notifyListeners();
    saveData();
  }

  void updateNotificationRule(NotificationRule rule) {
    final idx = _notificationRules.indexWhere((r) => r.id == rule.id);
    if (idx != -1) {
      _notificationRules[idx] = rule;
      notifyListeners();
      saveData();
    }
  }

  void deleteNotificationRule(String id) {
    _notificationRules.removeWhere((r) => r.id == id);
    notifyListeners();
    saveData();
  }

  void toggleRule(String id, bool isEnabled) {
    final idx = _notificationRules.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _notificationRules[idx] =
          _notificationRules[idx].copyWith(isEnabled: isEnabled);
      notifyListeners();
      saveData();
    }
  }

  Future<bool> processIncomingNotification({
    required String sourceApp,
    required String message,
    String? packageName,
  }) async {
    if (!_isNotificationReaderEnabled) return false;

    // 1. Find rule for app or matching package name or message
    NotificationRule? rule;
    final lowerPkg = (packageName ?? '').toLowerCase();
    final lowerSrc = sourceApp.toLowerCase();
    final lowerMsg = message.toLowerCase();

    if (lowerPkg.isNotEmpty) {
      rule = _notificationRules.cast<NotificationRule?>().firstWhere(
            (r) =>
                r != null &&
                r.isEnabled &&
                r.packageName != null &&
                (lowerPkg == r.packageName!.toLowerCase() ||
                    lowerPkg.contains(r.packageName!.toLowerCase())),
            orElse: () => null,
          );
    }

    rule ??= _notificationRules.cast<NotificationRule?>().firstWhere(
      (r) {
        if (r == null || !r.isEnabled) return false;
        final appLower = r.appName.toLowerCase();
        return lowerSrc.contains(appLower) ||
            appLower.contains(lowerSrc) ||
            (lowerPkg.isNotEmpty && lowerPkg.contains(appLower));
      },
      orElse: () => null,
    );

    rule ??= _notificationRules.cast<NotificationRule?>().firstWhere(
          (r) =>
              r != null &&
              r.isEnabled &&
              lowerMsg.contains(r.appName.toLowerCase()),
          orElse: () => null,
        );

    // Token intersection matching (e.g., "Livin Mandiri" matches "Livin by Mandiri", "SeaBank" matches "SeaBank App")
    rule ??= _notificationRules.cast<NotificationRule?>().firstWhere(
      (r) {
        if (r == null || !r.isEnabled) return false;
        final tokens = r.appName
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), ' ')
            .split(' ')
            .where(
                (t) => t.length > 2 && t != 'the' && t != 'app' && t != 'dan');
        return tokens.any((t) =>
            lowerSrc.contains(t) ||
            lowerPkg.contains(t) ||
            lowerMsg.contains(t));
      },
      orElse: () => null,
    );

    // Fallback checks for major banks if rule is present
    if (rule == null) {
      if (lowerPkg.contains('bca') ||
          lowerSrc.contains('bca') ||
          lowerMsg.contains('bca')) {
        rule = _notificationRules.cast<NotificationRule?>().firstWhere(
              (r) => r != null && r.isEnabled && r.id == 'rule_bca',
              orElse: () => null,
            );
      } else if (lowerPkg.contains('seabank') ||
          lowerSrc.contains('seabank') ||
          lowerMsg.contains('seabank')) {
        rule = _notificationRules.cast<NotificationRule?>().firstWhere(
              (r) => r != null && r.isEnabled && r.id == 'rule_seabank',
              orElse: () => null,
            );
      } else if (lowerPkg.contains('gojek') ||
          lowerPkg.contains('gopay') ||
          lowerSrc.contains('gopay')) {
        rule = _notificationRules.cast<NotificationRule?>().firstWhere(
              (r) => r != null && r.isEnabled && r.id == 'rule_gopay',
              orElse: () => null,
            );
      }
    }

    // Dynamic Fallback: if message contains monetary signs (Rp/IDR) from any bank/e-wallet
    if (rule == null && (lowerMsg.contains('rp') || lowerMsg.contains('idr'))) {
      rule = NotificationRule(
        id: 'dynamic_${DateTime.now().millisecondsSinceEpoch}',
        appName: sourceApp.isNotEmpty ? sourceApp : 'Bank / E-Wallet',
        packageName: packageName,
        icon: Icons.notifications_active_rounded,
        triggerKeywords: const ['berhasil', 'sukses', 'transfer', 'pembayaran', 'qris', 'debit', 'kredit', 'top up', 'masuk', 'keluar', 'terima'],
        ignoreKeywords: const ['promo', 'diskon', 'cashback', 'voucher', 'penawaran'],
        defaultWalletName: _wallets.isNotEmpty ? _wallets.first.name : 'Dompet Utama',
        defaultCategoryName: 'Makanan & Minuman',
        isEnabled: true,
      );
    }

    if (rule == null) return false;

    // 2. Anti-Promo filter: check ignore keywords
    final ignoreKeywords = rule.ignoreKeywords;
    for (final kw in ignoreKeywords) {
      if (kw.trim().isNotEmpty && lowerMsg.contains(kw.toLowerCase().trim())) {
        return false; // Ignored promo message
      }
    }

    // 3. Trigger keywords check
    final triggerKeywords = rule.triggerKeywords;
    bool hasTrigger = false;
    for (final kw in triggerKeywords) {
      if (kw.trim().isNotEmpty && lowerMsg.contains(kw.toLowerCase().trim())) {
        hasTrigger = true;
        break;
      }
    }
    if (!hasTrigger) return false;

    // 4. Extract amount
    double? amount;
    final regexRp =
        RegExp(r'(?:rp\.?|idr)\s*([0-9][0-9\.,]*)', caseSensitive: false);
    final match = regexRp.firstMatch(message);
    if (match != null) {
      String rawNum = match.group(1) ?? '';
      while (rawNum.endsWith('.') || rawNum.endsWith(',')) {
        rawNum = rawNum.substring(0, rawNum.length - 1);
      }
      if (rawNum.contains(',') && rawNum.split(',').last.length == 2) {
        rawNum = rawNum.replaceAll('.', '').replaceAll(',', '.');
      } else {
        rawNum = rawNum.replaceAll('.', '').replaceAll(',', '');
      }
      amount = double.tryParse(rawNum);
    } else {
      final numRegex = RegExp(r'\b\d{1,3}(?:\.\d{3})+\b');
      final numMatch = numRegex.firstMatch(message);
      if (numMatch != null) {
        amount = double.tryParse(numMatch.group(0)!.replaceAll('.', ''));
      }
    }

    if (amount == null || amount <= 0) return false;

    // 5. Extract merchant/recipient note
    String title = 'Transaksi ${rule.appName}';
    final toMatch = RegExp(
      r'(?:ke|untuk|di)\s+([A-Za-z0-9\s]+?)(?:\s+(?:telah|berhasil|sukses|pada|sebesar|\.|$))',
      caseSensitive: false,
    ).firstMatch(message);
    if (toMatch != null && toMatch.group(1) != null) {
      String matchedStr = toMatch.group(1)!.trim();
      matchedStr = matchedStr
          .replaceAll(RegExp(r'\s+telah$', caseSensitive: false), '')
          .trim();
      if (matchedStr.isNotEmpty && matchedStr.length < 40) {
        title = matchedStr;
      }
    }

    // Detect Fund Flow: Income vs Expense vs Transfer
    TransactionType detectedType = TransactionType.expense;
    final incomeKeywords = [
      'masuk',
      'uang masuk',
      'saldo masuk',
      'diterima',
      'terima dari',
      'transfer dari',
      'kiriman dari',
      'top up berhasil',
      'topup berhasil',
      'top up sukses',
      'topup sukses',
      'kredit',
      'cr ',
      'setoran',
      'cashback',
      'bunga'
    ];
    final transferKeywords = [
      'transfer ke',
      'kirim ke',
      'trsf ke',
      'pindah dana',
      'transfer antar'
    ];

    if (incomeKeywords.any((k) => lowerMsg.contains(k))) {
      detectedType = TransactionType.income;
    } else if (transferKeywords.any((k) => lowerMsg.contains(k))) {
      detectedType = TransactionType.transfer;
    } else {
      detectedType = TransactionType.expense;
    }

    final targetWallet = rule.defaultWalletName.isNotEmpty
        ? rule.defaultWalletName
        : (_wallets.isNotEmpty ? _wallets.first.name : 'Dompet Utama');

    String targetCategory;
    if (detectedType == TransactionType.income) {
      targetCategory = _categories
          .firstWhere(
            (c) => c.type == TransactionType.income,
            orElse: () => CategoryModel.defaultIncomeCategories.first,
          )
          .name;
    } else {
      targetCategory = rule.defaultCategoryName.isNotEmpty
          ? rule.defaultCategoryName
          : 'Makanan & Minuman';
    }

    final pending = PendingNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      sourceApp: rule.appName,
      title: title,
      rawMessage: message,
      amount: amount,
      walletName: targetWallet,
      categoryName: targetCategory,
      timestamp: DateTime.now(),
      status: PendingNotificationStatus.pending,
      type: detectedType,
    );

    _pendingNotifications.insert(0, pending);
    notifyListeners();
    await saveData();

    // Trigger local push notification alert so user sees banner in OS status bar
    final formattedAmount =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
            .format(amount);
    final typeLabel = detectedType == TransactionType.income
        ? 'Uang Masuk'
        : detectedType == TransactionType.transfer
            ? 'Transfer'
            : 'Pengeluaran';
    NativeNotificationService.instance.showPushNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '$typeLabel Terdeteksi: ${rule.appName}',
      body: '$formattedAmount untuk $title. Ketuk untuk menyetujui.',
      payload: pending.id,
    );

    return true;
  }

  Future<void> approveNotification(String id) async {
    final idx = _pendingNotifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;

    final notif = _pendingNotifications[idx];

    final wallet = _wallets.firstWhere(
      (w) => w.name.toLowerCase() == notif.walletName.toLowerCase(),
      orElse: () => _wallets.isNotEmpty
          ? _wallets.first
          : WalletModel(
              id: 'w_default',
              name: 'Dompet Utama',
              type: 'Cash',
              balance: 0.0),
    );

    final category = _categories.firstWhere(
      (c) =>
          c.name.toLowerCase() == notif.categoryName.toLowerCase() &&
          c.type == notif.type,
      orElse: () => _categories.firstWhere(
        (c) => c.type == notif.type,
        orElse: () => _categories.first,
      ),
    );

    await addTransaction(
      title: notif.title,
      amount: notif.amount,
      type: notif.type,
      categoryId: category.id,
      categoryName: category.name,
      walletId: wallet.id,
      note: '${notif.sourceApp}: ${notif.rawMessage}',
    );

    _pendingNotifications.removeAt(idx);
    notifyListeners();
    await saveData();
  }

  Future<void> rejectNotification(String id) async {
    final idx = _pendingNotifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;

    _pendingNotifications[idx] = _pendingNotifications[idx]
        .copyWith(status: PendingNotificationStatus.rejected);
    notifyListeners();
    await saveData();
  }

  Future<void> clearAllTransactions() async {
    _transactions.clear();
    for (final w in _wallets) {
      w.balance = 0.0;
    }
    notifyListeners();
    await saveData();
  }

  void toggleBalanceVisibility() {
    _isBalanceVisible = !_isBalanceVisible;
    notifyListeners();
  }

  void setDashboardViewMode(DashboardViewMode mode) {
    _dashboardViewMode = mode;
    notifyListeners();
    saveData();
  }

  void setHideBalanceSection(bool value) {
    setDashboardViewMode(
        value ? DashboardViewMode.incomeExpense : DashboardViewMode.complete);
  }

  // Category Management CRUD
  Future<void> setSelectedCategories(List<CategoryModel> selectedCategories) async {
    _categories = List.from(selectedCategories);
    notifyListeners();
    await saveData();
  }

  Future<CategoryModel> addCategory({
    required String name,
    required TransactionType type,
    IconData? icon,
    String? emoji,
    String? iconName,
    int? colorValue,
  }) async {
    final effectiveEmoji = (emoji != null && emoji.trim().isNotEmpty)
        ? emoji.trim()
        : CategoryModel.fallbackEmojiFor(name);

    final cat = CategoryModel(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      type: type,
      icon: icon,
      emoji: effectiveEmoji,
      iconName: iconName,
      colorValue: colorValue,
      isDefault: false,
    );
    _categories.add(cat);
    notifyListeners();
    await saveData();
    return cat;
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required TransactionType type,
    IconData? icon,
    String? emoji,
    String? iconName,
    int? colorValue,
  }) async {
    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    final old = _categories[idx];
    final newName = name.trim().isEmpty ? old.name : name.trim();
    final effectiveEmoji = (emoji != null && emoji.trim().isNotEmpty)
        ? emoji.trim()
        : (old.emoji ?? CategoryModel.fallbackEmojiFor(newName));

    final updated = CategoryModel(
      id: id,
      name: newName,
      type: type,
      icon: icon ?? old.icon,
      emoji: effectiveEmoji,
      iconName: iconName ?? old.iconName,
      colorValue: colorValue ?? old.colorValue,
      isDefault: old.isDefault,
    );
    _categories[idx] = updated;

    if (old.name != newName) {
      _transactions = _transactions.map((tx) {
        if (tx.categoryId == id ||
            (tx.categoryName == old.name && tx.type == type)) {
          return TransactionModel(
            id: tx.id,
            title: tx.title == old.name ? newName : tx.title,
            amount: tx.amount,
            type: tx.type,
            categoryId: id,
            categoryName: newName,
            walletId: tx.walletId,
            fromWalletId: tx.fromWalletId,
            toWalletId: tx.toWalletId,
            note: tx.note,
            timestamp: tx.timestamp,
          );
        }
        return tx;
      }).toList();
    }

    notifyListeners();
    await saveData();
  }

  Future<void> deleteCategory(String id) async {
    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    final cat = _categories[idx];

    // Reassign existing transactions to 'Others' or fallback of matching type
    final fallbackCat = _categories.firstWhere(
      (c) =>
          c.type == cat.type &&
          (c.id.startsWith('other_') ||
              c.name.toLowerCase() == 'others' ||
              c.name.toLowerCase() == 'lainnya'),
      orElse: () => _categories.firstWhere(
          (c) => c.type == cat.type && c.id != id,
          orElse: () => cat),
    );

    _transactions = _transactions.map((tx) {
      if (tx.categoryId == id ||
          (tx.categoryName == cat.name && tx.type == cat.type)) {
        return TransactionModel(
          id: tx.id,
          title: tx.title == cat.name ? fallbackCat.name : tx.title,
          amount: tx.amount,
          type: tx.type,
          categoryId: fallbackCat.id,
          categoryName: fallbackCat.name,
          walletId: tx.walletId,
          fromWalletId: tx.fromWalletId,
          toWalletId: tx.toWalletId,
          note: tx.note,
          timestamp: tx.timestamp,
        );
      }
      return tx;
    }).toList();

    _categories.removeAt(idx);
    notifyListeners();
    await saveData();
  }

  void toggleHideBalanceSection() {
    setDashboardViewMode(
      _dashboardViewMode == DashboardViewMode.complete
          ? DashboardViewMode.incomeExpense
          : DashboardViewMode.complete,
    );
  }

  void setShowBalanceSection(bool value) => setHideBalanceSection(!value);
  void toggleShowBalanceSection() => toggleHideBalanceSection();

  void setPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  void setCurrency(String cur) {
    _currency = cur;
    notifyListeners();
    saveData();
  }

  Future<void> setSyncWalletToTransactions(bool value) async {
    if (_syncWalletToTransactions != value) {
      _syncWalletToTransactions = value;
      notifyListeners();
      await saveData();
    }
  }

  void applyCloudSnapshot({
    List<WalletModel>? wallets,
    List<CategoryModel>? categories,
    List<TransactionModel>? transactions,
    BudgetModel? budget,
    String? userName,
    String? userPhone,
    String? userGender,
  }) {
    if (userName != null && userName.trim().isNotEmpty) _userName = userName.trim();
    if (userPhone != null && userPhone.trim().isNotEmpty) _userPhone = userPhone.trim();
    if (userGender != null && userGender.trim().isNotEmpty) _userGender = userGender.trim();
    if (wallets != null && wallets.isNotEmpty) _wallets = wallets;
    if (categories != null && categories.isNotEmpty) _categories = categories;
    if (transactions != null) _transactions = transactions;
    if (budget != null) _budget = budget;
    _lastCloudSyncTime = DateTime.now();
    notifyListeners();
    saveData();
  }

  Future<bool> syncWithCloud({bool forceUpload = false}) async {
    if (!SupabaseSyncService.canSync) return false;
    _isSyncingWithCloud = true;
    notifyListeners();

    bool success = false;
    try {
      if (forceUpload) {
        success = await SupabaseSyncService.uploadAllLocalData(this);
      } else {
        success = await SupabaseSyncService.pullCloudData(this);
        if (success && _transactions.isEmpty) {
          await SupabaseSyncService.uploadAllLocalData(this);
        }
      }
      if (success) {
        _lastCloudSyncTime = DateTime.now();
        await saveData();
      }
    } catch (_) {
      success = false;
    } finally {
      _isSyncingWithCloud = false;
      notifyListeners();
    }
    return success;
  }

  // 4.2 Business Rules Execution
  Future<TransactionModel> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required String categoryName,
    required String categoryId,
    required String walletId,
    String? fromWalletId,
    String? toWalletId,
    String note = '',
    DateTime? date,
  }) async {
    final tx = TransactionModel(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim().isEmpty ? categoryName : title.trim(),
      amount: amount,
      type: type,
      categoryId: categoryId,
      categoryName: categoryName,
      walletId: walletId,
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      note: note.trim(),
      timestamp: date ?? DateTime.now(),
    );

    // Business Rules:
    if (type == TransactionType.transfer &&
        fromWalletId != null &&
        toWalletId != null) {
      if (fromWalletId == toWalletId) {
        throw ArgumentError('Dompet asal dan tujuan transfer tidak boleh sama.');
      }
      final fromW = _wallets.cast<WalletModel?>().firstWhere(
          (w) => w?.id == fromWalletId,
          orElse: () => _wallets.isNotEmpty ? _wallets.first : null);
      final toW = _wallets.cast<WalletModel?>().firstWhere(
          (w) => w?.id == toWalletId,
          orElse: () => _wallets.isNotEmpty ? _wallets.first : null);
      if (fromW != null) fromW.balance -= amount;
      if (toW != null) toW.balance += amount;
    } else {
      final w = _wallets.cast<WalletModel?>().firstWhere(
          (w) => w?.id == walletId,
          orElse: () => _wallets.isNotEmpty ? _wallets.first : null);
      if (w != null) {
        if (type == TransactionType.income) {
          w.balance += amount;
        } else if (type == TransactionType.expense) {
          w.balance -= amount;
        }
      }
    }

    _transactions.insert(0, tx);

    final typeText = type == TransactionType.expense
        ? 'Catat Pengeluaran Berhasil'
        : (type == TransactionType.income
            ? 'Catat Pemasukan Berhasil'
            : 'Catat Transfer Berhasil');
    final w = _wallets
        .cast<WalletModel?>()
        .firstWhere((w) => w?.id == walletId, orElse: () => null);
    final wName = w?.name ?? 'Dompet';
    final desc = type == TransactionType.transfer
        ? 'Transfer ${formatCurrency(amount)} berhasil dicatat.'
        : '${tx.title} sebesar ${formatCurrency(amount)} dicatat ke $wName.';
    addActivityNotification(
      title: typeText,
      message: desc,
      type: type,
      amount: amount,
      timestamp: date ?? DateTime.now(),
    );

    notifyListeners();
    await saveData();
    unawaited(SupabaseSyncService.syncSingleTransaction(tx));
    return tx;
  }

  Future<void> deleteTransaction(String txId) async {
    final idx = _transactions.indexWhere((t) => t.id == txId);
    if (idx == -1) return;
    final tx = _transactions[idx];

    // Revert wallet impact
    if (tx.type == TransactionType.transfer &&
        tx.fromWalletId != null &&
        tx.toWalletId != null) {
      final fromW = _wallets
          .cast<WalletModel?>()
          .firstWhere((w) => w?.id == tx.fromWalletId, orElse: () => null);
      final toW = _wallets
          .cast<WalletModel?>()
          .firstWhere((w) => w?.id == tx.toWalletId, orElse: () => null);
      if (fromW != null) fromW.balance += tx.amount;
      if (toW != null) toW.balance -= tx.amount;
    } else {
      final w = _wallets
          .cast<WalletModel?>()
          .firstWhere((w) => w?.id == tx.walletId, orElse: () => null);
      if (w != null) {
        if (tx.type == TransactionType.income) {
          w.balance -= tx.amount;
        } else if (tx.type == TransactionType.expense) {
          w.balance += tx.amount;
        }
      }
    }

    _transactions.removeAt(idx);

    addActivityNotification(
      title: 'Transaksi Dihapus',
      message:
          '${tx.title} sebesar ${formatCurrency(tx.amount)} telah dihapus dari riwayat.',
      type: tx.type,
      amount: tx.amount,
      timestamp: DateTime.now(),
    );

    notifyListeners();
    await saveData();
    unawaited(SupabaseSyncService.syncSingleTransaction(tx, isDelete: true));
  }
  Future<void> addWallet({
    required String name,
    required String type,
    double initialBalance = 0.0,
    bool? syncToTransaction,
  }) async {
    final shouldSync =
        (syncToTransaction ?? _syncWalletToTransactions) && initialBalance > 0;
    final wallet = WalletModel(
      id: 'w_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      type: type,
      balance: shouldSync ? 0.0 : initialBalance,
    );
    _wallets.add(wallet);

    if (shouldSync) {
      await addTransaction(
        title: 'Saldo Awal - ${wallet.name}',
        amount: initialBalance,
        type: TransactionType.income,
        categoryName: 'Lainnya',
        categoryId: 'other_inc',
        walletId: wallet.id,
        note: 'Saldo awal akun ${wallet.name}',
        date: DateTime.now(),
      );
    } else {
      notifyListeners();
      await saveData();
    }
  }

  Future<void> updateWallet({
    required String id,
    required String name,
    required String type,
    double? balance,
    bool? syncToTransaction,
  }) async {
    final idx = _wallets.indexWhere((w) => w.id == id);
    if (idx == -1) return;
    _wallets[idx].name = name.trim();
    _wallets[idx].type = type;

    if (balance != null) {
      final oldBal = _wallets[idx].balance;
      final diff = balance - oldBal;
      final shouldSync =
          (syncToTransaction ?? _syncWalletToTransactions) && (diff.abs() > 0.001);

      if (shouldSync) {
        if (diff > 0) {
          await addTransaction(
            title: 'Penyesuaian Saldo - ${_wallets[idx].name}',
            amount: diff,
            type: TransactionType.income,
            categoryName: 'Lainnya',
            categoryId: 'other_inc',
            walletId: id,
            note:
                'Penyesuaian saldo ${_wallets[idx].name} (+${formatCurrency(diff)})',
            date: DateTime.now(),
          );
        } else {
          await addTransaction(
            title: 'Penyesuaian Saldo - ${_wallets[idx].name}',
            amount: diff.abs(),
            type: TransactionType.expense,
            categoryName: 'Lainnya',
            categoryId: 'other_exp',
            walletId: id,
            note:
                'Penyesuaian saldo ${_wallets[idx].name} (-${formatCurrency(diff.abs())})',
            date: DateTime.now(),
          );
        }
      } else {
        _wallets[idx].balance = balance;
        notifyListeners();
        await saveData();
      }
    } else {
      notifyListeners();
      await saveData();
    }
  }

  Future<void> deleteWallet(String id) async {
    if (_wallets.length <= 1) {
      // Must keep at least 1 wallet
      return;
    }
    final fallbackWallet = _wallets.firstWhere((w) => w.id != id);

    // Reassign transactions of deleted wallet to fallback wallet
    _transactions = _transactions.map((tx) {
      String? newWalletId = tx.walletId == id ? fallbackWallet.id : tx.walletId;
      String? newFrom =
          tx.fromWalletId == id ? fallbackWallet.id : tx.fromWalletId;
      String? newTo = tx.toWalletId == id ? fallbackWallet.id : tx.toWalletId;
      return TransactionModel(
        id: tx.id,
        title: tx.title,
        amount: tx.amount,
        type: tx.type,
        categoryId: tx.categoryId,
        categoryName: tx.categoryName,
        walletId: newWalletId,
        fromWalletId: newFrom,
        toWalletId: newTo,
        note: tx.note,
        timestamp: tx.timestamp,
      );
    }).toList();

    _wallets.removeWhere((w) => w.id == id);
    notifyListeners();
    await saveData();
  }

  // 4.4 Budgeting Updates
  Future<void> updateOverallBudget(double newLimit) async {
    _budget.overallMonthlyLimit = newLimit;
    notifyListeners();
    await saveData();
  }

  Future<void> updateCategoryBudget(String category, double limit) async {
    _budget.categoryBudgets[category] = limit;
    notifyListeners();
    await saveData();
  }

  Future<void> deleteCategoryBudget(String category) async {
    _budget.categoryBudgets.remove(category);
    notifyListeners();
    await saveData();
  }

  // Formatting helpers
  static String formatRupiah(num amount) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount.round());
  }

  String formatCurrency(double amount) {
    if (_currency == 'IDR') {
      final formatter = NumberFormat.currency(
          locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      return formatter.format(amount.round());
    }
    final formatter =
        NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);
    return formatter.format(amount);
  }
}
