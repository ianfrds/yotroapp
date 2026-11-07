import '../models/category_model.dart';
import '../models/voice_transaction_item.dart';

/// Intelligent on-device parser for Indonesian spoken financial entries.
class VoiceTransactionParserService {
  static const Map<String, double> _wordNumbers = {
    'nol': 0,
    'kosong': 0,
    'seperempat': 0.25,
    'setengah': 0.5,
    'separuh': 0.5,
    'satu': 1,
    'se': 1,
    'dua': 2,
    'tiga': 3,
    'empat': 4,
    'lima': 5,
    'enam': 6,
    'tujuh': 7,
    'delapan': 8,
    'sembilan': 9,
    'sepuluh': 10,
    'sebelas': 11,
    'seratus': 100,
    'seribu': 1000,
    'sejuta': 1000000,
  };

  /// Main parsing entry point.
  static VoiceParseResult parse(String rawSpeech) {
    final text = rawSpeech.trim();
    if (text.isEmpty) {
      return const VoiceParseResult(
        items: [],
        rawTranscription: '',
        isValid: false,
        validationError: 'Belum ada suara yang terdengar.',
      );
    }

    // 1. Split into prospective item clauses
    final clauses = _splitIntoClauses(text);
    final items = <VoiceTransactionItem>[];

    for (final clause in clauses) {
      final parsedItem = _parseClause(clause);
      if (parsedItem != null) {
        items.add(parsedItem);
      }
    }

    if (items.isEmpty) {
      return VoiceParseResult(
        items: const [],
        rawTranscription: text,
        isValid: false,
        validationError: 'Belum ada nama barang dan nominal yang valid. Contoh: "Kopi 25 ribu".',
      );
    }

    return VoiceParseResult(
      items: items,
      rawTranscription: text,
      isValid: true,
    );
  }

  /// Splits speech by comma, conjunctions, or transitions.
  static List<String> _splitIntoClauses(String text) {
    // Replace newline or comma with standard delimiter "|"
    var normalized = text
        .replaceAll(RegExp(r'[\n\r,;]+'), ' | ')
        .replaceAll(RegExp(r'\s+(?:dan|lalu|kemudian|terus|sama)\s+', caseSensitive: false), ' | ');

    final rawClauses = normalized
        .split('|')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final result = <String>[];
    for (final c in rawClauses) {
      // Further check if multiple amounts exist in a single clause without delimiters
      // e.g. "siomay 13 ribu tahu tek 100 ribu"
      final subClauses = _splitMultiAmountClause(c);
      result.addAll(subClauses);
    }
    return result;
  }

  /// Handles cases where user spoke multiple items without comma or "dan".
  static List<String> _splitMultiAmountClause(String clause) {
    final amountPattern = RegExp(
      r'(\d+(?:[\.,]\d+)?\s*(?:ribu|rb|k|juta|jt|ratus)?|seratus ribu|seribu|sejuta|setengah juta)\b',
      caseSensitive: false,
    );

    final matches = amountPattern.allMatches(clause).toList();
    if (matches.length <= 1) {
      return [clause];
    }

    final subClauses = <String>[];
    int lastEnd = 0;
    for (int i = 0; i < matches.length; i++) {
      final currentMatch = matches[i];
      final chunkEnd = currentMatch.end;
      final chunk = clause.substring(lastEnd, chunkEnd).trim();
      if (chunk.isNotEmpty) {
        subClauses.add(chunk);
      }
      lastEnd = chunkEnd;
    }
    if (lastEnd < clause.length) {
      final remaining = clause.substring(lastEnd).trim();
      if (remaining.isNotEmpty && subClauses.isNotEmpty) {
        subClauses[subClauses.length - 1] += ' $remaining';
      }
    }
    return subClauses;
  }

  /// Parses a single prospective clause into a VoiceTransactionItem.
  static VoiceTransactionItem? _parseClause(String clause) {
    final amountExtraction = _extractAmount(clause);
    if (amountExtraction == null || amountExtraction.amount <= 0) {
      return null;
    }

    // Clean title by removing the amount snippet and filler stopwords
    var title = clause.replaceFirst(amountExtraction.matchedText, ' ').trim();
    title = _cleanItemTitle(title);

    if (title.length < 2) {
      title = 'Pengeluaran';
    }

    final category = _detectCategory(title, clause);
    final isIncome = _detectIncome(clause);

    return VoiceTransactionItem(
      title: title,
      amount: amountExtraction.amount,
      suggestedCategory: isIncome ? 'Gaji' : category,
      type: isIncome ? TransactionType.income : TransactionType.expense,
      rawSnippet: clause,
    );
  }

