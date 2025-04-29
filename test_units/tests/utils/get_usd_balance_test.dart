import 'package:test/test.dart';

import 'test_util.dart';

void testUsdBalanceFormatter() {
  test('Get from Coin usd price and return formatted string', () {
    expect(
        setCoin(usdPrice: 10.12, balance: 1).getFormattedUsdBalance, '\$10.12');
    expect(setCoin(usdPrice: 0, balance: 1).getFormattedUsdBalance, '\$0.00');
    expect(
        setCoin(usdPrice: null, balance: 1).getFormattedUsdBalance, '\$0.00');
    expect(setCoin(usdPrice: 0.0000001, balance: 1).getFormattedUsdBalance,
        '\$0.0000001');
    expect(setCoin(usdPrice: 123456789, balance: 1).getFormattedUsdBalance,
        '\$123456789.00');
    expect(setCoin(usdPrice: 123456789, balance: 0).getFormattedUsdBalance,
        '\$0.00');
  });
}
