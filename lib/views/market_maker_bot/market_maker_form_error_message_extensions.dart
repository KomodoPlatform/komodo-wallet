// extension to allow for separation of BLoC and UI concerns
// Localisation should be handled in the UI layer
import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_trade_form/market_maker_trade_form_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/forms/coin_select_input.dart';
import 'package:web_dex/model/forms/coin_trade_amount_input.dart';
import 'package:web_dex/model/forms/trade_margin_input.dart';

extension TradeMarginValidationErrorText on TradeMarginValidationError {
  String? text({double minVAlue = 0, double maxValue = 100}) {
    switch (this) {
      case TradeMarginValidationError.empty:
        return LocaleKeys.postitiveNumberRequired.tr();
      case TradeMarginValidationError.lessThanMinimum:
      case TradeMarginValidationError.invalidNumber:
        return LocaleKeys.postitiveNumberRequired.tr();
      case TradeMarginValidationError.greaterThanMaximum:
        return LocaleKeys.mustBeLessThan.tr(args: [maxValue.toString()]);
    }
  }
}

extension CoinSelectValidationErrorText on CoinSelectValidationError {
  String? text(Coin? coin) {
    switch (this) {
      case CoinSelectValidationError.inactive:
        return LocaleKeys.postitiveNumberRequired.tr();
      case CoinSelectValidationError.insufficientBalance:
        return LocaleKeys.dexInsufficientFundsError
            .tr(args: [coin?.balance.toString() ?? '0', coin?.abbr ?? '']);
      case CoinSelectValidationError.insufficientGasBalance:
        return LocaleKeys.withdrawNotEnoughBalanceForGasError
            .tr(args: [coin?.abbr ?? '']);
      case CoinSelectValidationError.parentSuspended:
        return LocaleKeys.withdrawNoParentCoinError
            .tr(args: [coin?.abbr ?? '']);
      default:
        return null;
    }
  }
}

extension AmountValidationErrorText on AmountValidationError {
  String? text(Coin? coin) {
    switch (this) {
      case AmountValidationError.empty:
        return LocaleKeys.mmBotTradeVolumeRequired.tr();
      case AmountValidationError.invalid:
        return LocaleKeys.postitiveNumberRequired.tr();
      case AmountValidationError.moreThanMaximum:
        return LocaleKeys.dexInsufficientFundsError
            .tr(args: [coin?.balance.toString() ?? '0', coin?.abbr ?? '']);
      case AmountValidationError.lessThanMinimum:
        return LocaleKeys.mmBotMinimumTradeVolume.tr(args: ["0.00000001"]);
    }
  }
}

extension MarketMakerTradeFormErrorText on MarketMakerTradeFormError {
  String text(Coin? baseCoin, Coin? relCoin) {
    switch (this) {
      case MarketMakerTradeFormError.insufficientBalanceBase:
        return LocaleKeys.dexInsufficientFundsError.tr(
          args: [baseCoin?.balance.toString() ?? '0', baseCoin?.abbr ?? ''],
        );
      case MarketMakerTradeFormError.insufficientBalanceRel:
        return LocaleKeys.withdrawNotEnoughBalanceForGasError
            .tr(args: [relCoin?.abbr ?? '']);
      case MarketMakerTradeFormError.insufficientBalanceRelParent:
        return LocaleKeys.withdrawNotEnoughBalanceForGasError
            .tr(args: [relCoin?.parentCoin?.abbr ?? relCoin?.abbr ?? '']);
      case MarketMakerTradeFormError.insufficientTradeAmount:
        return LocaleKeys.mmBotMinimumTradeVolume.tr(args: ["0.00000001"]);
      default:
        return LocaleKeys.dexErrorMessage.tr();
    }
  }
}
