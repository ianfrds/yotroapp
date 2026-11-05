import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/notification_rule_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/nested_card.dart';
import '../widgets/modal_card_sheet.dart';
import '../widgets/standard_screen_header.dart';
import '../widgets/notification_permission_sheet.dart';
import '../services/native_notification_service.dart';

class NotificationReaderScreen extends StatefulWidget {
  const NotificationReaderScreen({super.key});

  static MaterialPageRoute route() {
    return MaterialPageRoute(
      builder: (_) => const NotificationReaderScreen(),
    );
  }

  @override
  State<NotificationReaderScreen> createState() =>
      _NotificationReaderScreenState();
}

class _NotificationReaderScreenState extends State<NotificationReaderScreen> {
  final TextEditingController _testMessageController = TextEditingController();
  bool _isListenerPermissionGranted = true;
  bool _showRestrictedHelp = false;

  @override
  void initState() {
    super.initState();
    _checkListenerPermission();
  }

  Future<void> _checkListenerPermission() async {
    if (!canUseNativePermission) return;
    final granted =
        await NativeNotificationService.instance.isListenerPermissionGranted();
    if (mounted) {
      setState(() => _isListenerPermissionGranted = granted);
    }
  }

  @override
  void dispose() {
    _testMessageController.dispose();
    super.dispose();
  }

