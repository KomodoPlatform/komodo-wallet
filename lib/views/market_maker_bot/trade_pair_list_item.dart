import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rational/rational.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;
import 'package:web_dex/bloc/market_maker_bot/market_maker_order_list/trade_pair.dart';
import 'package:web_dex/blocs/trading_entities_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/utils/formatters.dart';
import 'package:web_dex/shared/widgets/focusable_widget.dart';
import 'package:web_dex/views/dex/entities_list/common/buy_price_mobile.dart';
import 'package:web_dex/views/dex/entities_list/common/coin_amount_mobile.dart';
import 'package:web_dex/views/dex/entities_list/common/trade_amount_desktop.dart';

class TradePairListItem extends StatelessWidget {
  const TradePairListItem(
    this.pair, {
    required this.isBotRunning,
    super.key,
    this.onTap,
    this.actions = const [],
  });

  final TradePair pair;
  final bool isBotRunning;
  final List<Widget> actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final config = pair.config;
    final order = pair.order;
    final sellCoin = config.baseCoinId;
    final sellAmount = order?.baseAmountAvailable ?? pair.baseCoinAmount;
    final buyCoin = config.relCoinId;
    final buyAmount = order?.relAmountAvailable ?? pair.relCoinAmount;
    final String date = order != null ? getFormattedDate(order.createdAt) : '-';
    final tradingEntitiesBloc = RepositoryProvider.of<TradingEntitiesBloc>(context);
    final double fillProgress = order != null
        ? tradingEntitiesBloc.getProgressFillSwap(pair.order!)
        : 0;
    final showProgressIndicator = pair.order == null && isBotRunning;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        FocusableWidget(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: isMobile
                ? _OrderItemMobile(
                    buyAmount: buyAmount,
                    buyCoin: buyCoin,
                    sellCoin: sellCoin,
                    sellAmount: sellAmount,
                    date: date,
                    fillProgress: fillProgress,
                    actions: actions,
                  )
                : _OrderItemDesktop(
                    buyAmount: buyAmount,
                    buyCoin: buyCoin,
                    sellCoin: sellCoin,
                    sellAmount: sellAmount,
                    margin: '${config.margin.toStringAsFixed(2)}%',
                    updateInterval: '${config.updateInterval.minutes} min',
                    date: date,
                    fillProgress: fillProgress,
                    showProgressIndicator: showProgressIndicator,
                    actions: actions,
                  ),
          ),
        ),
      ],
    );
  }
}

class _OrderItemDesktop extends StatelessWidget {
  const _OrderItemDesktop({
    required this.buyCoin,
    required this.buyAmount,
    required this.sellCoin,
    required this.sellAmount,
    required this.margin,
    required this.updateInterval,
    required this.date,
    required this.fillProgress,
    required this.showProgressIndicator,
    this.actions = const [],
  });
  final String buyCoin;
  final Rational buyAmount;
  final String sellCoin;
  final Rational sellAmount;
  final String margin;
  final String updateInterval;
  final String date;
  final double fillProgress;
  final bool showProgressIndicator;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final tradingEntitiesBloc =
        RepositoryProvider.of<TradingEntitiesBloc>(context);
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          flex: 5,
          child: TradeAmountDesktop(coinAbbr: sellCoin, amount: sellAmount),
        ),
        Expanded(
          flex: 5,
          child: TradeAmountDesktop(coinAbbr: buyCoin, amount: buyAmount),
        ),
        Expanded(
          flex: 3,
          child: Text(
            showProgressIndicator
                ? '-'
                : formatAmt(
                    tradingEntitiesBloc.getPriceFromAmount(
                      sellAmount,
                      buyAmount,
                    ),
                  ),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            margin,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            updateInterval,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            date,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showProgressIndicator)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: actions.isNotEmpty
                      ? TableActionsButtonList(
                          actions: actions,
                        )
                      : const SizedBox(width: 80),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TableActionsButtonList extends StatelessWidget {
  const TableActionsButtonList({
    required this.actions,
  });

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    // use layout builder to dynamically switch to column layout if width is
    // not sufficient
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 120) {
          return Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: actions,
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: actions,
        );
      },
    );
  }
}

class _FillPainter extends CustomPainter {
  _FillPainter({
    required this.context,
    required this.fillProgress,
  });

  final BuildContext context;
  final double fillProgress;

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final theme = Theme.of(context);

    final Paint paint = Paint()
      ..color = Theme.of(context).highlightColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    final Offset center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width / 2, paint);

    final Paint fillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color =
          theme.progressIndicatorTheme.color ?? theme.colorScheme.secondary
      ..strokeWidth = size.width * 1.1 / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width / 4),
      vector_math.radians(0),
      vector_math.radians(fillProgress * 360),
      false,
      fillPaint,
    );
  }
}

class _OrderItemMobile extends StatelessWidget {
  const _OrderItemMobile({
    required this.buyCoin,
    required this.buyAmount,
    required this.sellCoin,
    required this.sellAmount,
    required this.date,
    required this.fillProgress,
    this.actions = const [],
  });

  final String buyCoin;
  final Rational buyAmount;
  final String sellCoin;
  final Rational sellAmount;
  final String date;
  final double fillProgress;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocaleKeys.send.tr(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: CoinAmountMobile(
                      coinAbbr: sellCoin,
                      amount: sellAmount,
                    ),
                  ),
                ],
              ),
            ),
            BuyPriceMobile(
              buyCoin: buyCoin,
              sellAmount: sellAmount,
              buyAmount: buyAmount,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.receive.tr(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: CoinAmountMobile(
                        coinAbbr: buyCoin,
                        amount: buyAmount,
                      ),
                    ),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CustomPaint(
                  painter: _FillPainter(
                    context: context,
                    fillProgress: fillProgress,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Text(
                  LocaleKeys.percentFilled
                      .tr(args: [(fillProgress * 100).toStringAsFixed(0)]),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
