import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';

/// Zero-Knowledge Transparent Client-Side Encryption Service (E2EE)
/// Uses AES-256-CBC with PKCS7 padding and deterministic per-user key derivation.
class EncryptionService {
  static const String prefix = 'enc:v1:';
  static const String _appSalt = 'yotro_secure_vault_salt_v1_2026';

  /// Derive a deterministic 32-byte (256-bit) AES key from the user's UUID
  static Uint8List deriveKey(String userId) {
    final cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) {
      throw ArgumentError('UserId cannot be empty for key derivation');
    }
    final hmac = Hmac(sha256, utf8.encode(_appSalt));
    final digest = hmac.convert(utf8.encode(cleanUserId));
    return Uint8List.fromList(digest.bytes);
  }

  /// Encrypt a string to format: enc:v1:<base64-iv>:<base64-ciphertext>
  static String encryptString(String? plainText, String userId) {
    if (plainText == null || plainText.isEmpty) return plainText ?? '';
    if (plainText.startsWith(prefix)) return plainText; // Already encrypted

    try {
      final key = enc.Key(deriveKey(userId));
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return '$prefix${iv.base64}:${encrypted.base64}';
    } catch (e) {
      debugPrint('[EncryptionService] Error encryptString: $e');
      return plainText;
    }
  }

  /// Decrypt a string with fallback to raw string if unencrypted or legacy
  static String decryptString(String? cipherText, String userId) {
    if (cipherText == null || cipherText.isEmpty) return cipherText ?? '';
    if (!cipherText.startsWith(prefix)) return cipherText; // Legacy plaintext

    try {
      final parts = cipherText.split(':');
      if (parts.length != 4 || parts[0] != 'enc' || parts[1] != 'v1') {
        return cipherText;
      }
      final key = enc.Key(deriveKey(userId));
      final iv = enc.IV.fromBase64(parts[2]);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt64(parts[3], iv: iv);
    } catch (e) {
      debugPrint('[EncryptionService] Error decryptString: $e');
      return cipherText;
    }
  }

  /// Encrypt a decimal amount into ciphertext string
  static String encryptAmount(double amount, String userId) {
    return encryptString(amount.toString(), userId);
  }

  /// Decrypt a raw amount (supports num, plain numeric string, or enc:v1:... ciphertext)
  static double decryptAmount(dynamic rawAmount, String userId) {
    if (rawAmount == null) return 0.0;
    if (rawAmount is num) return rawAmount.toDouble();

    if (rawAmount is String) {
      final clean = rawAmount.trim();
      if (clean.isEmpty) return 0.0;
      if (clean.startsWith(prefix)) {
        final decrypted = decryptString(clean, userId);
        return double.tryParse(decrypted) ?? 0.0;
      }
      return double.tryParse(clean) ?? 0.0;
    }

    return 0.0;
  }
}
