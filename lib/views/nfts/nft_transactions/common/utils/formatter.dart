import 'package:easy_localization/easy_localization.dart';
import 'package:komodo_wallet/mm2/rpc/nft_transaction/nft_transactions_response.dart';

class NftTxFormatter {
  static String getFeeValue(NftTransaction tx) {
    final coinAbbr = tx.chain.coinAbbr();
    var f = NumberFormat("##0.00#####", "en_US");
    final double? feeValueNum = double.tryParse(tx.feeDetails?.feeValue ?? '');
    if (feeValueNum == null) return '-';

    return '${f.format(feeValueNum)} $coinAbbr';
  }

  static String getUsdPriceOfFee(NftTransaction tx) {
    final feeValue = tx.feeDetails?.feeValue;
    final coinUsdPrice = tx.feeDetails?.coinUsdPrice;
    if (feeValue == null) return '-';
    if (coinUsdPrice == null) return '-';

    final double? feeValueNum = double.tryParse(feeValue);
    if (feeValueNum == null) return '-';

    return '${NumberFormat.decimalPatternDigits(locale: "en_US", decimalDigits: 7).format(feeValueNum * coinUsdPrice)} USD';
  }
}
