import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/taker_form/taker_bloc.dart';
import 'package:web_dex/bloc/taker_form/taker_event.dart';
import 'package:web_dex/bloc/taker_form/taker_state.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/dex/common/front_plate.dart';
import 'package:web_dex/views/dex/simple/form/common/dex_form_group_header.dart';
import 'package:web_dex/views/dex/simple/form/taker/coin_item/taker_form_buy_switcher.dart';
import 'package:web_dex/views/dex/simple/form/taker/coin_item/trade_controller.dart';

class TakerFormBuyItem extends StatelessWidget {
  const TakerFormBuyItem({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TakerBloc, TakerState>(
      buildWhen: (prev, curr) {
        if (prev.selectedOrder != curr.selectedOrder) return true;
        if (prev.sellCoin != curr.sellCoin) return true;
        if (prev.isBuyCoinActivating != curr.isBuyCoinActivating) return true;

        return false;
      },
      builder: (context, state) {
        final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
        final coin = coinsRepository.getCoin(state.selectedOrder?.coin ?? '');

        final controller = TradeOrderController(
          order: state.selectedOrder,
          coin: coin,
          isEnabled: false,
          isOpened: false,
          onTap: () {
            context.read<TakerBloc>().add(TakerOrderSelectorClick());
          },
        );

        final content = Column(
          children: [
            _BuyHeader(),
            TakerFormBuySwitcher(controller),
          ],
        );

        if (!state.isBuyCoinActivating) {
          return FrontPlate(child: content);
        }

        return FrontPlate(
          child: Stack(
            children: [
              content,
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black12,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BuyHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DexFormGroupHeader(
        title: LocaleKeys.buy.tr(),
      );
}
