import 'package:rational/rational.dart';
import 'package:test/test.dart';
import 'package:komodo_wallet/model/trade_preimage_extended_fee_info.dart';
import 'package:komodo_wallet/views/dex/dex_helpers.dart';

import '../utils/test_util.dart';

void testGetTotalFee() {
  test('Total fee positive test', () {
    final List<TradePreimageExtendedFeeInfo> info = [
      TradePreimageExtendedFeeInfo(
        coin: 'KMD',
        amount: '0.00000001',
        amountRational: Rational.parse('0.00000001'),
        paidFromTradingVol: false,
      ),
      TradePreimageExtendedFeeInfo(
        coin: 'BTC',
        amount: '0.00000002',
        amountRational: Rational.parse('0.00000002'),
        paidFromTradingVol: false,
      ),
      TradePreimageExtendedFeeInfo(
        coin: 'LTC',
        amount: '0.00000003',
        amountRational: Rational.parse('0.00000003'),
        paidFromTradingVol: false,
      ),
    ];
    final String nbsp = String.fromCharCode(0x00A0);
    expect(
        getTotalFee(null, (abbr) => setCoin(coinAbbr: abbr, usdPrice: 12.12)),
        '\$0.00');
    expect(
        getTotalFee(info, (abbr) => setCoin(coinAbbr: abbr, usdPrice: 10.00)),
        '\$0.0000006');
    expect(getTotalFee(info, (abbr) => setCoin(coinAbbr: abbr, usdPrice: 0.10)),
        '\$0.000000006');
    expect(getTotalFee(info, (abbr) => setCoin(coinAbbr: abbr, usdPrice: 0.0)),
        '0.00000001${nbsp}KMD +${nbsp}0.00000002${nbsp}BTC +${nbsp}0.00000003${nbsp}LTC');
  });

  test('Total fee edge cases', () {
    final List<TradePreimageExtendedFeeInfo> info = [
      TradePreimageExtendedFeeInfo(
        coin: 'KMD',
        amount: '0.00000000000001',
        amountRational: Rational.parse('0.00000000000001'),
        paidFromTradingVol: false,
      ),
    ];
    final String nbsp = String.fromCharCode(0x00A0);
    // PR: #1218, toStringAmount should fix unexpected results for formatAmt method
    expect(getTotalFee(info, (abbr) => setCoin(coinAbbr: abbr, usdPrice: 1.0)),
        '\$1e-14');
    expect(
        getTotalFee(
            info, (abbr) => setCoin(coinAbbr: abbr, usdPrice: 0.000000001)),
        '\$1.00000000000e-23');
    expect(
        getTotalFee(
            info, (abbr) => setCoin(coinAbbr: abbr, usdPrice: 0.0000000000001)),
        '\$1e-27');
    expect(
        getTotalFee(info, (abbr) => setCoin(coinAbbr: abbr, usdPrice: 1e-30)),
        '\$1.00000000000e-44');
    expect(
        getTotalFee(info, (abbr) => setCoin(coinAbbr: abbr, usdPrice: 1e-60)),
        '\$1e-74');
    expect(getTotalFee(info, (abbr) => setCoin(coinAbbr: abbr, usdPrice: 0)),
        '1e-14${nbsp}KMD');

    final List<TradePreimageExtendedFeeInfo> info2 = [
      TradePreimageExtendedFeeInfo(
        coin: 'BTC',
        amount: '123456789012345678901234567890123456789012345678901234567890',
        amountRational: Rational.parse(
            '123456789012345678901234567890123456789012345678901234567890'),
        paidFromTradingVol: false,
      ),
    ];
    expect(getTotalFee(info2, (abbr) => setCoin(coinAbbr: abbr, usdPrice: 1.0)),
        '\$1.23456789012e+59');
    expect(
        getTotalFee(info2, (abbr) => setCoin(coinAbbr: abbr, usdPrice: 1e-59)),
        '\$1.23');
  });
}
