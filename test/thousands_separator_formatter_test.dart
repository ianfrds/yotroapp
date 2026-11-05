import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/utils/thousands_separator_formatter.dart';

void main() {
  group('ThousandsSeparatorInputFormatter', () {
    const formatter = ThousandsSeparatorInputFormatter();

    test('formatNumber static method formats correctly', () {
      expect(ThousandsSeparatorInputFormatter.formatNumber('0'), '0');
      expect(ThousandsSeparatorInputFormatter.formatNumber('00'), '0');
      expect(ThousandsSeparatorInputFormatter.formatNumber('05'), '5');
      expect(ThousandsSeparatorInputFormatter.formatNumber('5000'), '5.000');
      expect(ThousandsSeparatorInputFormatter.formatNumber('100000'), '100.000');
      expect(ThousandsSeparatorInputFormatter.formatNumber('2000000'), '2.000.000');
      expect(ThousandsSeparatorInputFormatter.formatNumber(''), '');
    });

    test('replaces default 0 when user types after 0', () {
      const oldVal = TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 1),
      );
      const newVal = TextEditingValue(
        text: '05',
        selection: TextSelection.collapsed(offset: 2),
      );

      final result = formatter.formatEditUpdate(oldVal, newVal);
      expect(result.text, '5');
      expect(result.selection.baseOffset, 1);
    });

    test('replaces default 0 when user types before 0', () {
      const oldVal = TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 0),
      );
      const newVal = TextEditingValue(
        text: '50',
        selection: TextSelection.collapsed(offset: 1),
      );

      final result = formatter.formatEditUpdate(oldVal, newVal);
      expect(result.text, '5');
      expect(result.selection.baseOffset, 1);
    });

    test('preserves 0 when user types 0 over 0', () {
      const oldVal = TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 1),
      );
      const newVal = TextEditingValue(
        text: '00',
        selection: TextSelection.collapsed(offset: 2),
      );

      final result = formatter.formatEditUpdate(oldVal, newVal);
      expect(result.text, '0');
      expect(result.selection.baseOffset, 1);
    });

    test('formats thousands with dots: 500 -> 5.000', () {
      const oldVal = TextEditingValue(
        text: '500',
        selection: TextSelection.collapsed(offset: 3),
      );
      const newVal = TextEditingValue(
        text: '5000',
        selection: TextSelection.collapsed(offset: 4),
      );

      final result = formatter.formatEditUpdate(oldVal, newVal);
      expect(result.text, '5.000');
      expect(result.selection.baseOffset, 5);
    });

    test('formats millions with dots: 100.000 -> 2.000.000', () {
      final res1 = formatter.formatEditUpdate(
        const TextEditingValue(text: '10.000', selection: TextSelection.collapsed(offset: 6)),
        const TextEditingValue(text: '10.0000', selection: TextSelection.collapsed(offset: 7)),
      );
      expect(res1.text, '100.000');
      expect(res1.selection.baseOffset, 7);

      final res2 = formatter.formatEditUpdate(
        const TextEditingValue(text: '200.000', selection: TextSelection.collapsed(offset: 7)),
        const TextEditingValue(text: '200.0000', selection: TextSelection.collapsed(offset: 8)),
      );
      expect(res2.text, '2.000.000');
      expect(res2.selection.baseOffset, 9);
    });

    test('clearing input results in empty string without crashing', () {
      const oldVal = TextEditingValue(
        text: '5',
        selection: TextSelection.collapsed(offset: 1),
      );
      const newVal = TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );

      final result = formatter.formatEditUpdate(oldVal, newVal);
      expect(result.text, '');
      expect(result.selection.baseOffset, 0);
    });
  });
}

