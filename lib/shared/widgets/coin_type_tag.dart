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
          child: Text(_protocolName,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ))),
    );
  }

  String get _protocolName {
    switch (coin.type) {
      case CoinType.smartChain:
        return 'SMART CHAIN';
      case CoinType.erc20:
        return 'ERC20';
      case CoinType.utxo:
        return 'UTXO';
      case CoinType.bep20:
        return 'BEP20';
      case CoinType.qrc20:
        return 'QRC20';
      case CoinType.ftm20:
        return 'FTM20';
      case CoinType.arb20:
        return 'ARB20';
      case CoinType.etc:
        return 'ETC';
      case CoinType.avx20:
        return 'AVX20';
      case CoinType.hrc20:
        return 'HRC20';
      case CoinType.mvr20:
        return 'MVR20';
      case CoinType.hco20:
        return 'HCO20';
      case CoinType.plg20:
        return 'PLG20';
      case CoinType.sbch:
        return 'SmartBCH';
      case CoinType.ubiq:
        return 'UBIQ';
      case CoinType.krc20:
        return 'KRC20';
      case CoinType.tendermintToken:
        return 'TENDERMINTTOKEN';
      case CoinType.tendermint:
        return 'TENDERMINT';
      case CoinType.slp:
        return 'SLP';
    }
  }
}
