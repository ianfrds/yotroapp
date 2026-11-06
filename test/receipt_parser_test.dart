import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/services/receipt_scanner/receipt_parser_service.dart';

void main() {
  group('ReceiptParserService Tests', () {
    test('parses Indomaret receipt with grand total and belanja category', () {
      const sample = '''
INDOMARET POINT JUANDA
PT. INDOMARCO PRISMATAMA
JL. IR. H. JUANDA NO. 12 JAKARTA
NPWP: 01.337.994.6-054.000

TGL: 05-11-2026  20:15:22
KASIR: RIZKY / 02

ROTI TAWAR SARI ROTI    15.000
ULTRA MILK COKLAT 1L    21.500
INDOMIE GORENG 5X       15.500

SUBTOTAL                52.000
DISKON PROMO            (2.000)
GRAND TOTAL             50.000
TUNAI                   100.000
KEMBALI                 50.000

TERIMA KASIH ATAS BELANJA ANDA
''';

      final result = ReceiptParserService.parseText(sample);
      expect(result.merchantName, contains('INDOMARET POINT'));
      expect(result.totalAmount, 50000.0);
      expect(result.suggestedCategory, 'Belanja');
      expect(result.date.year, 2026);
      expect(result.date.month, 11);
      expect(result.date.day, 5);
      expect(result.alternativeAmounts, contains(52000.0));
    });

    test('parses SPBU Pertamina receipt with Transportasi category', () {
      const sample = '''
SPBU 31.129.02 PERTAMINA
JL. GATOT SUBROTO KAV 50

TANGGAL: 04/11/2026 08:30
POMPA : 03
PRODUK: PERTAMAX (RON 92)
LITER : 20.00 L
HARGA/L : 13.500

TOTAL : Rp 270.000
PEMBAYARAN: QRIS MYPERTAMINA

PASTIKAN TANGKI TERTUTUP RAPAT
TERIMA KASIH
''';

      final result = ReceiptParserService.parseText(sample);
      expect(result.merchantName, contains('SPBU'));
      expect(result.totalAmount, 270000.0);
      expect(result.suggestedCategory, 'Transportasi');
      expect(result.date.day, 4);
      expect(result.date.month, 11);
      expect(result.date.year, 2026);
    });

    test('parses Cafe receipt with PB1 tax and Makanan & Minuman category', () {
      const sample = '''
KOPI KENANGAN
SENAYAN CITY LT. LG

02 Nov 2026  16:45

2x Kopi Kenangan Mantan   36.000
1x Avocado Coffee         24.000

SUBTOTAL                  60.000
PB1 (10%)                  6.000
TOTAL BAYAR               66.000
DEBIT BCA                 66.000
''';

      final result = ReceiptParserService.parseText(sample);
      expect(result.merchantName, 'KOPI KENANGAN');
      expect(result.totalAmount, 66000.0);
      expect(result.suggestedCategory, 'Makanan & Minuman');
      expect(result.date.month, 11);
      expect(result.date.day, 2);
      expect(result.date.year, 2026);
      expect(result.alternativeAmounts, contains(60000.0));
    });

    test('handles empty text gracefully without throwing', () {
      final result = ReceiptParserService.parseText('');
      expect(result.totalAmount, 0.0);
      expect(result.merchantName, isEmpty);
      expect(result.alternativeAmounts, isEmpty);
    });
  });
}

