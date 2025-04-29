import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/utils/formatters.dart';

class CoinFiatChange extends StatefulWidget {
  const CoinFiatChange(
    this.coin, {
    Key? key,
    this.style,
    this.padding,
    this.useDashForCoinWithoutFiat = false,
  }) : super(key: key);

  final Coin coin;
  final bool useDashForCoinWithoutFiat;
  final TextStyle? style;
  final EdgeInsets? padding;

  @override
  State<CoinFiatChange> createState() => _CoinFiatChangeState();
}

class _CoinFiatChangeState extends State<CoinFiatChange> {
  @override
  Widget build(BuildContext context) {
    final double? change24h = widget.coin.usdPrice?.change24h;

    if (change24h == null) {
      return _NonFiat(
        useDashForCoinWithoutFiat: widget.useDashForCoinWithoutFiat,
        padding: widget.padding,
        style: widget.style,
      );
    }

    Color? color;
    if (change24h > 0) {
      color = theme.custom.increaseColor;
    } else if (change24h < 0) {
      color = theme.custom.decreaseColor;
    }

    final TextStyle style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: color,
    ).merge(widget.style);

    return Container(
      padding: widget.padding,
      child: Text(
        '${formatAmt(change24h)}%',
        style: style,
      ),
    );
  }
}

class _NonFiat extends StatelessWidget {
  final bool useDashForCoinWithoutFiat;
  final EdgeInsets? padding;
  final TextStyle? style;

  const _NonFiat(
      {required this.useDashForCoinWithoutFiat, this.padding, this.style});

  @override
  Widget build(BuildContext context) {
    if (useDashForCoinWithoutFiat) return const SizedBox();
    return Container(
      padding: padding,
      child: Text(
        '-',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ).merge(style),
      ),
    );
  }
}
