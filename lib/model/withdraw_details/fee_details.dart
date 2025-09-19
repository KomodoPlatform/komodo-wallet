import 'package:web_dex/shared/utils/utils.dart';

class FeeDetails {
  FeeDetails({
    required this.type,
    required this.coin,
    this.amount,
    this.totalFee,
    this.gasPrice,
    this.gas,
    this.gasLimit,
    this.minerFee,
    this.totalGasFee,
  });
  factory FeeDetails.fromJson(Map<String, dynamic> json) {
    return FeeDetails(
      type: json['type'] ?? '',
      coin: json['coin'] ?? '',
      gas: json['gas'],
      gasLimit: json['gas_limit'],
      minerFee: assertString(json['miner_fee']),
      totalGasFee: assertString(json['total_gas_fee']),
      gasPrice: assertString(json['gas_price']),
      totalFee: assertString(json['total_fee']),
      amount: assertString(json['amount']),
    );
  }

  static FeeDetails empty() => FeeDetails(
        type: '',
        coin: '',
        gas: null,
        gasLimit: null,
        minerFee: null,
        totalGasFee: null,
        gasPrice: null,
        totalFee: null,
        amount: null,
      );

  String type;
  String coin;
  String? amount;
  int? gas;
  String? gasPrice;
  int? gasLimit;
  String? minerFee;
  String? totalGasFee;
  String? totalFee;
  double? _coinUsdPrice;

  String? get feeValue {
    if (type == 'Qrc20') {
      try {
        return '${double.parse(totalGasFee!) + double.parse(minerFee!)}';
      } catch (_) {
        return null;
      }
    }

    return amount ?? totalFee;
  }

  void setCoinUsdPrice(double? value) {
    _coinUsdPrice = value;
  }

  double? get coinUsdPrice => _coinUsdPrice;
}
