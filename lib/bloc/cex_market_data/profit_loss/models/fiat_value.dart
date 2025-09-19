// TODO! Move this class to a shared types package.

import 'package:equatable/equatable.dart';
// import 'package:intl/intl.dart';

abstract class EntityWithValue extends Equatable {
  double get value;

  //TODO! NumberFormat? get valueFormatter;

  @override
  List<Object?> get props => [value];
}

class FiatValue extends EntityWithValue {
  FiatValue({
    required this.currency,
    required this.value,
  });

  FiatValue.fromJson(Map<String, dynamic> json)
      : this(
          currency: json['currency'] ?? '',
          value: (json['value'] as num).toDouble(),
        );

  FiatValue.usd(double value) : this(currency: 'USD', value: value);

  final String currency;
  @override
  final double value;

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'value': value,
    };
  }

  void _validateCurrencyPair(FiatValue other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot compare two different currencies');
    }
  }

  operator +(FiatValue other) {
    _validateCurrencyPair(other);

    return FiatValue(currency: currency, value: value + other.value);
  }

  operator -(FiatValue other) {
    _validateCurrencyPair(other);

    return FiatValue(currency: currency, value: value - other.value);
  }

  // Multiply a fiat value by a scalar, return value in the same currency
  operator *(double scalar) {
    return FiatValue(currency: currency, value: value * scalar);
  }

  // Divide a fiat value by a scalar, return value in the same currency
  operator /(double scalar) {
    return FiatValue(currency: currency, value: value / scalar);
  }

  @override
  List<Object?> get props => [currency, value];
}

class CoinValue extends EntityWithValue {
  CoinValue({
    required this.coinId,
    required this.value,
  });

  factory CoinValue.fromJson(Map<String, dynamic> json) {
    return CoinValue(
      coinId: json['coinId'] ?? '',
      value: (json['value'] as num).toDouble(),
    );
  }

  final String coinId;
  @override
  final double value;

  Map<String, dynamic> toJson() {
    return {
      'coinId': coinId,
      'value': value,
    };
  }

  @override
  List<Object?> get props => [coinId, value];
}
