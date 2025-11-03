import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/shared/utils/formatters.dart';

void main() {
  group('normalizeDecimalString', () {
    test('handles simple comma as decimal separator', () {
      expect(normalizeDecimalString('1,23'), '1.23');
      expect(normalizeDecimalString('0,5'), '0.5');
      expect(normalizeDecimalString('123,456'), '123.456');
    });

    test('handles simple dot as decimal separator', () {
      expect(normalizeDecimalString('1.23'), '1.23');
      expect(normalizeDecimalString('0.5'), '0.5');
      expect(normalizeDecimalString('123.456'), '123.456');
    });

    test('handles European format (dot as thousands, comma as decimal)', () {
      expect(normalizeDecimalString('1.234,56'), '1234.56');
      expect(normalizeDecimalString('12.345.678,90'), '12345678.90');
    });

    test('handles US format (comma as thousands, dot as decimal)', () {
      expect(normalizeDecimalString('1,234.56'), '1234.56');
      expect(normalizeDecimalString('12,345,678.90'), '12345678.90');
    });

    test('handles French format (space as thousands, comma as decimal)', () {
      expect(normalizeDecimalString('1 234,56'), '1234.56');
      expect(normalizeDecimalString('12 345 678,90'), '12345678.90');
    });

    test('handles NBSP (U+00A0) as thousands separator', () {
      expect(normalizeDecimalString('1\u00A0234,56'), '1234.56');
      expect(normalizeDecimalString('12\u00A0345\u00A0678,90'), '12345678.90');
    });

    test('handles NNBSP (U+202F) as thousands separator', () {
      expect(normalizeDecimalString('1\u202F234,56'), '1234.56');
      expect(normalizeDecimalString('12\u202F345\u202F678,90'), '12345678.90');
    });

    test('handles apostrophe as thousands separator', () {
      expect(normalizeDecimalString("1'234,56"), '1234.56');
      expect(normalizeDecimalString("12'345'678,90"), '12345678.90');
    });

    test('handles underscore as thousands separator', () {
      expect(normalizeDecimalString('1_234,56'), '1234.56');
      expect(normalizeDecimalString('12_345_678,90'), '12345678.90');
    });

    test('handles leading comma or dot', () {
      expect(normalizeDecimalString(',5'), '0.5');
      expect(normalizeDecimalString('.5'), '0.5');
      expect(normalizeDecimalString(',123'), '0.123');
      expect(normalizeDecimalString('.123'), '0.123');
    });

    test('handles integers without decimal separator', () {
      expect(normalizeDecimalString('123'), '123');
      expect(normalizeDecimalString('0'), '0');
      expect(normalizeDecimalString('999999'), '999999');
    });

    test('handles trailing zeros', () {
      expect(normalizeDecimalString('1.00'), '1.00');
      expect(normalizeDecimalString('1,00'), '1.00');
      expect(normalizeDecimalString('123.4500'), '123.4500');
    });

    test('handles whitespace trimming', () {
      expect(normalizeDecimalString('  1,23  '), '1.23');
      expect(normalizeDecimalString('\t1.23\n'), '1.23');
    });

    test('throws on empty string', () {
      expect(() => normalizeDecimalString(''), throwsFormatException);
    });

    test('throws on negative numbers', () {
      expect(() => normalizeDecimalString('-1.23'), throwsFormatException);
      expect(() => normalizeDecimalString('-0,5'), throwsFormatException);
    });

    test('throws on multiple decimal separators', () {
      expect(() => normalizeDecimalString('1.2.3'), throwsFormatException);
      expect(() => normalizeDecimalString('1,2,3'), throwsFormatException);
    });

    test('throws on invalid characters', () {
      expect(() => normalizeDecimalString('abc'), throwsFormatException);
      expect(() => normalizeDecimalString('1.2a3'), throwsFormatException);
      expect(() => normalizeDecimalString('1e5'), throwsFormatException);
    });

    test('handles edge case: only decimal separator', () {
      expect(normalizeDecimalString('.'), '0.');
      expect(normalizeDecimalString(','), '0.');
    });

    test('handles mixed separators with last as decimal', () {
      // Last separator is comma, so it's decimal
      expect(normalizeDecimalString('1.234.567,89'), '1234567.89');
      // Last separator is dot, so it's decimal
      expect(normalizeDecimalString('1,234,567.89'), '1234567.89');
    });
  });

  group('parseLocaleAwareDecimal', () {
    test('parses simple comma format', () {
      expect(parseLocaleAwareDecimal('1,23'), Decimal.parse('1.23'));
      expect(parseLocaleAwareDecimal('0,5'), Decimal.parse('0.5'));
    });

    test('parses simple dot format', () {
      expect(parseLocaleAwareDecimal('1.23'), Decimal.parse('1.23'));
      expect(parseLocaleAwareDecimal('0.5'), Decimal.parse('0.5'));
    });

    test('parses European format', () {
      expect(parseLocaleAwareDecimal('1.234,56'), Decimal.parse('1234.56'));
    });

    test('parses US format', () {
      expect(parseLocaleAwareDecimal('1,234.56'), Decimal.parse('1234.56'));
    });

    test('parses integers', () {
      expect(parseLocaleAwareDecimal('123'), Decimal.parse('123'));
      expect(parseLocaleAwareDecimal('0'), Decimal.zero);
    });

    test('throws on invalid input', () {
      expect(() => parseLocaleAwareDecimal(''), throwsFormatException);
      expect(() => parseLocaleAwareDecimal('abc'), throwsFormatException);
      expect(() => parseLocaleAwareDecimal('-1.23'), throwsFormatException);
    });
  });

  group('parseLocaleAwareRational', () {
    test('parses simple comma format', () {
      expect(parseLocaleAwareRational('1,23'), Rational.parse('1.23'));
      expect(parseLocaleAwareRational('0,5'), Rational.parse('0.5'));
    });

    test('parses simple dot format', () {
      expect(parseLocaleAwareRational('1.23'), Rational.parse('1.23'));
      expect(parseLocaleAwareRational('0.5'), Rational.parse('0.5'));
    });

    test('parses European format', () {
      expect(parseLocaleAwareRational('1.234,56'), Rational.parse('1234.56'));
    });

    test('parses US format', () {
      expect(parseLocaleAwareRational('1,234.56'), Rational.parse('1234.56'));
    });

    test('parses integers', () {
      expect(parseLocaleAwareRational('123'), Rational.fromInt(123));
      expect(parseLocaleAwareRational('0'), Rational.zero);
    });

    test('throws on invalid input', () {
      expect(() => parseLocaleAwareRational(''), throwsFormatException);
      expect(() => parseLocaleAwareRational('abc'), throwsFormatException);
      expect(() => parseLocaleAwareRational('-1.23'), throwsFormatException);
    });
  });

  group('Real-world scenarios', () {
    test('Russian locale input', () {
      // Russian locale uses comma as decimal separator
      expect(normalizeDecimalString('1,23'), '1.23');
      expect(parseLocaleAwareDecimal('1,23'), Decimal.parse('1.23'));
      expect(parseLocaleAwareRational('1,23'), Rational.parse('1.23'));
    });

    test('German locale input', () {
      // German locale uses dot as thousands, comma as decimal
      expect(normalizeDecimalString('1.234,56'), '1234.56');
      expect(parseLocaleAwareDecimal('1.234,56'), Decimal.parse('1234.56'));
    });

    test('French locale input', () {
      // French locale uses space as thousands, comma as decimal
      expect(normalizeDecimalString('1 234,56'), '1234.56');
      expect(parseLocaleAwareDecimal('1 234,56'), Decimal.parse('1234.56'));
    });

    test('Swiss locale input', () {
      // Swiss locale uses apostrophe as thousands, dot as decimal
      expect(normalizeDecimalString("1'234.56"), '1234.56');
      expect(parseLocaleAwareDecimal("1'234.56"), Decimal.parse('1234.56'));
    });
  });
}
