import '../../models/receipt_data_model.dart';

class ReceiptParserService {
  static const List<String> _grandTotalKeywords = [
    'grand total',
    'total bayar',
    'total akhir',
    'total belanja',
    'total tagihan',
    'total transaksi',
    'total',
    'jumlah bayar',
    'jumlah tagihan',
    'netto',
  ];

  static const List<String> _subtotalKeywords = [
    'subtotal',
    'sub total',
    'jumlah',
    'tagihan',
    'bayar tunai',
    'bayar debit',
    'bayar',
    'tunai',
    'cash',
    'qris',
    'debit',
    'amount',
  ];

  static const List<String> _ignoreMerchantKeywords = [
    'struk',
    'nota',
    'invoice',
    'sales draft',
    'receipt',
    'selamat datang',
    'terima kasih',
    'kasir',
    'pos',
    'npwp',
    'tanggal',
    'waktu',
    'date',
    'time',
    'jl.',
    'jalan',
    'telp',
    'phone',
    'customer',
    'pelanggan',
    'member',
    'no.',
    'order',
    'table',
    'meja',
    'lantai',
  ];

  /// Parse recognized raw OCR text into structured ReceiptDataModel
  static ReceiptDataModel parseText(String rawText) {
    if (rawText.trim().isEmpty) {
      return ReceiptDataModel(
        totalAmount: 0,
        alternativeAmounts: const [],
        merchantName: '',
        date: DateTime.now(),
        suggestedCategory: 'Makanan & Minuman',
        rawText: rawText,
        lines: const [],
      );
    }

    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final merchantName = _extractMerchant(lines);
    final date = _extractDate(rawText) ?? DateTime.now();
    final candidateAmounts = _extractAllAmounts(lines);
    final totalAmount = _extractTotalAmount(lines, candidateAmounts);

    final suggestedCategory = _detectCategory(merchantName, rawText);

    // Filter alternatives to remove the main total and sort descending
    final alternativeAmounts = candidateAmounts
        .where((amount) => (amount - totalAmount).abs() > 0.01 && amount > 0)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    return ReceiptDataModel(
      totalAmount: totalAmount,
      alternativeAmounts: alternativeAmounts.take(5).toList(),
      merchantName: merchantName,
      date: date,
      suggestedCategory: suggestedCategory,
      rawText: rawText,
      lines: lines,
    );
  }

  /// Extracts the store or merchant name from early lines
  static String _extractMerchant(List<String> lines) {
    for (int i = 0; i < lines.length && i < 6; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // Check if line contains phone numbers or mostly numbers/symbols
      if (RegExp(r'^\+?[0-9\s\-\.\(\)]{6,}$').hasMatch(line)) continue;
      if (line.length < 3) continue;

      // Check if line starts with ignore keywords
      bool shouldIgnore = false;
      for (final kw in _ignoreMerchantKeywords) {
        if (lower.startsWith(kw) || lower == kw) {
          shouldIgnore = true;
          break;
        }
      }
      if (shouldIgnore) continue;

      // Clean special characters
      final cleaned = line.replaceAll(RegExp(r'^[#*~=\-\_\|\s]+|[#*~=\-\_\|\s]+$'), '').trim();
      if (cleaned.length >= 3) {
        return cleaned;
      }
    }
    return 'Struk Belanja';
  }

  /// Extracts all monetary amounts found in the receipt lines
  static List<double> _extractAllAmounts(List<String> lines) {
    final List<double> amounts = [];
    final amountPattern = RegExp(r'(?:rp\.?\s*)?(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?|\d{3,10})', caseSensitive: false);

    for (final line in lines) {
      // Skip lines that look like dates or phone numbers or long codes
      if (RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b').hasMatch(line)) continue;
      if (RegExp(r'\b08\d{8,11}\b').hasMatch(line)) continue;

      final matches = amountPattern.allMatches(line);
      for (final match in matches) {
        final rawNum = match.group(1);
        if (rawNum != null) {
          final parsed = _parseCleanNumber(rawNum);
          if (parsed != null && parsed >= 500 && parsed <= 50000000) {
            amounts.add(parsed);
          }
        }
      }
    }
    return amounts.toSet().toList();
  }

  /// Extracts the most likely Grand Total from receipt lines
  static double _extractTotalAmount(List<String> lines, List<double> candidateAmounts) {
    // 1. Tier 1: Prioritize explicit Grand Total keywords (check from bottom to top)
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i].toLowerCase();
      for (final kw in _grandTotalKeywords) {
        if (line.contains(kw)) {
          final matchThisLine = _extractAmountFromLine(lines[i]);
          if (matchThisLine != null && matchThisLine >= 500) {
            return matchThisLine;
          }
          if (i + 1 < lines.length) {
            final matchNextLine = _extractAmountFromLine(lines[i + 1]);
            if (matchNextLine != null && matchNextLine >= 500) {
              return matchNextLine;
            }
          }
        }
      }
    }

