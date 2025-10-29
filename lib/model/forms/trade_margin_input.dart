import 'package:formz/formz.dart';
import 'package:web_dex/shared/utils/formatters.dart';

enum TradeMarginValidationError {
  /// Input is empty
  empty,

  /// Not a valid number
  invalidNumber,

  /// Number is negative
  lessThanMinimum,

  /// Number is greater than 100
  greaterThanMaximum,
}

class TradeMarginInput extends FormzInput<String, TradeMarginValidationError> {
  final double min;
  final double max;

  const TradeMarginInput.pure({this.min = 0, this.max = 1000})
      : super.pure('3');
  const TradeMarginInput.dirty(String value, {this.min = 0, this.max = 1000})
      : super.dirty(value);

  double get valueAsDouble => tryParseLocaleAwareDouble(value) ?? 0;

  @override
  TradeMarginValidationError? validator(String value) {
    if (value.isEmpty) {
      return TradeMarginValidationError.empty;
    }

    final margin = tryParseLocaleAwareDouble(value);
    if (margin == null) {
      return TradeMarginValidationError.invalidNumber;
    }

    if (margin <= min) {
      return TradeMarginValidationError.lessThanMinimum;
    }

    if (margin > max) {
      return TradeMarginValidationError.greaterThanMaximum;
    }

    return null;
  }
}
