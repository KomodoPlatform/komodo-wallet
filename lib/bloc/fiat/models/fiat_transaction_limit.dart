import 'package:equatable/equatable.dart';
import 'package:decimal/decimal.dart';

class FiatTransactionLimit extends Equatable {
  const FiatTransactionLimit({
    required this.min,
    required this.max,
    required this.fiatCode,
    required this.weekly,
  });

  factory FiatTransactionLimit.fromJson(Map<String, dynamic> json) {
    return FiatTransactionLimit(
      min: Decimal.tryParse(json['min'] as String? ?? '') ?? Decimal.zero,
      max: Decimal.tryParse(json['max'] as String? ?? '') ?? Decimal.zero,
      weekly: Decimal.tryParse(json['weekly'] as String? ?? '') ?? Decimal.zero,
      fiatCode: json['fiat_code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
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
