import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

extension SdkBuildExtensions on BuildContext {
  /// Returns the [KomodoDefiSdk] instance from the context.
  ///
  /// This requires the [KomodoDefiSdk] to be provided in the widget tree,
  /// which is already done in the [App] widget.
  KomodoDefiSdk get sdk => read<KomodoDefiSdk>();
}

extension SdkBalances on Asset {
  BalanceInfo? maybeKnownBalance(KomodoDefiSdk sdk) {
    return sdk.balances.lastKnown(id);
  }

  Future<BalanceInfo> getBalance(KomodoDefiSdk sdk) async {
    return sdk.balances.getBalance(id);
  }

  Stream<BalanceInfo> watchBalance(KomodoDefiSdk sdk,
      {bool activateIfNeeded = true}) {
    return sdk.balances.watchBalance(id, activateIfNeeded: activateIfNeeded);
  }
}

extension SdkPrices on Asset {
  /// Gets the current fiat price, updating the cache if successful
  Future<double?> getFiatPrice(
    KomodoDefiSdk sdk, {
    DateTime? priceDate,
    String fiatCurrency = 'usdt',
  }) async {
    return (await sdk.marketData.maybeFiatPrice(
      id,
      priceDate: priceDate,
      fiatCurrency: fiatCurrency,
    ))
        ?.toDouble();
  }

  // /// Gets historical fiat prices for specified dates
  // Future<Map<DateTime, double>> getFiatPriceHistory(
  //   KomodoDefiSdk sdk,
  //   List<DateTime> dates, {
  //   String fiatCurrency = 'usdt',
  // }) async {
  //   return sdk.marketData.fiatPriceHistory(
  //     id,
  //     dates,
  //     fiatCurrency: fiatCurrency,
  //   );
  // }

  /// Watches for price updates and maintains the cache
  Stream<double?> watchFiatPrice(
    KomodoDefiSdk sdk, {
    String fiatCurrency = 'usdt',
  }) async* {
    while (true) {
      final price = await getFiatPrice(sdk, fiatCurrency: fiatCurrency);
      yield price;
      await Future.delayed(const Duration(minutes: 1));
    }
  }
}
