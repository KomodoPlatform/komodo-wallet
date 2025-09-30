import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/bloc/fiat/models/i_currency.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item.dart' show CoinItem;
import 'package:web_dex/shared/widgets/coin_item/coin_item_size.dart';
import 'package:web_dex/views/fiat/fiat_icon.dart';

class FiatAssetIcon extends StatelessWidget {
  const FiatAssetIcon({
    required this.currency,
    required this.icon,
    required this.onTap,
    required this.assetExists,
    super.key,
  });

  final ICurrency currency;
  final Widget icon;
  final VoidCallback onTap;
  final bool? assetExists;

  @override
  Widget build(BuildContext context) {
    if (currency.isFiat) {
      return FiatIcon(symbol: currency.getAbbr());
    }

    final sdk = RepositoryProvider.of<KomodoDefiSdk>(context);
    final asset = sdk.getSdkAsset(currency.getAbbr());
    return CoinItem(coin: asset.toCoin(), size: CoinItemSize.large);
  }
}
