import 'package:formz/formz.dart';

/// Validation errors for the fiat amount form field.
enum FiatAmountValidationError {
  /// Input is empty
  empty,

  /// Input is not a valid decimal number
  invalid,

  /// Input is below the specified minimum amount
  belowMinimum,

  /// Input exceeds the specified maximum amount
  aboveMaximum,
}

/// Formz input for a fiat currency amount.
class FiatAmountInput extends FormzInput<String, FiatAmountValidationError> {
  const FiatAmountInput.pure({this.minValue = 0, this.maxValue})
      : super.pure('');
  const FiatAmountInput.dirty(super.value, {this.minValue = 0, this.maxValue})
      : super.dirty();

  final double? minValue;
  final double? maxValue;

  double? get valueAsDouble => double.tryParse(value);

  @override
  FiatAmountValidationError? validator(String value) {
    if (value.isEmpty) {
      return FiatAmountValidationError.empty;
    }

    final amount = double.tryParse(value.replaceAll(',', ''));

    if (amount == null) {
      return FiatAmountValidationError.invalid;
    }

    if (minValue != null && amount < minValue!) {
      return FiatAmountValidationError.belowMinimum;
    }

    if (maxValue != null && amount > maxValue!) {
      return FiatAmountValidationError.aboveMaximum;
    }

    return null;
  }
}