  void _runSimulation(
      TransactionProvider provider, String sourceApp, String message) async {
    final result = await provider.processIncomingNotification(
      sourceApp: sourceApp,
      message: message,
    );

    if (!mounted) return;

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF131A26),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF39D98A), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Transaksi dari $sourceApp berhasil dideteksi! Silakan beri persetujuan di Beranda.',
                  style: GoogleFonts.manrope(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF131A26),
          content: Row(
            children: [
              const Icon(Icons.block_rounded,
                  color: Color(0xFFFF6B7A), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pesan diabaikan otomatis karena mengandung kata kunci promosi atau tidak cocok dengan pemicu pengeluaran.',
                  style: GoogleFonts.manrope(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showAddRuleSheet(BuildContext context, TransactionProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor =
        isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final fieldBg =
        isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC);
    final fieldBorder =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1);

    final appNameController = TextEditingController();
    String? selectedPackageName;
    final triggerController =
        TextEditingController(text: 'QRIS, Transfer, Pembayaran, Berhasil');
    final ignoreController =
        TextEditingController(text: 'promo, diskon, cashback, voucher');
    String selectedWallet = provider.wallets.isNotEmpty
        ? provider.wallets.first.name
        : 'Dompet Utama';
    String selectedCategory = 'Food & Beverage';

    showModalCardSheet(
      context: context,
      title: 'Tambah Aturan Notifikasi',
      titleIcon: Icons.add_circle_outline_rounded,
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nama Aplikasi / Bank / E-Wallet',
                style: GoogleFonts.manrope(color: mutedColor, fontSize: 11.5),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: appNameController,
                style: GoogleFonts.manrope(color: textColor, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Contoh: Bank Jago, OVO, DANA',
                  hintStyle: GoogleFonts.manrope(
                      color: isDark
                          ? const Color(0xFF5A667A)
                          : const Color(0xFF94A3B8),
                      fontSize: 12.5),
                  filled: true,
                  fillColor: fieldBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: fieldBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: fieldBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF55C7FF))),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kata Kunci Pemicu (pisahkan koma)',
                style: GoogleFonts.manrope(color: mutedColor, fontSize: 11.5),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: triggerController,
                style: GoogleFonts.manrope(color: textColor, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'QRIS, Transfer, Berhasil',
                  hintStyle: GoogleFonts.manrope(
                      color: isDark
                          ? const Color(0xFF5A667A)
                          : const Color(0xFF94A3B8),
                      fontSize: 12.5),
                  filled: true,
                  fillColor: fieldBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: fieldBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: fieldBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF55C7FF))),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kata Kunci Diabaikan / Anti-Promo',
                style: GoogleFonts.manrope(color: mutedColor, fontSize: 11.5),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: ignoreController,
                style: GoogleFonts.manrope(color: textColor, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'promo, diskon, cashback, voucher',
                  hintStyle: GoogleFonts.manrope(
                      color: isDark
                          ? const Color(0xFF5A667A)
                          : const Color(0xFF94A3B8),
                      fontSize: 12.5),
                  filled: true,
                  fillColor: fieldBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: fieldBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: fieldBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF55C7FF))),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Target Dompet',
                            style: GoogleFonts.manrope(
                                color: mutedColor, fontSize: 11.5)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: fieldBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: provider.wallets
                                      .any((w) => w.name == selectedWallet)
                                  ? selectedWallet
                                  : (provider.wallets.isNotEmpty
                                      ? provider.wallets.first.name
                                      : null),
                              isExpanded: true,
                              dropdownColor: isDark
                                  ? const Color(0xFF131A26)
                                  : Colors.white,
                              style: GoogleFonts.manrope(
                                  color: textColor, fontSize: 12.5),
                              items: provider.wallets.map((w) {
                                return DropdownMenuItem(
                                    value: w.name, child: Text(w.name));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setSheetState(() => selectedWallet = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kategori Default',
                            style: GoogleFonts.manrope(
                                color: mutedColor, fontSize: 11.5)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: fieldBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              isExpanded: true,
                              dropdownColor: isDark
                                  ? const Color(0xFF131A26)
                                  : Colors.white,
                              style: GoogleFonts.manrope(
                                  color: textColor, fontSize: 12.5),
                              items: provider.categories
                                  .where(
                                      (c) => c.type == TransactionType.expense)
                                  .map((c) => DropdownMenuItem(
                                      value: c.name,
                                      child: Text(c.name,
                                          overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setSheetState(() => selectedCategory = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF02539A),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final app = appNameController.text.trim();
                  if (app.isEmpty) return;
                  final triggers = triggerController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                  final ignores = ignoreController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();

                  final rule = NotificationRule(
                    id: 'rule_${DateTime.now().millisecondsSinceEpoch}',
                    appName: app,
                    packageName: selectedPackageName,
                    icon: Icons.account_balance_wallet_outlined,
                    triggerKeywords: triggers.isNotEmpty
                        ? triggers
                        : ['QRIS', 'Transfer', 'Berhasil'],
                    ignoreKeywords: ignores.isNotEmpty
                        ? ignores
                        : ['promo', 'diskon', 'cashback'],
                    defaultWalletName: selectedWallet,
                    defaultCategoryName: selectedCategory,
                    isEnabled: true,
                  );

                  provider.addNotificationRule(rule);
                  Navigator.pop(context);
                },
                child: Text(
                  'Simpan Aturan',
                  style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditRuleModal(
    BuildContext context,
    TransactionProvider provider,
    NotificationRule rule,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor =
        isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final fieldBg =
        isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF8FAFC);
    final fieldBorder =
        isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFCBD5E1);

    final appNameController = TextEditingController(text: rule.appName);
    final triggerController =
        TextEditingController(text: rule.triggerKeywords.join(', '));
    final ignoreController =
        TextEditingController(text: rule.ignoreKeywords.join(', '));
    String? selectedPackageName = rule.packageName;
    String selectedWallet = rule.defaultWalletName;
    String selectedCategory = rule.defaultCategoryName;

    showModalCardSheet(
      context: context,
      title: 'Ubah Aturan: ${rule.appName}',
      titleIcon: Icons.edit_note_rounded,
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nama Aplikasi',
                style: GoogleFonts.manrope(color: mutedColor, fontSize: 11.5),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: appNameController,
                style: GoogleFonts.manrope(color: textColor, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Nama Aplikasi',
                  filled: true,
                  fillColor: fieldBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: fieldBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: fieldBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF55C7FF))),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Package Name Android',
                    style:
                        GoogleFonts.manrope(color: mutedColor, fontSize: 11.5),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: fieldBorder),
                ),
                child: Text(
                  selectedPackageName != null && selectedPackageName!.isNotEmpty
                      ? selectedPackageName!
                      : 'Belum terikat package (semua pesan app)',
                  style: GoogleFonts.manrope(
                    color: selectedPackageName != null ? textColor : mutedColor,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kata Kunci Pemicu (pisahkan dengan koma)',
                style: GoogleFonts.manrope(color: mutedColor, fontSize: 11.5),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: triggerController,
                style: GoogleFonts.manrope(color: textColor, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'QRIS, Transfer, Pembayaran, Berhasil, Masuk',
                  filled: true,
                  fillColor: fieldBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: fieldBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: fieldBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF55C7FF))),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kata Kunci Diabaikan / Anti-Promo (pisahkan dengan koma)',
                style: GoogleFonts.manrope(color: mutedColor, fontSize: 11.5),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: ignoreController,
                style: GoogleFonts.manrope(color: textColor, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'promo, diskon, cashback, voucher, penawaran',
                  filled: true,
                  fillColor: fieldBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: fieldBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: fieldBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF55C7FF))),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Target Dompet',
                            style: GoogleFonts.manrope(
                                color: mutedColor, fontSize: 11.5)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: fieldBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: provider.wallets
                                      .any((w) => w.name == selectedWallet)
                                  ? selectedWallet
                                  : (provider.wallets.isNotEmpty
                                      ? provider.wallets.first.name
                                      : null),
                              isExpanded: true,
                              dropdownColor: isDark
                                  ? const Color(0xFF131A26)
                                  : Colors.white,
                              style: GoogleFonts.manrope(
                                  color: textColor, fontSize: 12.5),
                              items: provider.wallets.map((w) {
                                return DropdownMenuItem(
                                    value: w.name, child: Text(w.name));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setSheetState(() => selectedWallet = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kategori Default',
                            style: GoogleFonts.manrope(
                                color: mutedColor, fontSize: 11.5)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: fieldBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              isExpanded: true,
                              dropdownColor: isDark
                                  ? const Color(0xFF131A26)
                                  : Colors.white,
                              style: GoogleFonts.manrope(
                                  color: textColor, fontSize: 12.5),
                              items: provider.categories
                                  .map((c) => DropdownMenuItem(
                                      value: c.name,
                                      child: Text(c.name,
                                          overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setSheetState(() => selectedCategory = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF6B7A),
                        side: BorderSide(
                            color: const Color(0xFFFF6B7A).withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        provider.deleteNotificationRule(rule.id);
                        Navigator.pop(context);
                      },
                      child: Text('Hapus Aturan',
                          style: GoogleFonts.manrope(
                              fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF02539A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final app = appNameController.text.trim();
                        if (app.isEmpty) return;
                        final triggers = triggerController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();
                        final ignores = ignoreController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();

                        final updated = rule.copyWith(
                          appName: app,
                          packageName: selectedPackageName,
                          triggerKeywords: triggers.isNotEmpty
                              ? triggers
                              : rule.triggerKeywords,
                          ignoreKeywords: ignores.isNotEmpty
                              ? ignores
                              : rule.ignoreKeywords,
                          defaultWalletName: selectedWallet,
                          defaultCategoryName: selectedCategory,
                        );

                        provider.updateNotificationRule(updated);
                        Navigator.pop(context);
                      },
                      child: Text('Simpan',
                          style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF1C2229) : const Color(0xFFF4F5F7);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          children: [
            const StandardScreenHeader(
              title: 'Pembaca Notifikasi',
            ),
            const SizedBox(height: 14),

            if (!provider.hasNotificationPermission) ...[
              GestureDetector(
                onTap: () => showNotificationPermissionSheet(
                  context: context,
                  featureTitle: 'Pembaca Notifikasi',
                  onGranted: () => provider.toggleNotificationReader(true),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE58B29).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFE58B29).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE58B29).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFE58B29), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Izin Notifikasi Belum Aktif',
                              style: GoogleFonts.interTight(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Ketuk di sini untuk mengizinkan akses agar notifikasi dapat dideteksi.',
                              style: GoogleFonts.manrope(
                                color: isDark
                                    ? const Color(0xFF8EA4BE)
                                    : const Color(0xFF64748B),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFFE58B29), size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (canUseNativePermission && !_isListenerPermissionGranted) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE58B29).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFE58B29).withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.security_update_warning_rounded,
                            color: Color(0xFFE58B29), size: 19),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Akses Notifikasi Belum Aktif',
                            style: GoogleFonts.interTight(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Agar Yotro dapat mendeteksi mutasi otomatis secara real-time, izinkan akses notifikasi di pengaturan Android HP Anda.',
                      style: GoogleFonts.manrope(
                        color: isDark
                            ? const Color(0xFF8EA4BE)
                            : const Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await NativeNotificationService.instance
                                    .requestListenerPermission();
                                await _checkListenerPermission();
                              },
                              icon: const Icon(
                                  Icons.notifications_active_rounded,
                                  size: 15),
                              label: Text(
                                '1. Buka Izin Notifikasi',
                                style: GoogleFonts.manrope(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE58B29),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: OutlinedButton.icon(
                              onPressed: () => provider.openDeviceSettings(),
                              icon:
                                  const Icon(Icons.settings_outlined, size: 15),
                              label: Text(
                                '2. Info Aplikasi',
                                style: GoogleFonts.manrope(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: isDark
                                        ? Colors.white24
                                        : const Color(0xFFCBD5E1)),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(
                            () => _showRestrictedHelp = !_showRestrictedHelp);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              _showRestrictedHelp
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.help_outline_rounded,
                              size: 14,
                              color: const Color(0xFF55C7FF),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _showRestrictedHelp
                                    ? 'Sembunyikan panduan Setelan Terbatas'
                                    : 'Muncul "Aplikasi tidak diberi akses" di Android 13/14+?',
                                style: GoogleFonts.manrope(
                                  color: const Color(0xFF55C7FF),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showRestrictedHelp) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withOpacity(0.25)
                              : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cara Buka Kunci "Setelan Terbatas" Android:',
                              style: GoogleFonts.interTight(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildRestrictedStep('1',
                                'Ketuk tombol "2. Info Aplikasi" di atas.'),
                            _buildRestrictedStep('2',
                                'Di pojok kanan atas Info Aplikasi Yotro, ketuk titik tiga (⋮).'),
                            _buildRestrictedStep('3',
                                'Pilih "Izinkan setelan terbatas" (Allow restricted settings).'),
                            _buildRestrictedStep('4',
                                'Masukkan PIN / Sidik Jari verifikasi keamanan HP Anda.'),
                            _buildRestrictedStep('5',
                                'Kembali ke sini lalu ketuk "1. Buka Izin Notifikasi" untuk mengaktifkan.'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Card 1: Master Toggle & Status
            NestedCard(
              title: 'Layanan Deteksi Otomatis',
              innerPadding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: provider.isNotificationReaderEnabled
                          ? const Color(0xFF39D98A).withOpacity(0.14)
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: provider.isNotificationReaderEnabled
                          ? const Color(0xFF39D98A)
                          : const Color(0xFF8CA7C5),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deteksi Notifikasi Transaksi',
                          style: GoogleFonts.interTight(
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          provider.isNotificationReaderEnabled
                              ? 'Aktif — Memindai SMS & notifikasi bank/e-wallet'
                              : 'Nonaktif — Notifikasi tidak akan dipindai',
                          style: GoogleFonts.manrope(
                            color: isDark
                                ? const Color(0xFF8EA4BE)
                                : const Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: provider.isNotificationReaderEnabled,
                    activeColor: const Color(0xFF55C7FF),
                    onChanged: (val) {
                      if (val) {
                        if (!provider.hasNotificationPermission) {
                          showNotificationPermissionSheet(
                            context: context,
                            featureTitle: 'Pembaca Notifikasi',
                            onGranted: () =>
                                provider.toggleNotificationReader(true),
                          );
                        } else {
                          provider.toggleNotificationReader(true);
                        }
                      } else {
                        provider.toggleNotificationReader(false);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Card 2: Simulator Pengujian Notifikasi
            NestedCard(
              title: 'Uji Coba Deteksi Notifikasi',
              innerPadding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulasikan pesan yang masuk ke perangkat. Transaksi valid akan otomatis diarahkan ke Beranda untuk disetujui, sedangkan pesan promo akan ditolak otomatis.',
                    style: GoogleFonts.manrope(
                      color: isDark
                          ? const Color(0xFF8EA4BE)
                          : const Color(0xFF64748B),
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick Simulation Buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.arrow_downward_rounded,
                            size: 14, color: Color(0xFF34D399)),
                        backgroundColor: isDark
                            ? const Color(0xFF34D399).withOpacity(0.12)
                            : const Color(0xFFECFDF5),
                        label: Text(
                          'myBCA: Masuk Rp 500.000',
                          style: GoogleFonts.manrope(
                            fontSize: 11.5,
                            color: const Color(0xFF34D399),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          _runSimulation(
                            provider,
                            'myBCA',
                            'myBCA: Transfer masuk Rp 500.000 dari Budi Santoso BERHASIL pada 04/11.',
                          );
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.arrow_upward_rounded,
                            size: 14, color: Color(0xFF55C7FF)),
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFFE2E8F0),
                        label: Text(
                          'myBCA: QRIS Rp 45.000',
                          style: GoogleFonts.manrope(
                            fontSize: 11.5,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: () {
                          _runSimulation(
                            provider,
                            'myBCA',
                            'myBCA: Pembayaran QRIS Rp 45.000 ke Kopi Kenangan BERHASIL pada 04/11.',
                          );
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.arrow_upward_rounded,
                            size: 14, color: Color(0xFF55C7FF)),
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFFE2E8F0),
                        label: Text(
                          'GoPay: Bayar Rp 22.000',
                          style: GoogleFonts.manrope(
                            fontSize: 11.5,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: () {
                          _runSimulation(
                            provider,
                            'GoPay',
                            'GoPay: Pembayaran berhasil Rp 22.000 untuk Martabak Manis.',
                          );
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.block_rounded,
                            size: 14, color: Color(0xFFFF6B7A)),
                        backgroundColor: isDark
                            ? const Color(0xFFFF6B7A).withOpacity(0.12)
                            : const Color(0xFFFFE4E6),
                        label: Text(
                          'BCA Promo Cashback (Abaikan)',
                          style: GoogleFonts.manrope(
                            fontSize: 11.5,
                            color: const Color(0xFFFF6B7A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          _runSimulation(
                            provider,
                            'myBCA',
                            'myBCA info: Dapatkan promo diskon cashback 50% hingga Rp 25.000 hanya hari ini!',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Card 3: Daftar Aturan & Trigger Aplikasi
            NestedCard(
              title: 'Aturan & Filter Aplikasi',
              action: '+ Tambah',
              onActionTap: () => _showAddRuleSheet(context, provider),
              innerPadding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.notificationRules.length,
                separatorBuilder: (_, __) => Divider(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : const Color(0xFFE2E8F0),
                  height: 1,
                  indent: 12,
                  endIndent: 12,
                ),
                itemBuilder: (context, index) {
                  final rule = provider.notificationRules[index];
                  return InkWell(
                    onTap: () => _showEditRuleModal(context, provider, rule),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF182230)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              rule.icon,
                              color: isDark
                                  ? const Color(0xFF8CA7C5)
                                  : const Color(0xFF475569),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      rule.appName,
                                      style: GoogleFonts.interTight(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.06)
                                            : const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        rule.defaultWalletName,
                                        style: GoogleFonts.manrope(
                                          color: isDark
                                              ? const Color(0xFF8EA4BE)
                                              : const Color(0xFF64748B),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (rule.packageName != null &&
                                        rule.packageName!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF55C7FF)
                                              .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          rule.packageName!,
                                          style: GoogleFonts.manrope(
                                            color: const Color(0xFF55C7FF),
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Pemicu: ',
                                      style: GoogleFonts.manrope(
                                          color: const Color(0xFF39D98A),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Expanded(
                                      child: Text(
                                        rule.triggerKeywords.take(3).join(', '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.manrope(
                                          color: isDark
                                              ? const Color(0xFF8EA4BE)
                                              : const Color(0xFF64748B),
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Abaikan: ',
                                      style: GoogleFonts.manrope(
                                          color: const Color(0xFFFF6B7A),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Expanded(
                                      child: Text(
                                        rule.ignoreKeywords.take(3).join(', '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.manrope(
                                          color: isDark
                                              ? const Color(0xFF8EA4BE)
                                              : const Color(0xFF64748B),
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: isDark
                                  ? const Color(0xFF8EA4BE)
                                  : const Color(0xFF64748B),
                            ),
                            tooltip: 'Ubah Aturan',
                            onPressed: () =>
                                _showEditRuleModal(context, provider, rule),
                          ),
                          Switch.adaptive(
                            value: rule.isEnabled,
                            activeColor: const Color(0xFF55C7FF),
                            onChanged: (val) =>
                                provider.toggleRule(rule.id, val),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestrictedStep(String num, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 17,
            height: 17,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF55C7FF).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              num,
              style: GoogleFonts.interTight(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF55C7FF),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 11,
                color:
                    isDark ? const Color(0xFF8EA4BE) : const Color(0xFF475569),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
