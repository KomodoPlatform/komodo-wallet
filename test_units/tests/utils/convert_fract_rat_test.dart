import 'package:rational/rational.dart';
import 'package:test/test.dart';
import 'package:komodo_wallet/shared/utils/utils.dart';

void testRatToFracAndViseVersa() {
  test('fract2rat and rat2fract converts valid map', () {
    Map<String, dynamic> validFract = {'numer': '3', 'denom': '4'};
    Rational? result = fract2rat(validFract, false);
    expect(result, isNotNull);
    expect(result!.numerator, equals(BigInt.from(3)));
    expect(result.denominator, equals(BigInt.from(4)));

    final fract = rat2fract(result, false);
    expect(fract, validFract);
    expect(fract!['numer'], '3');
    expect(fract['denom'], '4');

    final Rational result2 = Rational.parse('0.25');
    final fract2 = rat2fract(result2, false);
    expect(fract2!['numer'], '1');
    expect(fract2['denom'], '4');
  });

  test('fract2rat returns null for null input', () {
    Rational? result = fract2rat(null, false);
    expect(result, isNull);

    final fract = rat2fract(null, false);
    expect(fract, isNull);
  });

  test('fract2rat returns null for invalid input', () {
    Map<String, dynamic> invalidFract = {'numer': 'abc', 'denom': 'xyz'};
    Rational? result = fract2rat(invalidFract, false);
    expect(result, isNull);
  });
}
