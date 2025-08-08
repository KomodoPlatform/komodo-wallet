import 'package:equatable/equatable.dart';
import 'package:decimal/decimal.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';

class FiatTransactionLimit extends Equatable {
  const FiatTransactionLimit({
    required this.min,
    required this.max,
    required this.fiatCode,
    required this.weekly,
  });

  factory FiatTransactionLimit.fromJson(JsonMap json) {
    return FiatTransactionLimit(
      min: json.value<Decimal>('min'),
      max: json.value<Decimal>('max'),
      weekly: json.value<Decimal>('weekly'),
      fiatCode: json.valueOrNull<String>('fiat_code') ?? '',
    );
  }

  JsonMap toJson() {
    return {
      'min': min.toString(),
      'max': max.toString(),
      'weekly': weekly.toString(),
      'fiat_code': fiatCode,
    };
  }

  final Decimal min;
  final Decimal max;
  final Decimal weekly;
  final String fiatCode;

  @override
  List<Object?> get props => [min, max, weekly, fiatCode];
}
