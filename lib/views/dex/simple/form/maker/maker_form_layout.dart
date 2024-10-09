import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc_state.dart';
import 'package:web_dex/bloc/dex_tab_bar/dex_tab_bar_bloc.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/views/dex/simple/confirm/maker_order_confirmation.dart';
import 'package:web_dex/views/dex/simple/form/maker/maker_form_buy_coin_table.dart';
import 'package:web_dex/views/dex/simple/form/maker/maker_form_content.dart';
import 'package:web_dex/views/dex/simple/form/maker/maker_form_orderbook.dart';
import 'package:web_dex/views/dex/simple/form/maker/maker_form_sell_coin_table.dart';

class MakerFormLayout extends StatefulWidget {
  const MakerFormLayout();

  @override
  State<MakerFormLayout> createState() => _MakerFormLayoutState();
}

class _MakerFormLayoutState extends State<MakerFormLayout> {
  @override
  void initState() {
    makerFormBloc.setDefaultSellCoin();
    _consumeRouteParameters();

    super.initState();
  }

  void _consumeRouteParameters() {
    if (routingState.dexState.orderType != 'taker') {
      if (routingState.dexState.fromCurrency.isNotEmpty) {
        final Coin? sellCoin =
            coinsBloc.getCoin(routingState.dexState.fromCurrency);

        if (sellCoin != null) {
          makerFormBloc.sellCoin = sellCoin;

          if (routingState.dexState.fromAmount.isNotEmpty) {
            makerFormBloc.setSellAmount(routingState.dexState.fromAmount);
          }
        }
      }

      if (routingState.dexState.toCurrency.isNotEmpty) {
        final Coin? buyCoin =
            coinsBloc.getCoin(routingState.dexState.toCurrency);

        if (buyCoin != null) {
          makerFormBloc.buyCoin = buyCoin;

          if (routingState.dexState.toAmount.isNotEmpty) {
            makerFormBloc.setBuyAmount(routingState.dexState.toAmount);
          }
        }
      }

      routingState.dexState.clearDexParams();
    }
  }

  @override
  Widget build(BuildContext context) {
    final DexTabBarBloc bloc = context.read<DexTabBarBloc>();
    return BlocListener<AuthBloc, AuthBlocState>(
      listener: (context, state) {
        if (state.mode == AuthorizeMode.noLogin) {
          makerFormBloc.showConfirmation = false;
        }
      },
      child: StreamBuilder<bool>(
        initialData: makerFormBloc.showConfirmation,
        stream: makerFormBloc.outShowConfirmation,
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return MakerOrderConfirmation(
              onCreateOrder: () => bloc.add(const TabChanged(2)),
              onCancel: () {
                makerFormBloc.showConfirmation = false;
              },
            );
          }

          return isMobile
              ? const _MakerFormMobileLayout()
              : const _MakerFormDesktopLayout();
        },
      ),
    );
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
                child: const Stack(
                  clipBehavior: Clip.none,
                  children: [
                    MakerFormContent(),
                    MakerFormSellCoinTable(),
                    MakerFormBuyCoinTable(),
                  ],
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
              child: const MakerFormOrderbook(),
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
        child: const Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MakerFormContent(),
                SizedBox(height: 22),
                MakerFormOrderbook(),
              ],
            ),
            MakerFormSellCoinTable(),
            MakerFormBuyCoinTable(),
          ],
        ),
      ),
    );
  }
}