    // 2. Tier 2: Check secondary Subtotal/Payment keywords
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i].toLowerCase();
      for (final kw in _subtotalKeywords) {
        if (line.contains(kw)) {
          final matchThisLine = _extractAmountFromLine(lines[i]);
          if (matchThisLine != null && matchThisLine >= 500) {
            return matchThisLine;
          }
          if (i + 1 < lines.length) {
            final matchNextLine = _extractAmountFromLine(lines[i + 1]);
            if (matchNextLine != null && matchNextLine >= 500) {
              return matchNextLine;
            }
          }
        }
      }
    }

    // 3. Fallback: Find highest candidate amount
    if (candidateAmounts.isNotEmpty) {
      final sorted = List<double>.from(candidateAmounts)..sort((a, b) => b.compareTo(a));
      return sorted.first;
    }

    return 0;
  }

  static double? _extractAmountFromLine(String line) {
    final amountPattern = RegExp(r'(?:rp\.?\s*)?(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?|\d{3,10})', caseSensitive: false);
    final matches = amountPattern.allMatches(line).toList();
    if (matches.isEmpty) return null;

    // Usually the amount is at the right / end of the line
    for (int i = matches.length - 1; i >= 0; i--) {
      final rawNum = matches[i].group(1);
      if (rawNum != null) {
        final parsed = _parseCleanNumber(rawNum);
        if (parsed != null && parsed >= 500) return parsed;
      }
    }
    return null;
  }

  /// Cleans and parses localized number strings into double
  static double? _parseCleanNumber(String str) {
    try {
      String s = str.replaceAll(RegExp(r'[^\d.,]'), '').trim();
      if (s.isEmpty) return null;

      // Example: 45.000,00 or 45,000.00
      if (s.contains('.') && s.contains(',')) {
        if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
          // Dot is thousand, comma is decimal (Indonesian)
          s = s.replaceAll('.', '').replaceAll(',', '.');
        } else {
          // Comma is thousand, dot is decimal (English)
          s = s.replaceAll(',', '');
        }
      } else if (s.contains('.')) {
        // Only dot: e.g. 45.000 or 45.50
        final parts = s.split('.');
        if (parts.length > 2) {
          // Multiple dots: 1.250.000
          s = s.replaceAll('.', '');
        } else if (parts.length == 2) {
          if (parts[1].length == 3) {
            // Thousands: 45.000
            s = parts[0] + parts[1];
          } else {
            // Decimal: 45.5
            s = '${parts[0]}.${parts[1]}';
          }
        }
      } else if (s.contains(',')) {
        // Only comma: e.g. 45,000 or 45,50
        final parts = s.split(',');
        if (parts.length > 2) {
          s = s.replaceAll(',', '');
        } else if (parts.length == 2) {
          if (parts[1].length == 3) {
            s = parts[0] + parts[1];
          } else {
            s = '${parts[0]}.${parts[1]}';
          }
        }
      }

      final val = double.tryParse(s);
      return val;
    } catch (_) {
      return null;
    }
  }

  /// Extracts date from receipt text
  static DateTime? _extractDate(String text) {
    try {
      // 1. Format: DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
      final match1 = RegExp(r'\b([0-3]?\d)[/.\-]([0-1]?\d)[/.\-](\d{2,4})\b').firstMatch(text);
      if (match1 != null) {
        int day = int.parse(match1.group(1)!);
        int month = int.parse(match1.group(2)!);
        int year = int.parse(match1.group(3)!);
        if (year < 100) year += 2000;

        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          return DateTime(year, month, day);
        }
      }

      // 2. Format: DD Month YYYY (e.g. 06 Nov 2026, 6 November 2026)
      final match2 = RegExp(
        r'\b([0-3]?\d)\s+(jan|feb|mar|apr|mei|may|jun|jul|agu|ags|aug|sep|okt|oct|nov|des|dec)[a-z]*\s+(\d{2,4})\b',
        caseSensitive: false,
      ).firstMatch(text);

      if (match2 != null) {
        int day = int.parse(match2.group(1)!);
        String mStr = match2.group(2)!.toLowerCase();
        int year = int.parse(match2.group(3)!);
        if (year < 100) year += 2000;

        int month = 1;
        if (mStr.startsWith('jan')) month = 1;
        else if (mStr.startsWith('feb')) month = 2;
        else if (mStr.startsWith('mar')) month = 3;
        else if (mStr.startsWith('apr')) month = 4;
        else if (mStr.startsWith('mei') || mStr.startsWith('may')) month = 5;
        else if (mStr.startsWith('jun')) month = 6;
        else if (mStr.startsWith('jul')) month = 7;
        else if (mStr.startsWith('agu') || mStr.startsWith('ags') || mStr.startsWith('aug')) month = 8;
        else if (mStr.startsWith('sep')) month = 9;
        else if (mStr.startsWith('okt') || mStr.startsWith('oct')) month = 10;
        else if (mStr.startsWith('nov')) month = 11;
        else if (mStr.startsWith('des') || mStr.startsWith('dec')) month = 12;

        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  /// Automatically categorizes based on merchant and items
  static String _detectCategory(String merchant, String fullText) {
    final mLower = merchant.toLowerCase();

    // 1. Check strong merchant brand matches first
    const shopBrands = [
      'indomaret', 'alfamart', 'alfamidi', 'superindo', 'hypermart',
      'transmart', 'lotte', 'hero', 'farmers', 'ranch market', 'yomart',
      'minimarket', 'supermarket', 'mart', 'swalayan', 'uniqlo',
      'zara', 'h&m', 'miniso', 'gramedia', 'ace hardware', 'ikea',
      'informa', 'mr diy',
    ];
    for (final kw in shopBrands) {
      if (mLower.contains(kw)) return 'Belanja';
    }

    const transportBrands = [
      'spbu', 'pertamina', 'shell', 'bp', 'gojek', 'grab', 'maxim',
      'kai', 'kereta', 'transjakarta', 'mrt', 'lrt', 'damri', 'tol',
    ];
    for (final kw in transportBrands) {
      if (mLower.contains(kw)) return 'Transportasi';
    }

    const foodBrands = [
      'starbucks', 'kopi kenangan', 'fore', 'janji jiwa', 'chatime',
      'mcdonalds', 'mcd', 'kfc', 'hokben', 'dunkin', 'pizza hut',
      'domino', 'solaria', 'gacoan', 'burger king', 'kafe', 'cafe',
      'coffee', 'resto', 'restaurant', 'restoran', 'bakso', 'mie',
      'bakery', 'kitchen', 'warung',
    ];
    for (final kw in foodBrands) {
      if (mLower.contains(kw)) return 'Makanan & Minuman';
    }

    // 2. Check general keywords across full receipt text
    final text = ('$merchant $fullText').toLowerCase();

    // Makanan & Minuman
    final foodKeywords = [
      'kopi', 'coffee', 'cafe', 'kafe', 'resto', 'restaurant', 'restoran',
      'bakso', 'mie', 'warung', 'makan', 'kitchen', 'bakery', 'roti',
      'cake', 'burger', 'pizza', 'starbucks', 'mcdonalds', 'mcd', 'kfc',
      'hokben', 'dunkin', 'chatime', 'janji jiwa', 'kenangan', 'fore',
      'solaria', 'gacoan', 'tea', 'boba', 'kuliner', 'sate', 'ayam', 'nasi',
    ];
    for (final kw in foodKeywords) {
      if (text.contains(kw)) return 'Makanan & Minuman';
    }

    // Transportasi
    final transportKeywords = [
      'spbu', 'pertamina', 'shell', 'bp', 'solar', 'pertalite', 'pertamax',
      'bensin', 'gojek', 'goride', 'gocar', 'gopay', 'grab', 'grabfood',
      'maxim', 'parkir', 'parking', 'tol', 'toll', 'kai', 'kereta', 'tiket',
      'commuter', 'damri', 'transjakarta', 'mrt', 'lrt', 'travel',
    ];
    for (final kw in transportKeywords) {
      if (text.contains(kw)) return 'Transportasi';
    }

    // Belanja
    final shopKeywords = [
      'indomaret', 'alfamart', 'alfamidi', 'superindo', 'hypermart',
      'transmart', 'lotte', 'hero', 'farmers', 'ranch market', 'yomart',
      'minimarket', 'supermarket', 'mart', 'toko', 'swalayan', 'uniqlo',
      'zara', 'h&m', 'miniso', 'gramedia', 'ace hardware', 'ikea',
      'informa', 'mr diy', 'guardian', 'watsons',
    ];
    for (final kw in shopKeywords) {
      if (text.contains(kw)) return 'Belanja';
    }

    // Tagihan & Utilitas
    final billKeywords = [
      'pln', 'listrik', 'pdam', 'air', 'bpjs', 'indihome', 'biznet',
      'first media', 'wifi', 'telkomsel', 'indosat', 'xl', 'tri',
      'smartfren', 'pulsa', 'paket data', 'token',
    ];
    for (final kw in billKeywords) {
      if (text.contains(kw)) return 'Tagihan & Utilitas';
    }

    // Hiburan
    final entKeywords = [
      'cinema', 'xxi', 'cgv', 'cinepolis', 'bioskop', 'movie', 'timezone',
      'game', 'karaoke', 'steam', 'playstation', 'billiard', 'wisata',
    ];
    for (final kw in entKeywords) {
      if (text.contains(kw)) return 'Hiburan';
    }

    // Kesehatan
    final healthKeywords = [
      'apotek', 'apotik', 'kimia farma', 'k24', 'k-24', 'century',
      'farmasi', 'klinik', 'clinic', 'rumah sakit', 'rs', 'dokter',
      'lab', 'prodia', 'obat', 'vitamin', 'dental', 'gigi',
    ];
    for (final kw in healthKeywords) {
      if (text.contains(kw)) return 'Kesehatan';
    }

    return 'Makanan & Minuman';
  }
}