  /// Extracts numeric amount from clause text.
  static _AmountResult? _extractAmount(String text) {
    final lower = text.toLowerCase().replaceAll('rupiah', '').replaceAll('rp', '');

    // 1. Regex for digit + units: e.g. "13 ribu", "13rb", "13k", "100 ribu", "1.5 juta", "1,5 juta", "50000", "50.000"
    final digitPattern = RegExp(
      r'(\d+(?:[\.,]\d+)?)\s*(ribu|rb|k|juta|jt|ratus)?\b',
      caseSensitive: false,
    );

    final digitMatches = digitPattern.allMatches(lower).toList();
    for (final m in digitMatches) {
      final numStr = m.group(1)!.replaceAll(',', '.');
      final unit = (m.group(2) ?? '').toLowerCase();

      double? baseNum = double.tryParse(numStr);
      if (baseNum != null && baseNum > 0) {
        double multiplier = 1.0;
        if (unit == 'ribu' || unit == 'rb' || unit == 'k') {
          multiplier = 1000.0;
        } else if (unit == 'juta' || unit == 'jt') {
          multiplier = 1000000.0;
        } else if (unit == 'ratus') {
          multiplier = 100.0;
        } else if (unit.isEmpty) {
          // If pure number like 13 -> in spoken Indonesian if < 1000 without unit,
          // sometimes it's shorthand for thousands (e.g. "siomay 13" = 13 ribu)
          // but if >= 1000 (e.g. 25000) it is the literal amount.
          if (baseNum >= 1000) {
            multiplier = 1.0;
          } else if (baseNum <= 100 && (lower.contains('ribu') || lower.contains('rb'))) {
            multiplier = 1000.0;
          }
        }

        final calculated = baseNum * multiplier;
        return _AmountResult(
          amount: calculated,
          matchedText: m.group(0)!,
        );
      }
    }

    // 2. Indonesian spoken words: e.g. "setengah juta", "seratus ribu", "dua puluh lima ribu", "tiga belas ribu"
    final spokenResult = _parseSpokenIndonesianAmount(lower);
    if (spokenResult != null && spokenResult.amount > 0) {
      return spokenResult;
    }

    return null;
  }

  /// Parses purely verbal Indonesian number expressions.
  static _AmountResult? _parseSpokenIndonesianAmount(String text) {
    // Common direct phrases
    if (text.contains('setengah juta')) {
      return const _AmountResult(amount: 500000.0, matchedText: 'setengah juta');
    }
    if (text.contains('sejuta') || text.contains('satu juta')) {
      return _AmountResult(
        amount: 1000000.0,
        matchedText: text.contains('sejuta') ? 'sejuta' : 'satu juta',
      );
    }
    if (text.contains('seratus ribu')) {
      return const _AmountResult(amount: 100000.0, matchedText: 'seratus ribu');
    }
    if (text.contains('seribu')) {
      return const _AmountResult(amount: 1000.0, matchedText: 'seribu');
    }

    // Pattern for compound verbal phrases like "dua puluh lima ribu", "tiga belas ribu"
    final phrasePattern = RegExp(
      r'((?:satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan|sepuluh|sebelas|dua belas|tiga belas|empat belas|lima belas|enam belas|tujuh belas|delapan belas|sembilan belas|dua puluh|tiga puluh|empat puluh|lima puluh|enam puluh|tujuh puluh|delapan puluh|sembilan puluh|seratus|dua ratus|tiga ratus|empat ratus|lima ratus|enam ratus|tujuh ratus|delapan ratus|sembilan ratus|\d+)\s*(?:belas|puluh|ratus)?\s*(?:ribu|rb|juta|jt)?)\b',
      caseSensitive: false,
    );

    final match = phrasePattern.firstMatch(text);
    if (match != null) {
      final phrase = match.group(0)!.trim();
      final val = _convertWordsToNumber(phrase);
      if (val > 0) {
        return _AmountResult(amount: val, matchedText: phrase);
      }
    }
    return null;
  }

  static double _convertWordsToNumber(String phrase) {
    var words = phrase.split(RegExp(r'\s+'));
    double total = 0;
    double current = 0;

    for (int i = 0; i < words.length; i++) {
      final w = words[i].toLowerCase();
      if (_wordNumbers.containsKey(w)) {
        current += _wordNumbers[w]!;
      } else if (w == 'belas') {
        current += 10;
      } else if (w == 'puluh') {
        current = (current == 0 ? 1 : current) * 10;
      } else if (w == 'ratus') {
        current = (current == 0 ? 1 : current) * 100;
      } else if (w == 'ribu' || w == 'rb') {
        total += (current == 0 ? 1 : current) * 1000;
        current = 0;
      } else if (w == 'juta' || w == 'jt') {
        total += (current == 0 ? 1 : current) * 1000000;
        current = 0;
      } else {
        final parsed = double.tryParse(w);
        if (parsed != null) current += parsed;
      }
    }
    total += current;
    return total;
  }

