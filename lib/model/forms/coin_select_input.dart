import 'package:formz/formz.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:get_it/get_it.dart';

/// Validation errors for the coin selection form field.
enum CoinSelectValidationError {
  /// Input is empty
  empty,

  /// The coin has not been activated in the users wallet yet
  inactive,

  /// Selected coin does not have enough available balance
  insufficientBalance,

  /// The parent coin is suspended, so this coin cannot be used.
  /// E.g. If BNB is suspended, then all BEP2 tokens are suspended.
  parentSuspended,

  // The available balance is not enough to cover the gas fee
  insufficientGasBalance,
}

/// Formz input for selecting a coin.
class CoinSelectInput extends FormzInput<Coin?, CoinSelectValidationError> {
  const CoinSelectInput.pure({this.minBalance = 0, this.minGasBalance = 0})
      : super.pure(null);
  const CoinSelectInput.dirty([
    super.value,
    this.minBalance = 0,
    this.minGasBalance = 0,
  ]) : super.dirty();

  final double minBalance;
  final double minGasBalance;

  @override
  CoinSelectValidationError? validator(Coin? value) {
    if (value == null) {
      return CoinSelectValidationError.empty;
    }

    // not applicable, since only enabled coins should be shown /selectable
    // if (!value.isActive) {
    //   return CoinSelectValidationError.inactive;
    // }

    final KomodoDefiSdk sdk = GetIt.I<KomodoDefiSdk>();
    final coinBalance =
        sdk.balances.lastKnown(value.id)?.spendable.toDouble() ?? 0.0;

    if (coinBalance <= minBalance) {
      return CoinSelectValidationError.insufficientBalance;
    }

    final parentCoin = value.parentCoin;
    if (parentCoin != null && parentCoin.isSuspended) {
      return CoinSelectValidationError.parentSuspended;
    }

    if (parentCoin != null) {
      final parentBalance =
          sdk.balances.lastKnown(parentCoin.id)?.spendable.toDouble() ?? 0.0;
      if (parentBalance < minGasBalance) {
        return CoinSelectValidationError.insufficientGasBalance;
      }
    }

    return null;
  }
}
