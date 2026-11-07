import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../config/app_capabilities.dart';
import '../services/backup_storage_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/nested_card.dart';
import '../widgets/modal_card_sheet.dart';
import '../widgets/notification_permission_sheet.dart';
import '../widgets/ambient_top_glow.dart';
import 'manage_categories_screen.dart';
import 'display_preferences_screen.dart';
import 'onboarding_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  final ScrollController? scrollController;

  const SettingsScreen({super.key, this.scrollController});

  static const _background = Color(0xFF1C2229);
  static const _cyan = Color(0xFF55C7FF);
  static const _danger = Color(0xFFE05362);
  static const _warning = Color(0xFFE58B29);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? _background : const Color(0xFFF4F5F7);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          if (isDark) const AmbientTopGlow(),
          SafeArea(
            bottom: false,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 124),
              children: [
                _buildHeader(isDark),
                const SizedBox(height: 14),
                NestedCard(
                  title: 'Profil Pengguna',
                  action: 'Ubah Profil',
                  onActionTap: () => _showEditProfileSheet(context, provider),
                  innerPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: _buildProfileCard(context, provider, isDark),
                ),
                const SizedBox(height: 12),
                NestedCard(
                  title: 'Preferensi Finansial & Tampilan',
                  innerPadding: const EdgeInsets.symmetric(vertical: 2),
                  child: _buildFinancialPreferences(context, provider, isDark),
                ),
                const SizedBox(height: 12),
                NestedCard(
                  title: 'Notifikasi & Pengingat',
                  innerPadding: const EdgeInsets.symmetric(vertical: 2),
                  child: _buildNotificationsAndReminders(context, provider, isDark),
                ),
                const SizedBox(height: 12),
                NestedCard(
                  title: 'Cadangan & Pemulihan Data',
                  action: 'JSON Backup',
                  innerPadding: const EdgeInsets.symmetric(vertical: 2),
                  child: _buildBackupRestore(context, provider, isDark),
                ),
                const SizedBox(height: 12),
                NestedCard(
                  title: 'Zona Bahaya',
                  innerPadding: const EdgeInsets.symmetric(vertical: 2),
                  child: _buildDangerZone(context, provider, isDark),
                ),
                const SizedBox(height: 12),
                NestedCard(
                  title: 'Tentang Aplikasi & Privasi',
                  innerPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: _buildAboutSystem(context, isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Text(
      'Profil & Pengaturan',
      style: GoogleFonts.interTight(
        color: isDark ? Colors.white : const Color(0xFF0F172A),
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildProfileCard(
      BuildContext context, TransactionProvider provider, bool isDark) {
    final initials = provider.userName.trim().isNotEmpty
        ? provider.userName
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'MT';
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor =
        isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final dividerColor =
        isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0);
    final sepColor =
        isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFCBD5E1);

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF02539A), Color(0xFF01417A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                    color: Colors.white.withOpacity(0.12), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: GoogleFonts.interTight(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.userName,
                    style: GoogleFonts.interTight(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (provider.userPhone.isNotEmpty) provider.userPhone,
                      if (provider.userGender.isNotEmpty) provider.userGender,
                    ].where((s) => s.trim().isNotEmpty).join(' · '),
                    style: GoogleFonts.manrope(
                      color: mutedColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Container(
            height: 1,
            color: dividerColor,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildProfileStat(
                label: 'Transaksi',
                value: '${provider.transactions.length}',
                unit: 'catatan',
                isDark: isDark,
              ),
            ),
            Container(width: 1, height: 28, color: sepColor),
            Expanded(
              child: _buildProfileStat(
                label: 'Dompet',
                value: '${provider.wallets.length}',
                unit: 'rekening',
                isDark: isDark,
              ),
            ),
            Container(width: 1, height: 28, color: sepColor),
            Expanded(
              child: _buildProfileStat(
                label: 'Bulan Ini',
                value: provider.formatCurrency(provider.totalExpense),
                unit: 'keluar',
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileStat({
    required String label,
    required String value,
    required String unit,
    required bool isDark,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: GoogleFonts.interTight(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          unit,
          style: GoogleFonts.manrope(
            color: isDark ? const Color(0xFF708398) : const Color(0xFF94A3B8),
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Sistem';
      case ThemeMode.light:
        return 'Mode Terang';
      case ThemeMode.dark:
        return 'Mode Gelap';
    }
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
    }
  }

  void _showThemeModeSheet(BuildContext context, TransactionProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A);

    _showModalCardSheet(
      context: context,
      title: 'Mode Tampilan',
      titleIcon: Icons.palette_outlined,
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          Widget buildOption({
            required ThemeMode mode,
            required String title,
            required IconData icon,
            required String description,
          }) {
            final isSelected = provider.themeMode == mode;

            return InkWell(
              onTap: () {
                provider.setThemeMode(mode);
                Navigator.pop(ctx);
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? const Color(0xFF55C7FF).withOpacity(0.08)
                          : const Color(0xFF02539A).withOpacity(0.06))
                      : (isDark
                          ? Colors.white.withOpacity(0.03)
                          : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? accentColor
                        : (isDark
                            ? Colors.white.withOpacity(0.06)
                            : const Color(0xFFE2E8F0)),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor.withOpacity(0.18)
                            : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: isSelected
                            ? accentColor
                            : (isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B)),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.interTight(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: GoogleFonts.manrope(
                              fontSize: 11.5,
                              color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? accentColor : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? accentColor
                              : (isDark ? const Color(0xFF677B92) : const Color(0xFF94A3B8)),
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildOption(
                mode: ThemeMode.system,
                title: 'Sistem',
                icon: Icons.brightness_auto_rounded,
                description: 'Menyesuaikan tema otomatis dengan sistem perangkat',
              ),
              buildOption(
                mode: ThemeMode.light,
                title: 'Mode Terang',
                icon: Icons.light_mode_rounded,
                description: 'Tampilan bersih, cerah, dan kontras tinggi',
              ),
              buildOption(
                mode: ThemeMode.dark,
                title: 'Mode Gelap',
                icon: Icons.dark_mode_rounded,
                description: 'Tampilan gelap matte elegan dan hemat baterai',
              ),
              const SizedBox(height: 6),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFinancialPreferences(
      BuildContext context, TransactionProvider provider, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor =
        isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1);
    final chipBg =
        isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9);

    return Column(
      children: [
        _buildSettingRow(
          context: context,
          icon: _getThemeIcon(provider.themeMode),
          title: 'Mode Tampilan',
          subtitle: _getThemeLabel(provider.themeMode),
          onTap: () => _showThemeModeSheet(context, provider),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getThemeLabel(provider.themeMode),
                style: GoogleFonts.manrope(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: mutedColor,
              ),
            ],
          ),
        ),
        _buildDivider(context),
        _buildSettingRow(
          context: context,
          icon: Icons.currency_exchange_rounded,
          title: 'Mata Uang Acuan',
          subtitle: 'Format penulisan angka finansial',
          trailing: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: provider.currency,
                dropdownColor: isDark ? const Color(0xFF131A26) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                icon: Icon(Icons.arrow_drop_down_rounded,
                    color: textColor, size: 18),
                style: GoogleFonts.interTight(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                items: [
                  DropdownMenuItem(
                      value: 'IDR',
                      child:
                          Text('IDR (Rp)', style: TextStyle(color: textColor))),
                  DropdownMenuItem(
                      value: 'USD',
                      child:
                          Text('USD (\$)', style: TextStyle(color: textColor))),
                ],
                onChanged: (val) {
                  if (val != null) provider.setCurrency(val);
                },
              ),
            ),
          ),
        ),
        _buildDivider(context),
        _buildSettingRow(
          context: context,
          icon: Icons.dashboard_customize_outlined,
          title: 'Preferensi Tampilan',
          subtitle: provider.dashboardViewMode.label,
          onTap: () => _showDisplayPreferencesSheet(context, provider),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: borderColor),
                ),
                child: Center(
                  child: Text(
                    provider.dashboardViewMode.shortLabel,
                    style: GoogleFonts.interTight(
                      color: textColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: mutedColor, size: 20),
            ],
          ),
        ),
        _buildDivider(context),
        _buildSettingRow(
          context: context,
          icon: Icons.category_outlined,
          title: 'Kelola Kategori',
          subtitle: 'Atur kategori pengeluaran dan pemasukan',
          onTap: () => Navigator.push(
            context,
            ManageCategoriesScreen.route(),
          ).then((_) {
            if (scrollController?.hasClients ?? false) {
              scrollController!.jumpTo(0.0);
            }
          }),
          trailing:
              Icon(Icons.chevron_right_rounded, color: mutedColor, size: 20),
        ),
      ],
    );
  }

  Widget _buildNotificationsAndReminders(
      BuildContext context, TransactionProvider provider, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor =
        isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1);
    final chipBg =
        isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9);

    return Column(
      children: [
        _buildSettingRow(
          context: context,
          icon: Icons.shield_outlined,
          title: 'Izin Notifikasi Sistem',
          subtitle: provider.hasNotificationPermission
              ? 'Diizinkan · Notifikasi lokal aktif'
              : 'Belum diizinkan · Ketuk untuk aktivasi',
          onTap: () {
            if (!provider.hasNotificationPermission) {
              showNotificationPermissionSheet(
                context: context,
                featureTitle: 'Layanan Notifikasi',
                onGranted: () {},
              );
            }
          },
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: provider.hasNotificationPermission
                  ? const Color(0xFF39D98A).withOpacity(0.14)
                  : const Color(0xFFE58B29).withOpacity(0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: provider.hasNotificationPermission
                    ? const Color(0xFF39D98A).withOpacity(0.3)
                    : const Color(0xFFE58B29).withOpacity(0.3),
              ),
            ),
            child: Text(
              provider.hasNotificationPermission ? 'Diizinkan' : 'Belum Aktif',
              style: GoogleFonts.interTight(
                color: provider.hasNotificationPermission
                    ? const Color(0xFF39D98A)
                    : const Color(0xFFE58B29),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        _buildDivider(context),
        _buildSettingRow(
          context: context,
          icon: Icons.alarm_rounded,
          title: 'Pengingat Transaksi Harian',
          subtitle: provider.isDailyReminderEnabled
              ? 'Aktif · ${provider.dailyReminderTimes.join(", ")}'
              : 'Ingatkan jika belum ada transaksi hari ini',
          trailing: Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: isDark ? const Color(0xFF8CA7C5) : const Color(0xFF64748B),
          ),
          onTap: () => _showDailyReminderSheet(context, provider),
        ),
        _buildDivider(context),
        _buildSettingRow(
          context: context,
          icon: Icons.notifications_active_outlined,
          title: 'Tes Notifikasi HP',
          subtitle: 'Kirim notifikasi uji coba langsung ke status bar HP Anda',
          onTap: () async {
            await provider.sendTestPushNotification();
            if (context.mounted) {
              AppSnackBar.show(
                context,
                'Notifikasi tes berhasil dikirim ke status bar HP.',
                type: SnackBarType.success,
              );
            }
          },
          trailing: const Icon(Icons.send_rounded,
              size: 16, color: Color(0xFF55C7FF)),
        ),
      ],
    );
  }

  void _showDailyReminderSheet(
      BuildContext context, TransactionProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor =
        isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final itemBg = isDark ? const Color(0xFF131A26) : const Color(0xFFF8FAFC);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);

    bool isEnabled = provider.isDailyReminderEnabled;
    final List<String> alarms = List<String>.from(
      provider.dailyReminderTimes.isNotEmpty
          ? provider.dailyReminderTimes
          : ['18:00', '19:00'],
    );

    _showModalCardSheet(
      context: context,
      title: 'Pengingat Transaksi Harian',
      titleIcon: Icons.alarm_rounded,
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Atur jam notifikasi otomatis untuk mengingatkan Anda mencatat transaksi harian.',
                style: GoogleFonts.manrope(
                  color: mutedColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 14),
              // Master Switch Card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: itemBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Pengingat',
                            style: GoogleFonts.interTight(
                              color: textColor,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEnabled
                                ? 'Notifikasi aktif pada jam yang ditentukan'
                                : 'Pengingat nonaktif',
                            style: GoogleFonts.manrope(
                              color: isEnabled
                                  ? const Color(0xFF39D98A)
                                  : mutedColor,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: isEnabled,
                      activeColor: const Color(0xFF55C7FF),
                      onChanged: (val) {
                        setSheetState(() {
                          isEnabled = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (isEnabled) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Daftar Waktu Alarm (${alarms.length})',
                        style: GoogleFonts.manrope(
                          color: mutedColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 20, minute: 0),
                        );
                        if (picked != null) {
                          final h = picked.hour.toString().padLeft(2, '0');
                          final m = picked.minute.toString().padLeft(2, '0');
                          final timeStr = '$h:$m';
                          if (!alarms.contains(timeStr)) {
                            alarms.add(timeStr);
                            alarms.sort();
                            setSheetState(() {});
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded,
                                size: 14, color: Color(0xFF55C7FF)),
                            const SizedBox(width: 2),
                            Text(
                              'Tambah Jam',
                              style: GoogleFonts.manrope(
                                color: const Color(0xFF55C7FF),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  children: alarms.map((time) {
                    final parts = time.split(':');
                    final initH = int.tryParse(parts[0]) ?? 18;
                    final initM = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: itemBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: initH, minute: initM),
                          );
                          if (picked != null) {
                            final h = picked.hour.toString().padLeft(2, '0');
                            final m = picked.minute.toString().padLeft(2, '0');
                            final newTime = '$h:$m';
                            final idx = alarms.indexOf(time);
                            if (idx != -1) {
                              alarms[idx] = newTime;
                              alarms.sort();
                              setSheetState(() {});
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF55C7FF).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.schedule_rounded,
                                  size: 15,
                                  color: Color(0xFF55C7FF),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          time,
                                          style: GoogleFonts.interTight(
                                            color: textColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.edit_outlined,
                                          size: 13,
                                          color: mutedColor.withOpacity(0.6),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Ketuk untuk ubah jam pengingat',
                                      style: GoogleFonts.manrope(
                                        color: mutedColor,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (alarms.length > 1)
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: const Color(0xFFFF6B7A).withOpacity(0.8),
                                  ),
                                  onPressed: () {
                                    alarms.remove(time);
                                    setSheetState(() {});
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
              ],
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF02539A),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (isEnabled && !provider.hasNotificationPermission) {
                    showNotificationPermissionSheet(
                      context: context,
                      featureTitle: 'Pengingat Transaksi Harian',
                      onGranted: () {
                        provider.setDailyReminderTimes(alarms);
                        provider.toggleDailyReminder(true);
                      },
                    );
                  } else {
                    provider.setDailyReminderTimes(alarms);
                    provider.toggleDailyReminder(isEnabled);
                  }
                  Navigator.pop(ctx);
                  AppSnackBar.show(
                    context,
                    'Pengaturan pengingat harian berhasil disimpan.',
                    type: SnackBarType.success,
                  );
                },
                child: Text(
                  'Simpan Pengingat',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackupRestore(
      BuildContext context, TransactionProvider provider, bool isDark) {
    final mutedColor =
        isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);

    return Column(
      children: [
        _buildSettingRow(
          context: context,
          icon: Icons.file_download_outlined,
          title: 'Ekspor Cadangan (Backup JSON)',
          subtitle: 'Unduh berkas cadangan data keuangan (.json)',
          onTap: () => _showExportSheet(context, provider),
          trailing:
              Icon(Icons.chevron_right_rounded, color: mutedColor, size: 20),
        ),
        _buildDivider(context),
        _buildSettingRow(
          context: context,
          icon: Icons.settings_backup_restore_rounded,
          title: 'Pulihkan Data (Restore JSON)',
          subtitle: 'Unggah berkas atau tempel JSON untuk pemulihan',
          onTap: () => _showRestoreSheet(context, provider),
          trailing:
              Icon(Icons.chevron_right_rounded, color: mutedColor, size: 20),
        ),
      ],
    );
  }

  Widget _buildDangerZone(
      BuildContext context, TransactionProvider provider, bool isDark) {
    final mutedColor =
        isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);

    return Column(
      children: [
        _buildSettingRow(
          context: context,
          icon: Icons.delete_sweep_rounded,
          iconColor: _danger,
          iconBg: _danger.withOpacity(0.14),
          title: 'Kosongkan Riwayat Transaksi',
          subtitle: 'Hapus seluruh catatan mutasi dan reset saldo ke nol',
          onTap: () => _showClearTransactionsSheet(context, provider),
          trailing:
              Icon(Icons.chevron_right_rounded, color: mutedColor, size: 20),
        ),
        _buildDivider(context),
        _buildSettingRow(
          context: context,
          icon: Icons.restart_alt_rounded,
          iconColor: _warning,
          iconBg: _warning.withOpacity(0.14),
          title: 'Reset ke Data Bawaan',
          subtitle: 'Kembalikan saldo dan transaksi simulasi awal',
          onTap: () => _showResetDefaultSheet(context, provider),
          trailing:
              Icon(Icons.chevron_right_rounded, color: mutedColor, size: 20),
        ),
      ],
    );
  }

  Widget _buildAboutSystem(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor =
        isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final iconBg = isDark ? const Color(0xFF16202D) : const Color(0xFFE2E8F0);
    final cardBg =
        isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/logo.png',
                width: 38,
                height: 38,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yotro',
                    style: GoogleFonts.interTight(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Versi 2.0.0',
                    style: GoogleFonts.manrope(
                      color: mutedColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              _buildInfoRow('Database:',
                  'Lokal di perangkat (SharedPreferences)', isDark),
              const SizedBox(height: 6),
              _buildInfoRow('Privasi:',
                  '100% Offline (Data tidak dikirim ke server luar)', isDark),
              const SizedBox(height: 6),
              _buildInfoRow('Lisensi:', 'Pencatat Keuangan Mandiri', isDark),
            ],
          ),
        ),
        if (kIsWeb) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () {
                BackupStorageService.downloadApk();
                AppSnackBar.show(
                  context,
                  'Mengunduh berkas yotro-app.apk...',
                  type: SnackBarType.info,
                );
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(
                'Unduh APK Android (v1.0.6)',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF02539A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: GoogleFonts.manrope(
              color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.manrope(
              color: isDark
                  ? Colors.white.withOpacity(0.85)
                  : const Color(0xFF1E293B),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showModalCardSheet({
    required BuildContext context,
    required String title,
    IconData? titleIcon,
    Color? titleIconColor,
    required Widget child,
  }) {
    showModalCardSheet(
      context: context,
      title: title,
      titleIcon: titleIcon,
      titleIconColor: titleIconColor,
      child: child,
    );
  }

  void _showDisplayPreferencesSheet(
      BuildContext context, TransactionProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor =
        isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final accentColor =
        isDark ? const Color(0xFF55C7FF) : const Color(0xFF0F172A);

    DashboardViewMode selectedMode = provider.dashboardViewMode;

    _showModalCardSheet(
      context: context,
      title: 'Preferensi Tampilan Beranda',
      titleIcon: Icons.dashboard_customize_outlined,
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          Widget buildOption({
            required DashboardViewMode mode,
            required String title,
            String? badge,
            required String description,
          }) {
            final isSelected = selectedMode == mode;

            return InkWell(
              onTap: () {
                setSheetState(() {
                  selectedMode = mode;
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? const Color(0xFF55C7FF).withOpacity(0.08)
                          : const Color(0xFF0F172A).withOpacity(0.05))
                      : (isDark
                          ? Colors.white.withOpacity(0.03)
                          : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? (isDark
                            ? const Color(0xFF55C7FF)
                            : const Color(0xFF0F172A))
                        : (isDark
                            ? Colors.white.withOpacity(0.06)
                            : const Color(0xFFE2E8F0)),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 2, right: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? accentColor : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? accentColor
                              : (isDark
                                  ? const Color(0xFF677B92)
                                  : const Color(0xFF94A3B8)),
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: isDark ? Colors.black : Colors.white,
                            )
                          : null,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: GoogleFonts.interTight(
                                    color: isSelected
                                        ? (isDark
                                            ? const Color(0xFF55C7FF)
                                            : const Color(0xFF0F172A))
                                        : textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (badge != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    badge,
                                    style: GoogleFonts.manrope(
                                      color: isDark
                                          ? const Color(0xFF8EA4BE)
                                          : const Color(0xFF475569),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: GoogleFonts.manrope(
                              color: mutedColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pilih format tampilan kartu saldo dan ringkasan finansial di Beranda.',
                style: GoogleFonts.manrope(
                  color: mutedColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 14),
              buildOption(
                mode: DashboardViewMode.complete,
                title: 'Complete View',
                badge: 'Bawaan',
                description:
                    'Tampilkan total saldo saat ini serta sub-kartu pemasukan dan pengeluaran.',
              ),
              buildOption(
                mode: DashboardViewMode.incomeExpense,
                title: 'Pemasukan dan Pengeluaran',
                description:
                    'Sembunyikan total saldo. Tampilkan sub-kartu pemasukan dan pengeluaran berdampingan.',
              ),
              buildOption(
                mode: DashboardViewMode.expenseOnly,
                title: 'Pengeluaran saja',
                description:
                    'Kartu utama menampilkan Total Pengeluaran, tanpa kartu saldo saat ini dan sub-kartu pemasukan/pengeluaran.',
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF02539A),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  provider.setDashboardViewMode(selectedMode);
                  Navigator.pop(ctx);
                  AppSnackBar.show(
                    context,
                    'Preferensi tampilan beranda berhasil disimpan.',
                    type: SnackBarType.success,
                  );
                },
                child: Text(
                  'Simpan Preferensi',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditProfileSheet(
      BuildContext context, TransactionProvider provider) {
    final nameController = TextEditingController(text: provider.userName);
    final phoneController = TextEditingController(text: provider.userPhone);
    String selectedGender =
        provider.userGender.isNotEmpty ? provider.userGender : 'Pria';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor =
        isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final fieldBg =
        isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF8FAFC);
    final fieldBorder =
        isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFCBD5E1);

    _showModalCardSheet(
      context: context,
      title: 'Ubah Profil Pengguna',
      titleIcon: Icons.badge_outlined,
      child: StatefulBuilder(
        builder: (ctx, setState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Perbarui data identitas Anda untuk personalisasi akun.',
                style: GoogleFonts.manrope(color: mutedColor, fontSize: 12.5),
              ),
              const SizedBox(height: 14),
              Text(
                'Nama Lengkap',
                style: GoogleFonts.manrope(
                    color: mutedColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: nameController,
                style: GoogleFonts.manrope(color: textColor, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Nama lengkap...',
                  hintStyle: GoogleFonts.manrope(
                      color: isDark
                          ? const Color(0xFF6C7D93)
                          : const Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: fieldBg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: fieldBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: fieldBorder),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: _cyan),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Nomor Telepon',
                style: GoogleFonts.manrope(
                    color: mutedColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.manrope(color: textColor, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: '08xxxxxxxxxx',
                  hintStyle: GoogleFonts.manrope(
                      color: isDark
                          ? const Color(0xFF6C7D93)
                          : const Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: fieldBg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: fieldBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: fieldBorder),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: _cyan),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Jenis Kelamin',
                style: GoogleFonts.manrope(
                    color: mutedColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Container(
                height: 40,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: fieldBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => selectedGender = 'Pria'),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selectedGender == 'Pria'
                                ? (isDark
                                    ? const Color(0xFF0B2244)
                                    : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: selectedGender == 'Pria'
                                ? Border.all(
                                    color: const Color(0xFF55C7FF)
                                        .withOpacity(0.4))
                                : null,
                          ),
                          child: Text(
                            'Pria',
                            style: GoogleFonts.manrope(
                              color: selectedGender == 'Pria'
                                  ? (isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A))
                                  : mutedColor,
                              fontSize: 12,
                              fontWeight: selectedGender == 'Pria'
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => selectedGender = 'Wanita'),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selectedGender == 'Wanita'
                                ? (isDark
                                    ? const Color(0xFF0B2244)
                                    : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: selectedGender == 'Wanita'
                                ? Border.all(
                                    color: const Color(0xFF55C7FF)
                                        .withOpacity(0.4))
                                : null,
                          ),
                          child: Text(
                            'Wanita',
                            style: GoogleFonts.manrope(
                              color: selectedGender == 'Wanita'
                                  ? (isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A))
                                  : mutedColor,
                              fontSize: 12,
                              fontWeight: selectedGender == 'Wanita'
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.12)
                                : const Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Batal',
                          style: GoogleFonts.manrope(
                              color: mutedColor, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFF02539A),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final newName = nameController.text.trim();
                        final newPhone = phoneController.text.trim();
                        if (newName.isNotEmpty) {
                          await provider.updateProfile(
                            name: newName,
                            phone: newPhone,
                            gender: selectedGender,
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text('Simpan',
                          style: GoogleFonts.manrope(
                              color: Colors.white,
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

  void _showExportSheet(BuildContext context, TransactionProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor =
        isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF131A26) : const Color(0xFFF8FAFC);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);

    final jsonStr = provider.exportDataAsJson();
    final now = DateTime.now();
    final dateTag =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final fileName = 'yotro_backup_$dateTag.json';

    _showModalCardSheet(
      context: context,
      title: 'Cadangkan Data Keuangan',
      titleIcon: Icons.cloud_download_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Apakah Anda yakin ingin membuat berkas cadangan data keuangan saat ini?',
            style: GoogleFonts.manrope(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Berkas .json ini mencakup seluruh catatan transaksi, dompet, anggaran, dan kategori Anda yang siap disimpan ke perangkat.',
            style: GoogleFonts.manrope(
              color: mutedColor,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          // Summary Pod
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${provider.transactions.length}',
                        style: GoogleFonts.interTight(
                          color: const Color(0xFF55C7FF),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text('Transaksi',
                          style: GoogleFonts.manrope(
                              color: mutedColor, fontSize: 10.5)),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: borderColor),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${provider.wallets.length}',
                        style: GoogleFonts.interTight(
                          color: const Color(0xFF39D98A),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text('Dompet',
                          style: GoogleFonts.manrope(
                              color: mutedColor, fontSize: 10.5)),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: borderColor),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${provider.categories.length}',
                        style: GoogleFonts.interTight(
                          color: const Color(0xFFFFC857),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text('Kategori',
                          style: GoogleFonts.manrope(
                              color: mutedColor, fontSize: 10.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.manrope(
                        color: mutedColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFF02539A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.download_rounded,
                      color: Colors.white, size: 16),
                  label: Text(
                    'Unduh Berkas JSON',
                    style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final success = await BackupStorageService.exportJsonFile(
                      jsonContent: jsonStr,
                      fileName: fileName,
                    );
                    if (context.mounted) {
                      AppSnackBar.show(
                        context,
                        success
                            ? 'Berkas cadangan ($fileName) berhasil diekspor.'
                            : 'Gagal mengunduh berkas cadangan.',
                        type: success
                            ? SnackBarType.success
                            : SnackBarType.danger,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: jsonStr));
              if (context.mounted) {
                Navigator.pop(context);
                AppSnackBar.show(
                  context,
                  'Teks JSON cadangan berhasil disalin ke clipboard.',
                  type: SnackBarType.success,
                );
              }
            },
            icon: Icon(Icons.copy_rounded, size: 13, color: mutedColor),
            label: Text(
              'Atau salin teks JSON ke clipboard',
              style: GoogleFonts.manrope(color: mutedColor, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  void _showRestoreSheet(BuildContext context, TransactionProvider provider) {
    final controller = TextEditingController();
    Map<String, dynamic>? validationResult;
    String? pickedFileName;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor =
        isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);

    _showModalCardSheet(
      context: context,
      title: 'Pulihkan Data (JSON)',
      titleIcon: Icons.settings_backup_restore_rounded,
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> pickJsonFile() async {
            try {
              final files = await FilePicker.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['json'],
              );
              if (files.isNotEmpty) {
                final file = files.first;
                final content = await file.xFile.readAsString();
                if (content.isNotEmpty) {
                  controller.text = content;
                  final res = provider.validateBackupJson(content.trim());
                  setSheetState(() {
                    pickedFileName = file.name;
                    validationResult = res;
                  });
                }
              }
            } catch (e) {
              if (ctx.mounted) {
                AppSnackBar.show(
                  context,
                  'Gagal membaca berkas: $e',
                  type: SnackBarType.danger,
                );
              }
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pilih berkas cadangan .json atau tempel teks JSON untuk memulihkan data Anda.',
                style: GoogleFonts.manrope(color: mutedColor, fontSize: 12),
              ),
              const SizedBox(height: 12),
              // File Picker Upload Button
              InkWell(
                onTap: pickJsonFile,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.04)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: pickedFileName != null
                          ? const Color(0xFF55C7FF)
                          : borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF55C7FF).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.upload_file_rounded,
                          size: 16,
                          color: Color(0xFF55C7FF),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pickedFileName ?? 'Unggah Berkas .json',
                              style: GoogleFonts.interTight(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              pickedFileName != null
                                  ? 'Berkas siap dipulihkan'
                                  : 'Klik untuk memilih berkas dari penyimpanan',
                              style: GoogleFonts.manrope(
                                color: pickedFileName != null
                                    ? const Color(0xFF39D98A)
                                    : mutedColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.folder_open_rounded,
                        size: 18,
                        color: mutedColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Divider(color: borderColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'atau tempel teks JSON',
                      style: GoogleFonts.manrope(
                          color: mutedColor, fontSize: 10.5),
                    ),
                  ),
                  Expanded(child: Divider(color: borderColor)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                style: GoogleFonts.firaCode(color: textColor, fontSize: 11),
                decoration: InputDecoration(
                  hintText:
                      '{\n  "version": "2.0.0",\n  "transactions": [...]\n}',
                  hintStyle: GoogleFonts.firaCode(
                      color: mutedColor.withOpacity(0.6), fontSize: 11),
                  filled: true,
                  fillColor: isDark
                      ? Colors.black.withOpacity(0.35)
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: _cyan),
                  ),
                ),
                onChanged: (text) {
                  final res = provider.validateBackupJson(text.trim());
                  setSheetState(() {
                    validationResult = res;
                  });
                },
              ),
              const SizedBox(height: 12),
              if (validationResult != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF103328),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E6F56)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF39D98A), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Valid: ${validationResult!['txCount']} transaksi dan ${validationResult!['walletCount']} dompet ditemukan.',
                          style: GoogleFonts.manrope(
                            color: const Color(0xFF39D98A),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              if (validationResult == null)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Tutup',
                      style: GoogleFonts.manrope(
                          color: mutedColor, fontWeight: FontWeight.w600)),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: _cyan),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final success = await provider.restoreFromJson(
                              controller.text.trim(),
                              merge: true);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            AppSnackBar.show(
                              context,
                              success
                                  ? 'Data berhasil digabungkan (Merge).'
                                  : 'Gagal memulihkan data.',
                              type: success
                                  ? SnackBarType.success
                                  : SnackBarType.danger,
                            );
                          }
                        },
                        child: Text('Merge Data',
                            style: GoogleFonts.manrope(
                                color: _cyan, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFF02539A),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final success = await provider.restoreFromJson(
                              controller.text.trim(),
                              merge: false);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            AppSnackBar.show(
                              context,
                              success
                                  ? 'Data berhasil ditimpa penuh (Replace).'
                                  : 'Gagal memulihkan data.',
                              type: success
                                  ? SnackBarType.success
                                  : SnackBarType.danger,
                            );
                          }
                        },
                        child: Text('Replace Data',
                            style: GoogleFonts.manrope(
                                color: Colors.white,
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

  void _showClearTransactionsSheet(
      BuildContext context, TransactionProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _showModalCardSheet(
      context: context,
      title: 'Kosongkan Riwayat Transaksi?',
      titleIcon: Icons.warning_amber_rounded,
      titleIconColor: _danger,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? _danger.withOpacity(0.12) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? _danger.withOpacity(0.3) : const Color(0xFFFCA5A5),
              ),
            ),
            child: Text(
              'Seluruh catatan transaksi (${provider.transactions.length} item) akan dihapus permanen dan saldo rekening dinolkan. Tindakan ini tidak dapat dibatalkan.',
              style: GoogleFonts.manrope(
                color: isDark ? const Color(0xFFFECACA) : const Color(0xFF991B1B),
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                    side: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.15) : const Color(0xFFCBD5E1),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Batalkan',
                    style: GoogleFonts.manrope(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: _danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await provider.clearAllTransactions();
                    if (context.mounted) {
                      Navigator.pop(context);
                      AppSnackBar.show(
                        context,
                        'Seluruh transaksi berhasil dikosongkan.',
                        type: SnackBarType.danger,
                      );
                    }
                  },
                  child: Text(
                    'Hapus Semua',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showResetDefaultSheet(
      BuildContext context, TransactionProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _showModalCardSheet(
      context: context,
      title: 'Reset ke Data Bawaan?',
      titleIcon: Icons.restart_alt_rounded,
      titleIconColor: _warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? _warning.withOpacity(0.12) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? _warning.withOpacity(0.3) : const Color(0xFFFCD34D),
              ),
            ),
            child: Text(
              'Database akan dikembalikan ke data simulasi bawaan awal (17 transaksi demo John Doe, 4 dompet, dan target budget).',
              style: GoogleFonts.manrope(
                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                    side: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.15) : const Color(0xFFCBD5E1),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Batalkan',
                    style: GoogleFonts.manrope(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFF02539A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await provider.resetToDefaults();
                    if (context.mounted) {
                      Navigator.pop(context);
                      AppSnackBar.show(
                        context,
                        'Aplikasi berhasil direset ke data bawaan.',
                        type: SnackBarType.success,
                      );
                    }
                  },
                  child: Text(
                    'Reset Bawaan',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required BuildContext context,
    required IconData icon,
    Color? iconColor,
    Color? iconBg,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final defaultIconBg =
        iconBg ?? (isDark ? const Color(0xFF182230) : const Color(0xFFE2E8F0));
    final defaultIconColor = iconColor ??
        (isDark ? const Color(0xFF8CA7C5) : const Color(0xFF475569));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: defaultIconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: defaultIconColor, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      color: titleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        color: subtitleColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        height: 1,
        color:
            isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
      ),
    );
  }
}
