// import 'package:komodo_defi_sdk/komodo_defi_sdk.dart' show KomodoDefiSdk;
// import 'package:rational/rational.dart';
import 'package:test/test.dart';
// import 'package:web_dex/model/trade_preimage_extended_fee_info.dart';
// import 'package:web_dex/views/dex/dex_helpers.dart';

// import '../utils/test_util.dart';

// TODO: revisit or migrate these tests to the SDK package
void testGetTotalFee() {
  test('Total fee positive test', () {
    //   final List<TradePreimageExtendedFeeInfo> info = [
    //     TradePreimageExtendedFeeInfo(
    //       coin: 'KMD',
    //       amount: '0.00000001',
    //       amountRational: Rational.parse('0.00000001'),
    //       paidFromTradingVol: false,
    //     ),
    //     TradePreimageExtendedFeeInfo(
    //       coin: 'BTC',
    //       amount: '0.00000002',
    //       amountRational: Rational.parse('0.00000002'),
    //       paidFromTradingVol: false,
    //     ),
    //     TradePreimageExtendedFeeInfo(
    //       coin: 'LTC',
    //       amount: '0.00000003',
    //       amountRational: Rational.parse('0.00000003'),
    //       paidFromTradingVol: false,
    //     ),
    //   ];
    //   final String nbsp = String.fromCharCode(0x00A0);
    //   expect(
    //     getTotalFee(
    //       null,
    //       (abbr) => setCoin(coinAbbr: abbr, usdPrice: 12.12),
    //       mockSdk,
    //     ),
    //     '\$0.00',
    //   );
    //   expect(
    //     getTotalFee(
    //       info,
    //       (abbr) => setCoin(coinAbbr: abbr, usdPrice: 10.00),
    //       mockSdk,
    //     ),
    //     '\$0.0000006',
    //   );
    //   expect(
    //     getTotalFee(
    //       info,
    //       (abbr) => setCoin(coinAbbr: abbr, usdPrice: 0.10),
    //       mockSdk,
    //     ),
    //     '\$0.000000006',
    //   );
    //   expect(
    //     getTotalFee(
    //       info,
    //       (abbr) => setCoin(coinAbbr: abbr, usdPrice: 0.0),
    //       mockSdk,
    //     ),
    //     '0.00000001${nbsp}KMD +${nbsp}0.00000002${nbsp}BTC +${nbsp}0.00000003${nbsp}LTC',
    //   );
    // });

    // test('Total fee edge cases', () {
    //   final List<TradePreimageExtendedFeeInfo> info = [
    //     TradePreimageExtendedFeeInfo(
    //       coin: 'KMD',
    //       amount: '0.00000000000001',
    //       amountRational: Rational.parse('0.00000000000001'),
    //       paidFromTradingVol: false,
    //     ),
    //   ];
    //   final String nbsp = String.fromCharCode(0x00A0);
    //   // PR: #1218, toStringAmount should fix unexpected results for formatAmt method
    //   expect(
    //     getTotalFee(
    //       info,
    //       (abbr) => setCoin(coinAbbr: abbr, usdPrice: 1.0),
    //       mockSdk,
    //     ),
    //     '\$1e-14',
    //   );
    //   expect(
    //     getTotalFee(
    //       info,
    //       (abbr) => setCoin(coinAbbr: abbr, usdPrice: 0.000000001),
    //       mockSdk,
    //     ),
    //     '\$1.00000000000e-23',
    //   );
    //   expect(
    //     getTotalFee(
    //       info,
    //       (abbr) => setCoin(coinAbbr: abbr, usdPrice: 0.0000000000001),
    //       mockSdk,
    //     ),
    //     '\$1e-27',
    //   );
    //   expect(
    //     getTotalFee(
    //       info,
    //       (abbr) => setCoin(coinAbbr: abbr, usdPrice: 1e-30),
    //       mockSdk,
    //     ),
    //     '\$1.00000000000e-44',
    //   );
    //   expect(
    //     getTotalFee(
    //       info,
    //       (abbr) => setCoin(coinAbbr: abbr, usdPrice: 1e-60),
    //       mockSdk,
    //     ),
    //     '\$1e-74',
    //   );
    //   expect(
    //     getTotalFee(
    //       info,
    //       (abbr) => setCoin(coinAbbr: abbr, usdPrice: 0),
    //       mockSdk,
    //     ),
    //     '1e-14${nbsp}KMD',
    //   );

    //   final List<TradePreimageExtendedFeeInfo> info2 = [
    //     TradePreimageExtendedFeeInfo(
    //       coin: 'BTC',
    //       amount: '123456789012345678901234567890123456789012345678901234567890',
    //       amountRational: Rational.parse(
    //         '123456789012345678901234567890123456789012345678901234567890',
    //       ),
    //       paidFromTradingVol: false,
    //     ),
    //   ];
    //   expect(
    //     getTotalFee(
    //       info2,
    //       (abbr) => setCoin(coinAbbr: abbr, usdPrice: 1.0),
    //       mockSdk,
    //     ),
    //     '\$1.23456789012e+59',
    //   );
    //   expect(
    //     getTotalFee(
    //       info2,
    //       (abbr) => setCoin(coinAbbr: abbr, usdPrice: 1e-59),
    //       mockSdk,
    //     ),
    //     '\$1.23',
    //   );
    // Skipping due to mocking issue with the SDK - requires internal interfaces
    // to be exposed to be mocked properly (e.g. MarketDataManager for the priceIfKnown method)
  }, skip: true);
}

void main() {
  testGetTotalFee();
}
