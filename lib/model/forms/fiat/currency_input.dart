import 'package:formz/formz.dart';
import 'package:web_dex/bloc/fiat/models/i_currency.dart';

/// Validation errors for the currency selection form field.
enum CurrencyValidationError {
  /// No currency selected
  empty,

  /// Currency is not valid for the current operation (e.g., unsupported)
  unsupported,
}

/// Formz input for selecting a currency.
class CurrencyInput extends FormzInput<ICurrency?, CurrencyValidationError> {
  const CurrencyInput.pure() : super.pure(null);
  const CurrencyInput.dirty([super.value]) : super.dirty();

  @override
  CurrencyValidationError? validator(ICurrency? value) {
    if (value == null) {
      return CurrencyValidationError.empty;
    }

    // Additional checks can be placed here
    if (!isCurrencySupported(value)) {
      return CurrencyValidationError.unsupported;
    }

    return null;
  }

  bool isCurrencySupported(ICurrency currency) {
    // Implement your logic for determining if a currency is supported.
    // For example, this might check against a list of supported fiat/currencies.
    // Here, we assume a placeholder true value, meaning all are supported.
    return true;
  }
}
