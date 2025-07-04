import 'package:rational/rational.dart';
import 'package:test/test.dart';
import 'package:komodo_wallet/shared/utils/balances_formatter.dart';

import 'test_util.dart';

void testGetFiatAmount() {
  test('formatting double DEX amount tests:', () {
    expect(getFiatAmount(setCoin(usdPrice: 10.12), Rational.one), 10.12);
    expect(
        getFiatAmount(
          setCoin(usdPrice: 10.12),
          Rational(BigInt.from(1), BigInt.from(10)),
        ),
        1.012);
    expect(
        getFiatAmount(
          setCoin(usdPrice: null),
          Rational(BigInt.from(1), BigInt.from(10)),
        ),
        0.0);
    expect(
        getFiatAmount(
          setCoin(usdPrice: 0),
          Rational(BigInt.from(1), BigInt.from(10)),
        ),
        0.0);
    expect(
        getFiatAmount(
          setCoin(usdPrice: 1e-7),
          Rational(BigInt.from(1), BigInt.from(1e10)),
        ),
        1e-17);
    expect(
        getFiatAmount(
          setCoin(usdPrice: 1.23e40),
          Rational(BigInt.from(2), BigInt.from(1e50)),
        ),
        2.46e-10);
    // Amount of atoms in the universe is ~10^80
    expect(
        getFiatAmount(
          setCoin(usdPrice: 1.2345e40),
          Rational(BigInt.from(1e50), BigInt.from(1)),
        ),
        1.2345e90);
  });
}
