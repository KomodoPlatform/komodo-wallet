import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/shared/utils/utils.dart';

// todo @dmitrii: Looks similar to BlockchainBadge
// Make common
class CoinTypeTag extends StatelessWidget {
  const CoinTypeTag(this.coin);

  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final Color protocolColor = getProtocolColor(coin.type);
    return Container(
      width: 124,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: getProtocolColor(coin.type),
        border: Border.all(
          color: coin.type == CoinType.smartChain
              ? theme.custom.smartchainLabelBorderColor
              : protocolColor,
        ),
      ),
      child: Center(
        child: Text(
          _resolvedProtocolName,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String get _resolvedProtocolName {
    // Use the same naming that the business logic layer uses everywhere else
    // and ensure parents show as 'Native'.
    final upper = coin.typeName.toUpperCase();
    if (upper == 'SMART CHAIN') return 'SMART CHAIN';
    // Keep short forms without hyphen for small badge
    return upper.replaceAll('-', '');
  }
}
