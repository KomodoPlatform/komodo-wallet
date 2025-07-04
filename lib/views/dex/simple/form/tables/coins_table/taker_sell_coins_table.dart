import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_bloc.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_event.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_state.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/views/dex/simple/form/tables/coins_table/coins_table.dart';
import 'package:komodo_wallet/views/dex/simple/form/taker/coin_item/taker_form_sell_switcher.dart';
import 'package:komodo_wallet/views/dex/simple/form/taker/coin_item/trade_controller.dart';

class TakerSellCoinsTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TakerBloc, TakerState>(
      buildWhen: (prev, curr) {
        if (prev.showCoinSelector != curr.showCoinSelector) return true;
        if (prev.sellCoin != curr.sellCoin) return true;

        return false;
      },
      builder: (context, state) {
        if (!state.showCoinSelector) return const SizedBox();

        return CoinsTable(
          key: const Key('taker-sell-coins-table'),
          onSelect: (Coin coin) =>
              context.read<TakerBloc>().add(TakerSetSellCoin(coin)),
          head: TakerFormSellSwitcher(
            padding: const EdgeInsets.only(top: 16, bottom: 12),
            controller: TradeCoinController(
              coin: state.sellCoin,
              onTap: () =>
                  context.read<TakerBloc>().add(TakerCoinSelectorClick()),
              isEnabled: false,
              isOpened: true,
            ),
          ),
        );
      },
    );
  }
}
