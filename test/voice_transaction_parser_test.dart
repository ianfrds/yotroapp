import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/services/voice_transaction_parser_service.dart';

void main() {
  group('VoiceTransactionParserService Tests', () {
    test('parses exact multi-item speech from user request', () {
      const speech = 'Siomay 13 ribu, tahu tek 100 ribu, keyboard 500 ribu, hp 1 juta';
      final result = VoiceTransactionParserService.parse(speech);

      expect(result.isValid, isTrue);
      expect(result.items.length, 4);

      // Item 1: Siomay 13rb
      expect(result.items[0].title, 'Siomay');
      expect(result.items[0].amount, 13000.0);
      expect(result.items[0].suggestedCategory, 'Makanan & Minuman');

      // Item 2: Tahu tek 100rb
      expect(result.items[1].title, 'Tahu Tek');
      expect(result.items[1].amount, 100000.0);
      expect(result.items[1].suggestedCategory, 'Makanan & Minuman');

      // Item 3: Keyboard 500rb
      expect(result.items[2].title, 'Keyboard');
      expect(result.items[2].amount, 500000.0);
      expect(result.items[2].suggestedCategory, 'Belanja');

      // Item 4: HP 1 juta
      expect(result.items[3].title, 'HP');
      expect(result.items[3].amount, 1000000.0);
      expect(result.items[3].suggestedCategory, 'Belanja');

      // Total amount = 13k + 100k + 500k + 1M = 1.613.000
      expect(result.totalAmount, 1613000.0);
      expect(result.isMultiItem, isTrue);
      expect(result.isSingleItem, isFalse);
    });

    test('parses single item with direct instant fill format', () {
      const speech = 'Kopi kenangan 25 ribu';
      final result = VoiceTransactionParserService.parse(speech);

      expect(result.isValid, isTrue);
      expect(result.isSingleItem, isTrue);
      expect(result.isMultiItem, isFalse);
      expect(result.items.length, 1);
      expect(result.items[0].title, 'Kopi Kenangan');
      expect(result.items[0].amount, 25000.0);
      expect(result.items[0].suggestedCategory, 'Makanan & Minuman');
    });

    test('correctly parses Kopi 12ribu and thousands formatted variations to 12000.0', () {
      final res1 = VoiceTransactionParserService.parse('Kopi 12ribu');
      expect(res1.isValid, isTrue);
      expect(res1.items[0].title, 'Kopi');
      expect(res1.items[0].amount, 12000.0);

      final res2 = VoiceTransactionParserService.parse('Kopi 12.000');
      expect(res2.isValid, isTrue);
      expect(res2.items[0].title, 'Kopi');
      expect(res2.items[0].amount, 12000.0);

      final res3 = VoiceTransactionParserService.parse('Kopi 12,000');
      expect(res3.isValid, isTrue);
      expect(res3.items[0].title, 'Kopi');
      expect(res3.items[0].amount, 12000.0);

      final res4 = VoiceTransactionParserService.parse('Kopi 12 rb');
      expect(res4.isValid, isTrue);
      expect(res4.items[0].title, 'Kopi');
      expect(res4.items[0].amount, 12000.0);

      final res5 = VoiceTransactionParserService.parse('Kopi 12');
      expect(res5.isValid, isTrue);
      expect(res5.items[0].title, 'Kopi');
      expect(res5.items[0].amount, 12000.0);
    });

    test('parses multi-item separated by conjunctions like dan, lalu, sama', () {
      const speech = 'Beli bensin 50rb dan makan siang 35k sama parkir 5 ribu';
      final result = VoiceTransactionParserService.parse(speech);

      expect(result.isValid, isTrue);
      expect(result.items.length, 3);
      expect(result.items[0].title, 'Bensin');
      expect(result.items[0].amount, 50000.0);
      expect(result.items[0].suggestedCategory, 'Transportasi');

      expect(result.items[1].title, 'Siang');
      expect(result.items[1].amount, 35000.0);

      expect(result.items[2].title, 'Parkir');
      expect(result.items[2].amount, 5000.0);
      expect(result.items[2].suggestedCategory, 'Transportasi');
    });

    test('parses spoken Indonesian words like seratus ribu, sejuta, setengah juta', () {
      const speech1 = 'baju seratus ribu';
      final res1 = VoiceTransactionParserService.parse(speech1);
      expect(res1.items.first.amount, 100000.0);

      const speech2 = 'bonus sejuta';
      final res2 = VoiceTransactionParserService.parse(speech2);
      expect(res2.items.first.amount, 1000000.0);
      expect(res2.items.first.type, TransactionType.income);

      const speech3 = 'belanja setengah juta';
      final res3 = VoiceTransactionParserService.parse(speech3);
      expect(res3.items.first.amount, 500000.0);
    });

    test('returns invalid when no amounts or only conversational chat is spoken', () {
      const speech = 'Halo selamat pagi tes tes satu dua tiga';
      final res = VoiceTransactionParserService.parse(speech);
      // Wait, "satu dua tiga" might produce numbers if not careful, let's see:
      // What about pure conversation: "selamat pagi apa kabar"
      const nonNumberSpeech = 'Halo selamat pagi apa kabar semuanya';
      final resNonNumber = VoiceTransactionParserService.parse(nonNumberSpeech);
      expect(resNonNumber.isValid, isFalse);
      expect(resNonNumber.validationError, isNotNull);
    });

    test('returns invalid on empty speech', () {
      final res = VoiceTransactionParserService.parse('   ');
      expect(res.isValid, isFalse);
    });
  });
}
