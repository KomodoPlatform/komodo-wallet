import 'package:decimal/decimal.dart';
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
  const FiatAmountInput.pure({this.minValue, this.maxValue}) : super.pure('');
  const FiatAmountInput.dirty(super.value, {this.minValue, this.maxValue})
    : super.dirty();

  final Decimal? minValue;
  final Decimal? maxValue;

  /// Returns the value as a Decimal, properly handling different locale formats
  Decimal? get valueAsDecimal => parseLocaleAwareDecimal(value);

  @override
  FiatAmountValidationError? validator(String value) {
    if (value.isEmpty) {
      return FiatAmountValidationError.empty;
    }

    final amount = parseLocaleAwareDecimal(value);

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

/// Normalizes and parses a decimal string value that might use different
/// locale formats
// TODO: refactor into sdk or extension class for Decimal
Decimal? parseLocaleAwareDecimal(String value) {
  if (value.isEmpty) return null;

  // First attempt: standard format with period as decimal separator (123.45)
  // This covers standard format and numbers without thousand separators
  final decimalValue = Decimal.tryParse(value);
  if (decimalValue != null) return decimalValue;

  // Second attempt: US/UK format with commas as thousand separators (1,234.56)
  if (value.contains(',') && value.contains('.')) {
    final normalizedValue = value.replaceAll(',', '');
    final usFormat = Decimal.tryParse(normalizedValue);
    if (usFormat != null) return usFormat;
  }

  // Third attempt: European format (1.234,56) or other edge cases
  // Only try this if there's a comma and either no period or the period
  // appears before the comma
  if (value.contains(',')) {
    final lastCommaIndex = value.lastIndexOf(',');
    final lastPeriodIndex = value.lastIndexOf('.');

    // Check if this looks like a European format number:
    // - Has a comma
    // - Either no period, or all periods appear before the last comma
    // (as thousand separators)
    if (lastPeriodIndex == -1 || lastPeriodIndex < lastCommaIndex) {
      final europeanFormat = value.replaceAll('.', '').replaceAll(',', '.');
      final euFormat = Decimal.tryParse(europeanFormat);
      if (euFormat != null) return euFormat;
    }
  }

  return null;
}
