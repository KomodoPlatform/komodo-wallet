import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';

class FiatTransactionFee extends Equatable {
  const FiatTransactionFee({required this.fees});

  factory FiatTransactionFee.fromJson(JsonMap json) {
    final feesJson = json.valueOrNull<List<JsonMap>>('fees') ?? const [];
    final List<FeeDetail> feesList = feesJson
        .map((e) => FeeDetail.fromJson(e))
        .toList();
    return FiatTransactionFee(fees: feesList);
  }

  final List<FeeDetail> fees;

  JsonMap toJson() {
    return {'fees': fees.map((fee) => fee.toJson()).toList()};
  }

  @override
  List<Object?> get props => [fees];
}

class FeeDetail extends Equatable {
  const FeeDetail({required this.amount});

  factory FeeDetail.fromJson(JsonMap json) {
    return FeeDetail(
      amount: json.valueOrNull<Decimal>('amount') ?? Decimal.zero,
    );
  }

  final Decimal amount;

  JsonMap toJson() {
    return {'amount': amount.toString()};
  }

  @override
  List<Object?> get props => [amount];
}
