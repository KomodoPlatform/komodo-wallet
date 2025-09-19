import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

class FiatTransactionFee extends Equatable {
  const FiatTransactionFee({required this.fees});

  factory FiatTransactionFee.fromJson(Map<String, dynamic> json) {
    final feesJson = json['fees'] as List<dynamic>? ?? [];
    final List<FeeDetail> feesList = feesJson
        .map((e) => FeeDetail.fromJson(e as Map<String, dynamic>))
        .toList();
    return FiatTransactionFee(fees: feesList);
  }

  final List<FeeDetail> fees;

  Map<String, dynamic> toJson() {
    return {
      'fees': fees.map((fee) => fee.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [fees];
}

class FeeDetail extends Equatable {
  const FeeDetail({required this.amount});

  factory FeeDetail.fromJson(Map<String, dynamic> json) {
    final amountStr = json['amount']?.toString() ?? '0';
    return FeeDetail(amount: Decimal.parse(amountStr));
  }

  final Decimal amount;

  Map<String, dynamic> toJson() {
    return {
      'amount': amount.toString(),
    };
  }

  @override
  List<Object?> get props => [amount];
}
