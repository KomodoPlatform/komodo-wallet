import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/blocs/maker_form_bloc.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/views/dex/common/front_plate.dart';
import 'package:komodo_wallet/views/dex/simple/form/maker/maker_form_sell_header.dart';
import 'package:komodo_wallet/views/dex/simple/form/maker/maker_form_sell_switcher.dart';
import 'package:komodo_wallet/views/dex/simple/form/taker/coin_item/trade_controller.dart';

class MakerFormSellItem extends StatefulWidget {
  const MakerFormSellItem({
    Key? key,
  }) : super(key: key);
  @override
  State<MakerFormSellItem> createState() => _MakerFormSellItemState();
}

class _MakerFormSellItemState extends State<MakerFormSellItem> {
  @override
  Widget build(BuildContext context) {
    final makerFormBloc = RepositoryProvider.of<MakerFormBloc>(context);
    return FrontPlate(
      child: StreamBuilder<Coin?>(
        initialData: makerFormBloc.sellCoin,
        stream: makerFormBloc.outSellCoin,
        builder: (context, coinSnapshot) {
          final Coin? coin = coinSnapshot.data;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StreamBuilder<bool>(
                initialData: makerFormBloc.showSellCoinSelect,
                stream: makerFormBloc.outShowSellCoinSelect,
                builder: (context, isOpenSnapshot) {
                  final bool isOpen = isOpenSnapshot.data == true;

                  return Column(
                    children: [
                      const MakerFormSellHeader(),
                      const SizedBox(height: 16),
                      MakerFormSellSwitcher(
                        controller: TradeCoinController(
                            coin: coin,
                            onTap: () =>
                                makerFormBloc.showSellCoinSelect = !isOpen,
                            isOpened: isOpen,
                            isEnabled: coin != null),
                      ),
                    ],
                  );
                }),
          );
        },
      ),
    );
  }
}
