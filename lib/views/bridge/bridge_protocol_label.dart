import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui/komodo_ui.dart' show AssetIcon;
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/model/coin_utils.dart';
import 'package:web_dex/shared/utils/utils.dart';

class BridgeProtocolLabel extends StatelessWidget {
  const BridgeProtocolLabel(this.coin);

  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = coin.type == CoinType.utxo
        ? Theme.of(context).cardColor
        : getProtocolColor(coin.type);
    final Color borderColor = coin.type == CoinType.utxo
        ? getProtocolColor(coin.type)
        : coin.type == CoinType.smartChain
            ? theme.custom.smartchainLabelBorderColor
            : backgroundColor;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1,
          color: borderColor,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(3, 3, 10, 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AssetIcon.ofTicker(coin.abbr, size: 16),
          const SizedBox(width: 6),
          _buildText(backgroundColor),
        ],
      ),
    );
  }

  Widget _buildText(Color protocolColor) {
    return Text(
      coin.type == CoinType.utxo
          ? coin.abbr
          : getCoinTypeName(coin.type).toUpperCase(),
      style: TextStyle(
        color: ThemeData.estimateBrightnessForColor(protocolColor) ==
                Brightness.dark
            ? Colors.white
            : Colors.black,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
    );
  }
}
