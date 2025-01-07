import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/bloc/dex_tab_bar/dex_tab_bar_bloc.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_bot/market_maker_bot_bloc.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_trade_form/market_maker_trade_form_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/orderbook/order.dart';
import 'package:web_dex/views/dex/orderbook/orderbook_view.dart';
import 'package:web_dex/views/market_maker_bot/market_maker_bot_confirmation_form.dart';
import 'package:web_dex/views/market_maker_bot/market_maker_bot_form_content.dart';

class MarketMakerBotForm extends StatelessWidget {
  const MarketMakerBotForm();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MarketMakerTradeFormBloc, MarketMakerTradeFormState,
        MarketMakerTradeFormStage>(
      selector: (state) => state.stage,
      builder: (context, formStage) {
        if (formStage == MarketMakerTradeFormStage.confirmationRequired) {
          return MarketMakerBotConfirmationForm(
            onCreateOrder: () => _onCreateOrderPressed(context),
            onCancel: () {
              context
                  .read<MarketMakerTradeFormBloc>()
                  .add(const MarketMakerConfirmationPreviewCancelRequested());
            },
          );
        }

        return isMobile
            ? const _MakerFormMobileLayout()
            : const _MakerFormDesktopLayout();
      },
    );
  }

  void _onCreateOrderPressed(BuildContext context) {
    final marketMakerTradeFormBloc = context.read<MarketMakerTradeFormBloc>();
    final tradePair = marketMakerTradeFormBloc.state.toTradePairConfig();

    context
        .read<MarketMakerBotBloc>()
        .add(MarketMakerBotOrderUpdateRequested(tradePair));

    context.read<DexTabBarBloc>().add(const TabChanged(2));

    marketMakerTradeFormBloc.add(const MarketMakerTradeFormClearRequested());
  }
}

class _MakerFormDesktopLayout extends StatelessWidget {
  const _MakerFormDesktopLayout();

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // We want to place form in the middle of the screen,
        // and orderbook, when shown, should be on the right side
        // (leaving the form in the middle)
        const Expanded(flex: 3, child: SizedBox.shrink()),
        Flexible(
          flex: 6,
          child: DexScrollbar(
            scrollController: scrollController,
            isMobile: isMobile,
            child: SingleChildScrollView(
              key: const Key('maker-form-layout-scroll'),
              controller: scrollController,
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: theme.custom.dexFormWidth),
                child: BlocBuilder<CoinsBloc, CoinsState>(
                  builder: (context, state) {
                    final coins = state.walletCoins.values
                        .where(
                          (e) => e.usdPrice != null && e.usdPrice!.price > 0,
                        )
                        .cast<Coin>()
                        .toList();
                    return MarketMakerBotFormContent(coins: coins);
                  },
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: SingleChildScrollView(
              controller: ScrollController(),
              child: const MarketMakerBotOrderbook(),
            ),
          ),
        ),
      ],
    );
  }
}

class _MakerFormMobileLayout extends StatelessWidget {
  const _MakerFormMobileLayout();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('maker-form-layout-scroll'),
      controller: ScrollController(),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: theme.custom.dexFormWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlocBuilder<CoinsBloc, CoinsState>(
              builder: (context, state) {
                final coins = state.walletCoins.values
                    .where(
                      (e) => e.usdPrice != null && e.usdPrice!.price > 0,
                    )
                    .cast<Coin>()
                    .toList();
                return MarketMakerBotFormContent(coins: coins);
              },
            ),
            const SizedBox(height: 22),
            const MarketMakerBotOrderbook(),
          ],
        ),
      ),
    );
  }
}

class MarketMakerBotOrderbook extends StatelessWidget {
  const MarketMakerBotOrderbook({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketMakerTradeFormBloc, MarketMakerTradeFormState>(
      builder: (context, state) => OrderbookView(
        base: state.sellCoin.value,
        rel: state.buyCoin.value,
        myOrder: _getMyOrder(context, Rational.zero),
        onAskClick: (order) => _onAskClick(context, order),
      ),
    );
  }
}

Order? _getMyOrder(BuildContext context, Rational? price) {
  final state = context.read<MarketMakerTradeFormBloc>().state;
  final Coin? sellCoin = state.sellCoin.value;
  final Coin? buyCoin = state.buyCoin.value;
  final Rational sellAmount =
      Rational.zero; //Rational.parse(state.sellAmount.value);

  if (sellCoin == null) return null;
  if (buyCoin == null) return null;
  if (sellAmount == Rational.zero) return null;
  if (price == null || price == Rational.zero) return null;

  return Order(
    base: sellCoin.abbr,
    rel: buyCoin.abbr,
    maxVolume: sellAmount,
    price: price,
    direction: OrderDirection.ask,
    uuid: orderPreviewUuid,
  );
}

void _onAskClick(BuildContext context, Order order) {
  context
      .read<MarketMakerTradeFormBloc>()
      .add(MarketMakerTradeFormAskOrderbookSelected(order));
}