  /// Strips stop words and capitalizes words cleanly.
  static String _cleanItemTitle(String rawTitle) {
    var cleaned = rawTitle
        .replaceAll(RegExp(r'[\(\)\[\]\{\}:;]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Remove leading filler words
    final leadingStopwords = RegExp(
      r'^(?:beli|membeli|buat|untuk|seharga|bayar|sebesar|tadi|jajan|makan|minum)\s+',
      caseSensitive: false,
    );
    while (leadingStopwords.hasMatch(cleaned)) {
      cleaned = cleaned.replaceFirst(leadingStopwords, '').trim();
    }

    // Remove trailing filler words
    final trailingStopwords = RegExp(
      r'\s+(?:seharga|sebesar|tadi|aja|saja|rupiah|rp)$',
      caseSensitive: false,
    );
    while (trailingStopwords.hasMatch(cleaned)) {
      cleaned = cleaned.replaceFirst(trailingStopwords, '').trim();
    }

    // Specific abbreviations: "hp" -> "HP"
    if (cleaned.toLowerCase() == 'hp') return 'HP';

    // Capitalize words
    return cleaned.split(' ').map((word) {
      if (word.isEmpty) return '';
      if (word.toLowerCase() == 'hp') return 'HP';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Matches category against comprehensive Indonesian keyword lists.
  static String _detectCategory(String title, String clause) {
    final t = ('$title $clause').toLowerCase();

    // Makanan & Minuman
    const foodKeywords = [
      'siomay', 'tahu', 'tempe', 'kopi', 'bakso', 'mie', 'soto', 'nasi',
      'ayam', 'burger', 'sate', 'martabak', 'roti', 'teh', 'boba', 'jus',
      'es', 'seblak', 'cilok', 'cireng', 'batagor', 'jajan', 'snack',
      'makan', 'minum', 'warung', 'kafe', 'cafe', 'resto', 'restoran',
      'mcd', 'kfc', 'gacoan', 'dunkin', 'starbucks', 'hokben', 'pizza',
      'rawon', 'pecel', 'bebek', 'gudeg', 'kuliner',
    ];
    for (final kw in foodKeywords) {
      if (t.contains(kw)) return 'Makanan & Minuman';
    }

    // Belanja
    const shopKeywords = [
      'keyboard', 'mouse', 'hp', 'handphone', 'laptop', 'gadget', 'casing',
      'charger', 'baju', 'celana', 'sepatu', 'kaos', 'jaket', 'buku', 'tas',
      'belanja', 'mart', 'supermarket', 'indomaret', 'alfamart', 'alfamidi',
      'uniqlo', 'zara', 'h&m', 'miniso', 'shopee', 'tokopedia', 'lazada',
      'elektronik', 'headset', 'earphone', 'monitor', 'kabel',
    ];
    for (final kw in shopKeywords) {
      if (t.contains(kw)) return 'Belanja';
    }

    // Transportasi
    const transportKeywords = [
      'bensin', 'pertalite', 'pertamax', 'gojek', 'grab', 'maxim', 'parkir',
      'tol', 'krl', 'mrt', 'kereta', 'tiket', 'travel', 'oli', 'servis',
      'spbu', 'pertamina', 'shell', 'bp', 'transjakarta', 'bus', 'damri',
    ];
    for (final kw in transportKeywords) {
      if (t.contains(kw)) return 'Transportasi';
    }

    // Tagihan & Utilitas
    const billKeywords = [
      'listrik', 'pln', 'token', 'pdam', 'pulsa', 'kuota', 'paket data',
      'wifi', 'indihome', 'biznet', 'bpjs', 'air', 'pbb',
    ];
    for (final kw in billKeywords) {
      if (t.contains(kw)) return 'Tagihan & Utilitas';
    }

    // Hiburan
    const entertainmentKeywords = [
      'nonton', 'bioskop', 'movie', 'cinema', 'xxi', 'cgv', 'netflix',
      'spotify', 'game', 'steam', 'playstation', 'karaoke', 'konser',
    ];
    for (final kw in entertainmentKeywords) {
      if (t.contains(kw)) return 'Hiburan';
    }

    // Kesehatan
    const healthKeywords = [
      'obat', 'dokter', 'apotek', 'vitamin', 'klinik', 'puskesmas', 'periksa',
      'masker', 'panadol', 'paracetamol', 'bodrex',
    ];
    for (final kw in healthKeywords) {
      if (t.contains(kw)) return 'Kesehatan';
    }

    // Pendidikan
    const eduKeywords = [
      'kuliah', 'spp', 'kursus', 'les', 'sekolah', 'fotokopi', 'ujian',
    ];
    for (final kw in eduKeywords) {
      if (t.contains(kw)) return 'Pendidikan';
    }

    return 'Makanan & Minuman';
  }

  /// Checks if phrase implies income.
  static bool _detectIncome(String clause) {
    final lower = clause.toLowerCase();
    const incomeKeywords = [
      'gaji', 'bonus', 'dividen', 'komisi', 'cashback', 'refund',
      'hadiah', 'upah', 'pendapatan', 'uang masuk', 'terima transfer',
    ];
    for (final kw in incomeKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }
}

class _AmountResult {
  final double amount;
  final String matchedText;

  const _AmountResult({
    required this.amount,
    required this.matchedText,
  });
}
