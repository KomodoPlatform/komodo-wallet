import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/widgets/coin_icon.dart';

class CoinLogo extends StatelessWidget {
  const CoinLogo({this.coin, this.size});

  final Coin? coin;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final double size = this.size ?? 41;
    final Coin? coin = this.coin;

    if (coin == null) return _CoinLogoPlaceholder(size);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CoinIcon(coin.abbr, size: size),
        if (coin.type != CoinType.utxo && coin.protocolData != null)
          _ProtocolIcon(
            coin: coin,
            logoSize: size,
          ),
      ],
    );
  }
}

class _ProtocolIcon extends StatelessWidget {
  const _ProtocolIcon({
    required this.coin,
    required this.logoSize,
  });

  final Coin coin;
  final double logoSize;

  double get protocolSizeWithBorder => logoSize * 0.45;
  double get protocolBorder => protocolSizeWithBorder * 0.1;
  double get protocolLeftPosition => logoSize * 0.55;
  double get protocolTopPosition => logoSize * 0.55;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: protocolLeftPosition,
      top: protocolTopPosition,
      width: protocolSizeWithBorder,
      height: protocolSizeWithBorder,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 2)
          ],
        ),
        child: Container(
          width: protocolSizeWithBorder - protocolBorder,
          height: protocolSizeWithBorder - protocolBorder,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: CoinIcon(getProtocolIcon(coin),
              size: protocolSizeWithBorder - protocolBorder),
        ),
      ),
    );
  }
}

class _CoinLogoPlaceholder extends StatelessWidget {
  const _CoinLogoPlaceholder(this.logoSize);

  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dexPageColors.emptyPlace,
      ),
    );
  }
}

String getProtocolIcon(Coin coin) {
  switch (coin.type) {
    case CoinType.smartChain:
      return 'kmd';
    case CoinType.erc20:
      return 'eth';
    case CoinType.bep20:
      return 'bnb';
    case CoinType.qrc20:
      return 'qtum';
    case CoinType.ftm20:
      return 'ftm';
    case CoinType.arb20:
      return 'arb';
    case CoinType.etc:
      return 'etc';
    case CoinType.avx20:
      return 'avax';
    case CoinType.mvr20:
      return 'movr';
    case CoinType.hco20:
      return 'ht';
    case CoinType.plg20:
      return 'matic';
    case CoinType.sbch:
      return 'sbch';
    case CoinType.ubiq:
      return 'ubq';
    case CoinType.hrc20:
      return 'one';
    case CoinType.krc20:
      return 'kcs';
    case CoinType.iris:
      return 'iris';
    case CoinType.slp:
      return 'slp';
    case CoinType.utxo:
    case CoinType.cosmos:
      return abbr2Ticker(coin.abbr).toLowerCase();
  }
}
