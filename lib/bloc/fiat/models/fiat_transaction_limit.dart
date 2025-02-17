import 'package:equatable/equatable.dart';

class FiatTransactionLimit extends Equatable {
  const FiatTransactionLimit({
    required this.min,
    required this.max,
    required this.fiatCode,
    required this.weekly,
  });

  factory FiatTransactionLimit.fromJson(Map<String, dynamic> json) {
    double parseDouble(String? value) {
      if (value == null || value.isEmpty) {
        return 0.0;
      }
      return double.tryParse(value) ?? 0.0;
    }

    return FiatTransactionLimit(
      min: parseDouble(json['min'] as String?),
      max: parseDouble(json['max'] as String?),
      weekly: parseDouble(json['weekly'] as String?),
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

  final double min;
  final double max;
  final double weekly;
  final String fiatCode;

  @override
  List<Object?> get props => [min, max, weekly, fiatCode];
}
