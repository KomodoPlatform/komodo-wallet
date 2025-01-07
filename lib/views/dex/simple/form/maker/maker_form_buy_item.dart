import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/blocs/maker_form_bloc.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/views/dex/simple/form/maker/maker_form_buy_switcher.dart';
import 'package:web_dex/views/dex/simple/form/taker/coin_item/trade_controller.dart';

class MakerFormBuyItem extends StatefulWidget {
  const MakerFormBuyItem({
    Key? key,
  }) : super(key: key);
  @override
  State<MakerFormBuyItem> createState() => _MakerFormBuyItemState();
}

class _MakerFormBuyItemState extends State<MakerFormBuyItem> {
  @override
  Widget build(BuildContext context) {
    final makerFormBloc = RepositoryProvider.of<MakerFormBloc>(context);
    return StreamBuilder<Coin?>(
        initialData: makerFormBloc.buyCoin,
        stream: makerFormBloc.outBuyCoin,
        builder: (context, coinSnapshot) {
          final Coin? coin = coinSnapshot.data;

          return Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 14),
              child: StreamBuilder<bool>(
                  initialData: makerFormBloc.showBuyCoinSelect,
                  stream: makerFormBloc.outShowBuyCoinSelect,
                  builder: (context, isOpenSnapshot) {
                    final bool isOpen = isOpenSnapshot.data == true;

                    return MakerFormBuySwitcher(
                      controller: TradeCoinController(
                          coin: coin,
                          onTap: () =>
                              makerFormBloc.showBuyCoinSelect = !isOpen,
                          isOpened: isOpen,
                          isEnabled: coin != null),
                    );
                  }));
        });
  }
}
