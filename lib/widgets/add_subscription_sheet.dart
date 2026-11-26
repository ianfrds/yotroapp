import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/subscription_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/thousands_separator_formatter.dart';
import 'modal_card_sheet.dart';

class SubscriptionPreset {
  final String name;
  final double amount;
  final int defaultDay;
  final String categoryHint;
  final IconData icon;

  const SubscriptionPreset({
    required this.name,
    required this.amount,
    required this.defaultDay,
    required this.categoryHint,
    required this.icon,
  });
}

const List<SubscriptionPreset> kSubscriptionPresets = [
  SubscriptionPreset(
    name: 'Netflix',
    amount: 186000,
    defaultDay: 25,
    categoryHint: 'Hiburan',
    icon: Icons.movie_outlined,
  ),
  SubscriptionPreset(
    name: 'Spotify',
    amount: 54990,
    defaultDay: 1,
    categoryHint: 'Hiburan',
    icon: Icons.music_note_outlined,
  ),
  SubscriptionPreset(
    name: 'YouTube Premium',
    amount: 69000,
    defaultDay: 10,
    categoryHint: 'Hiburan',
    icon: Icons.play_circle_outline,
  ),
  SubscriptionPreset(
    name: 'WiFi / Internet',
    amount: 350000,
    defaultDay: 15,
    categoryHint: 'Tagihan & Utilitas',
    icon: Icons.wifi,
  ),
  SubscriptionPreset(
    name: 'Listrik PLN',
    amount: 200000,
    defaultDay: 20,
    categoryHint: 'Tagihan & Utilitas',
    icon: Icons.bolt,
  ),
  SubscriptionPreset(
    name: 'BPJS Kesehatan',
    amount: 150000,
    defaultDay: 10,
    categoryHint: 'Kesehatan',
    icon: Icons.health_and_safety_outlined,
  ),
  SubscriptionPreset(
    name: 'Kos / Kontrakan',
    amount: 1500000,
    defaultDay: 1,
    categoryHint: 'Tagihan & Utilitas',
    icon: Icons.home_outlined,
  ),
  SubscriptionPreset(
    name: 'iCloud / Drive',
    amount: 45000,
    defaultDay: 5,
    categoryHint: 'Tagihan & Utilitas',
    icon: Icons.cloud_outlined,
  ),
  SubscriptionPreset(
    name: 'ChatGPT Plus',
    amount: 350000,
    defaultDay: 12,
    categoryHint: 'Tagihan & Utilitas',
    icon: Icons.smart_toy_outlined,
  ),
  SubscriptionPreset(
    name: 'Gym / Fitness',
    amount: 300000,
    defaultDay: 1,
    categoryHint: 'Kesehatan',
    icon: Icons.fitness_center,
  ),
];

