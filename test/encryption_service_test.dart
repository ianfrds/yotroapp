import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/services/encryption_service.dart';

void main() {
  const testUserId = 'e4b3c2a1-0000-4000-8000-0123456789ab';
  const otherUserId = 'f8a7b6c5-1111-4111-9111-abcdef012345';

  group('EncryptionService Tests', () {
    test('deriveKey returns consistent 32-byte key for same userId', () {
      final key1 = EncryptionService.deriveKey(testUserId);
      final key2 = EncryptionService.deriveKey(testUserId);
      final keyOther = EncryptionService.deriveKey(otherUserId);

      expect(key1.length, 32);
      expect(key1, equals(key2));
      expect(key1, isNot(equals(keyOther)));
    });

    test('deriveKey throws ArgumentError on empty userId', () {
      expect(() => EncryptionService.deriveKey(''), throwsArgumentError);
      expect(() => EncryptionService.deriveKey('   '), throwsArgumentError);
    });

    test('encryptString produces ciphertext with enc:v1: prefix', () {
      const plaintext = 'Beli Kopi Kenangan';
      final ciphertext = EncryptionService.encryptString(plaintext, testUserId);

      expect(ciphertext.startsWith(EncryptionService.prefix), isTrue);
      expect(ciphertext, isNot(equals(plaintext)));

      final parts = ciphertext.split(':');
      expect(parts.length, 4);
      expect(parts[0], 'enc');
      expect(parts[1], 'v1');
    });

    test('encryptString and decryptString roundtrip successfully', () {
      const texts = [
        'Beli Makan Siang Rp 25.000',
        'Gaji Bulan November 2026',
        'Pembayaran cicilan & tagihan kartu kredit 1234-5678',
        'Special characters: !@#\$%^&*()_+{}[]:;<>,.?/~`|',
        'Unicode text: 日本語, 한국어, العربية, 🚀💰📊',
      ];

      for (final text in texts) {
        final cipher = EncryptionService.encryptString(text, testUserId);
        final decrypted = EncryptionService.decryptString(cipher, testUserId);
        expect(decrypted, equals(text));
      }
    });

    test('decryptString returns original text on non-matching userId', () {
      const plaintext = 'Rahasia Keuangan';
      final cipher = EncryptionService.encryptString(plaintext, testUserId);

      // Decrypting with different user ID should fail gracefully and not throw
      final failedAttempt = EncryptionService.decryptString(cipher, otherUserId);
      expect(failedAttempt, isNot(equals(plaintext)));
    });

    test('decryptString handles legacy plaintext gracefully (backward compatibility)', () {
      const legacyText = 'Pengeluaran Kopi Tradisional';
      final result = EncryptionService.decryptString(legacyText, testUserId);
      expect(result, equals(legacyText));
    });

    test('decryptString handles null and empty string safely', () {
      expect(EncryptionService.decryptString(null, testUserId), equals(''));
      expect(EncryptionService.decryptString('', testUserId), equals(''));
      expect(EncryptionService.encryptString(null, testUserId), equals(''));
      expect(EncryptionService.encryptString('', testUserId), equals(''));
    });

    test('encryptAmount and decryptAmount roundtrip accurately', () {
      final amounts = [0.0, 15000.0, 250000.5, 9999999999.0, 12.34];

      for (final amt in amounts) {
        final cipher = EncryptionService.encryptAmount(amt, testUserId);
        expect(cipher.startsWith(EncryptionService.prefix), isTrue);

        final decrypted = EncryptionService.decryptAmount(cipher, testUserId);
        expect(decrypted, equals(amt));
      }
    });

    test('decryptAmount supports legacy numeric types and plain strings', () {
      // Legacy num from database
      expect(EncryptionService.decryptAmount(45000, testUserId), equals(45000.0));
      expect(EncryptionService.decryptAmount(45000.75, testUserId), equals(45000.75));

      // Legacy string numbers
      expect(EncryptionService.decryptAmount('45000', testUserId), equals(45000.0));
      expect(EncryptionService.decryptAmount('45000.75', testUserId), equals(45000.75));

      // Invalid/null fallback
      expect(EncryptionService.decryptAmount(null, testUserId), equals(0.0));
      expect(EncryptionService.decryptAmount('not_a_number', testUserId), equals(0.0));
    });
  });
}
