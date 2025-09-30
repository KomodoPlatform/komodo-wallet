import 'package:flutter/material.dart';
import 'package:web_dex/bloc/fiat/models/i_currency.dart';
import 'package:web_dex/model/coin_utils.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/views/fiat/fiat_asset_icon.dart';

class FiatCurrencyListTile extends StatelessWidget {
  const FiatCurrencyListTile({
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
    final coinType = currency.isCrypto
        ? getCoinTypeName(
            (currency as CryptoCurrency).chainType,
            (currency as CryptoCurrency).symbol)
        : '';

    return ListTile(
      leading: FiatAssetIcon(
        currency: currency,
        icon: icon,
        onTap: onTap,
        assetExists: assetExists,
      ),
      title: currency.isFiat
          ? Row(
              children: <Widget>[
                // Use Expanded to let AutoScrollText take all available space
                Expanded(
                  child: AutoScrollText(
                    text:
                        '${currency.name}${coinType.isEmpty ? '' : ' ($coinType)'}',
                  ),
                ),
                // Align the text to the right
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(currency.symbol),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
      onTap: onTap,
    );
  }
}