Future<void> showAddOrEditSubscriptionSheet({
  required BuildContext context,
  SubscriptionModel? existingSubscription,
}) async {
  final provider = context.read<TransactionProvider>();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isEdit = existingSubscription != null;

  final expenseCategories = provider.getCategories(TransactionType.expense);
  final wallets = provider.wallets;

  final nameController = TextEditingController(
    text: existingSubscription?.name ?? '',
  );
  final amountController = TextEditingController(
    text: existingSubscription != null
        ? ThousandsSeparatorInputFormatter.formatNumber(
            existingSubscription.amount.round().toString(),
          )
        : '',
  );

  int selectedDay = existingSubscription?.billingDay ?? DateTime.now().day;
  SubscriptionCycle selectedCycle =
      existingSubscription?.cycle ?? SubscriptionCycle.monthly;

  String selectedCategoryId = existingSubscription?.categoryId ??
      (expenseCategories.isNotEmpty ? expenseCategories.first.id : '');
  String selectedCategoryName = existingSubscription?.categoryName ??
      (expenseCategories.isNotEmpty ? expenseCategories.first.name : 'Tagihan & Utilitas');

  String selectedWalletId = existingSubscription?.walletId ??
      (wallets.isNotEmpty ? wallets.first.id : '');

  bool reminderEnabled = existingSubscription?.reminderEnabled ?? true;
  bool isSaving = false;

  await showModalCardSheet(
    context: context,
    title: isEdit ? 'Ubah Tagihan Rutin' : 'Tambah Tagihan Rutin',
    titleIcon: Icons.repeat_rounded,
    titleIconColor: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
    child: StatefulBuilder(
      builder: (ctx, setState) {
        final inputBg = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9);
        final inputBorder = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1);
        final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final labelColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
        final accentColor = isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Quick Presets (Only if creating new)
            if (!isEdit) ...[
              Text(
                'Pilihan Cepat Populer',
                style: GoogleFonts.manrope(
                  color: labelColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: kSubscriptionPresets.map((preset) {
                    final isSelected = nameController.text.trim().toLowerCase() ==
                        preset.name.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            nameController.text = preset.name;
                            amountController.text =
                                ThousandsSeparatorInputFormatter.formatNumber(
                              preset.amount.round().toString(),
                            );
                            selectedDay = preset.defaultDay;

                            // Match category
                            final matchedCat = expenseCategories.firstWhere(
                              (c) =>
                                  c.name.toLowerCase().contains(preset.categoryHint.toLowerCase()) ||
                                  preset.categoryHint.toLowerCase().contains(c.name.toLowerCase()),
                              orElse: () => expenseCategories.first,
                            );
                            selectedCategoryId = matchedCat.id;
                            selectedCategoryName = matchedCat.name;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? const Color(0xFF2563EB).withOpacity(0.25)
                                    : const Color(0xFF02539A).withOpacity(0.12))
                                : (isDark
                                    ? Colors.white.withOpacity(0.04)
                                    : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A))
                                  : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1)),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                preset.icon,
                                size: 14,
                                color: isSelected
                                    ? (isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A))
                                    : (isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                preset.name,
                                style: GoogleFonts.manrope(
                                  color: isSelected
                                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                      : (isDark ? const Color(0xFFB0C0D4) : const Color(0xFF334155)),
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 2. Input Nama Tagihan
            Text(
              'Nama Tagihan / Langganan',
              style: GoogleFonts.manrope(
                color: labelColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              style: GoogleFonts.manrope(color: textColor, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Contoh: Netflix, Listrik PLN, WiFi',
                hintStyle: GoogleFonts.manrope(
                  color: isDark ? const Color(0xFF4B5A6D) : const Color(0xFF94A3B8),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: inputBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Input Nominal
            Text(
              'Nominal Tagihan (${provider.currency})',
              style: GoogleFonts.manrope(
                color: labelColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              style: GoogleFonts.interTight(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                prefixText: '${provider.currency == 'IDR' ? 'Rp ' : '\$ '} ',
                prefixStyle: GoogleFonts.interTight(
                  color: isDark ? const Color(0xFF7F91A7) : const Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                hintText: '0',
                hintStyle: GoogleFonts.interTight(
                  color: isDark ? const Color(0xFF4B5A6D) : const Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: inputBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 4. Baris: Tanggal Jatuh Tempo & Siklus
            Row(
              children: [
                // Tanggal Jatuh Tempo (1..31)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jatuh Tempo (Tgl)',
                        style: GoogleFonts.manrope(
                          color: labelColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: inputBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: selectedDay,
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF131A26) : Colors.white,
                            icon: Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: isDark ? const Color(0xFF7F91A7) : const Color(0xFF64748B),
                            ),
                            items: List.generate(31, (index) => index + 1).map((d) {
                              return DropdownMenuItem<int>(
                                value: d,
                                child: Text(
                                  'Tgl $d',
                                  style: GoogleFonts.manrope(
                                    color: textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => selectedDay = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Siklus Berulang
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Siklus Berulang',
                        style: GoogleFonts.manrope(
                          color: labelColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: inputBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<SubscriptionCycle>(
                            value: selectedCycle,
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF131A26) : Colors.white,
                            icon: Icon(
                              Icons.arrow_drop_down_rounded,
                              color: isDark ? const Color(0xFF7F91A7) : const Color(0xFF64748B),
                            ),
                            items: SubscriptionCycle.values.map((c) {
                              return DropdownMenuItem<SubscriptionCycle>(
                                value: c,
                                child: Text(
                                  c.label,
                                  style: GoogleFonts.manrope(
                                    color: textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => selectedCycle = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 5. Kategori Pengeluaran & Dompet Pembayaran
            Row(
              children: [
                // Kategori
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kategori',
                        style: GoogleFonts.manrope(
                          color: labelColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: inputBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: expenseCategories.any((c) => c.id == selectedCategoryId)
                                ? selectedCategoryId
                                : (expenseCategories.isNotEmpty ? expenseCategories.first.id : null),
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF131A26) : Colors.white,
                            items: expenseCategories.map((c) {
                              return DropdownMenuItem<String>(
                                value: c.id,
                                child: Text(
                                  c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(
                                    color: textColor,
                                    fontSize: 12.5,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                final cat = expenseCategories.firstWhere((c) => c.id == val);
                                setState(() {
                                  selectedCategoryId = cat.id;
                                  selectedCategoryName = cat.name;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Dompet
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dompet Default',
                        style: GoogleFonts.manrope(
                          color: labelColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: inputBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: wallets.any((w) => w.id == selectedWalletId)
                                ? selectedWalletId
                                : (wallets.isNotEmpty ? wallets.first.id : null),
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF131A26) : Colors.white,
                            items: wallets.map((w) {
                              return DropdownMenuItem<String>(
                                value: w.id,
                                child: Text(
                                  w.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(
                                    color: textColor,
                                    fontSize: 12.5,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => selectedWalletId = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 6. Sakelar Pengingat Notifikasi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: inputBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                    color: reminderEnabled
                        ? (isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A))
                        : (isDark ? const Color(0xFF7F91A7) : const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ingatkan Sebelum Jatuh Tempo',
                          style: GoogleFonts.manrope(
                            color: textColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Alarm otomatis H-1 & Hari H (09:00 WIB)',
                          style: GoogleFonts.manrope(
                            color: labelColor,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: reminderEnabled,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF02539A),
                    onChanged: (val) {
                      setState(() => reminderEnabled = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 7. Tombol Simpan Tagihan
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF02539A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        final cleanAmount = amountController.text.replaceAll('.', '').trim();
                        final amount = double.tryParse(cleanAmount) ?? 0.0;

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nama tagihan tidak boleh kosong.')),
                          );
                          return;
                        }
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nominal tagihan harus lebih dari 0.')),
                          );
                          return;
                        }

                        setState(() => isSaving = true);
                        try {
                          if (isEdit) {
                            final updated = existingSubscription.copyWith(
                              name: name,
                              amount: amount,
                              billingDay: selectedDay,
                              cycle: selectedCycle,
                              categoryId: selectedCategoryId,
                              categoryName: selectedCategoryName,
                              walletId: selectedWalletId,
                              reminderEnabled: reminderEnabled,
                            );
                            await provider.updateSubscription(updated);
                          } else {
                            await provider.addSubscription(
                              name: name,
                              amount: amount,
                              billingDay: selectedDay,
                              cycle: selectedCycle,
                              categoryId: selectedCategoryId,
                              categoryName: selectedCategoryName,
                              walletId: selectedWalletId,
                              reminderEnabled: reminderEnabled,
                            );
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        } finally {
                          if (ctx.mounted) setState(() => isSaving = false);
                        }
                      },
                child: Text(
                  isEdit ? 'Simpan Perubahan' : 'Tambah Tagihan Rutin',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
