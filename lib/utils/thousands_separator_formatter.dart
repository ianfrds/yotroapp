import 'dart:math';
import 'package:flutter/services.dart';

/// Formatter that automatically groups numbers with dot ('.') as thousands separator
/// and prevents leading zeros when typing financial amounts.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  const ThousandsSeparatorInputFormatter();

  /// Format a string of numbers or digits into dot-separated thousands (e.g. "5000" -> "5.000").
  static String formatNumber(String value) {
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';

    // Strip leading zeros unless it is just "0"
    digits = digits.replaceFirst(RegExp(r'^0+(?!$)'), '');
    if (digits.isEmpty) digits = '0';

    return _groupThousands(digits);
  }

  /// Parse a formatted string with dots or symbols into a double.
  static double parseNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(digits) ?? 0.0;
  }

  static String _groupThousands(String digits) {
    if (digits.isEmpty) return '';
    final len = digits.length;
    final buffer = StringBuffer();
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    String rawDigits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (rawDigits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // When default '0' is present and user types a digit, replace the '0'
    if (oldValue.text == '0' && rawDigits.length > 1) {
      if (rawDigits.startsWith('0')) {
        rawDigits = rawDigits.substring(1);
      } else if (rawDigits.endsWith('0') && newValue.selection.baseOffset <= 1) {
        rawDigits = rawDigits.substring(0, rawDigits.length - 1);
      }
    }

    // Count how many leading zeros are stripped
    int leadingZerosStripped = 0;
    if (rawDigits.startsWith('0')) {
      final match = RegExp(r'^0+').firstMatch(rawDigits);
      final zerosCount = match != null ? match.group(0)!.length : 0;
      if (zerosCount == rawDigits.length) {
        leadingZerosStripped = zerosCount - 1;
      } else {
        leadingZerosStripped = zerosCount;
      }
    }

    // Clean digits with no leading zero (except single '0')
    String cleanDigits = rawDigits.replaceFirst(RegExp(r'^0+(?!$)'), '');
    if (cleanDigits.isEmpty) cleanDigits = '0';

    // Calculate digits before cursor in newValue
    final int cursorOffset = newValue.selection.end.clamp(0, newValue.text.length);
    final String textBeforeCursor = newValue.text.substring(0, cursorOffset);
    final String digitsBefore = textBeforeCursor.replaceAll(RegExp(r'[^0-9]'), '');

    final int strippedBeforeCursor = min(digitsBefore.length, leadingZerosStripped);
    final int targetDigitsBeforeCursor = digitsBefore.length - strippedBeforeCursor;

    final String formattedText = _groupThousands(cleanDigits);

    int newCursorOffset = 0;
    if (targetDigitsBeforeCursor <= 0) {
      newCursorOffset = cleanDigits == '0' ? formattedText.length : 0;
    } else {
      int seenDigits = 0;
      for (int i = 0; i < formattedText.length; i++) {
        if (formattedText[i] != '.') {
          seenDigits++;
        }
        if (seenDigits == targetDigitsBeforeCursor) {
          newCursorOffset = i + 1;
          break;
        }
      }
      if (seenDigits < targetDigitsBeforeCursor) {
        newCursorOffset = formattedText.length;
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: newCursorOffset.clamp(0, formattedText.length),
      ),
    );
  }
}

