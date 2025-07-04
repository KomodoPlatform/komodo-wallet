import 'package:flutter/material.dart';
import 'package:komodo_wallet/bloc/fiat/models/i_currency.dart';
import 'package:komodo_wallet/shared/widgets/coin_icon.dart';
import 'package:komodo_wallet/views/fiat/fiat_currency_list_tile.dart';
import 'package:komodo_wallet/views/fiat/fiat_select_button.dart';

class FiatCurrencyItem extends StatelessWidget {
  const FiatCurrencyItem({
    required this.foregroundColor,
    required this.disabled,
    required this.currency,
    required this.icon,
    required this.onTap,
    required this.isListTile,
    super.key,
  });

  final Color foregroundColor;
  final bool disabled;
  final ICurrency currency;
  final Widget icon;
  final VoidCallback onTap;
  final bool isListTile;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: currency.isFiat
          ? Future.value(true)
          : checkIfAssetExists(currency.symbol),
      builder: (context, snapshot) {
        final assetExists = snapshot.connectionState == ConnectionState.done
            ? snapshot.data ?? false
            : null;
        return isListTile
            ? FiatCurrencyListTile(
                currency: currency,
                icon: icon,
                onTap: onTap,
                assetExists: assetExists,
              )
            : FiatSelectButton(
                context: context,
                foregroundColor: foregroundColor,
                enabled: !disabled,
                currency: currency,
                icon: icon,
                onTap: onTap,
                assetExists: assetExists,
              );
      },
    );
  }
}
