import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rational/rational.dart';
import 'package:komodo_wallet/blocs/maker_form_bloc.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/model/orderbook/order.dart';
import 'package:komodo_wallet/views/dex/orderbook/orderbook_view.dart';

class MakerFormOrderbook extends StatelessWidget {
  const MakerFormOrderbook({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final makerFormBloc = RepositoryProvider.of<MakerFormBloc>(context);
    return StreamBuilder<Coin?>(
      initialData: makerFormBloc.sellCoin,
      stream: makerFormBloc.outSellCoin,
      builder: (context, sellCoin) {
        return StreamBuilder<Coin?>(
          initialData: makerFormBloc.buyCoin,
          stream: makerFormBloc.outBuyCoin,
          builder: (context, buyCoin) {
            return StreamBuilder<Rational?>(
              initialData: makerFormBloc.price,
              stream: makerFormBloc.outPrice,
              builder: (context, price) {
                return OrderbookView(
                  base: makerFormBloc.sellCoin,
                  rel: makerFormBloc.buyCoin,
                  myOrder: _getMyOrder(context, price.data),
                  onAskClick: (Order order) => _onAskClick(context, order),
                );
              },
            );
          },
        );
      },
    );
  }

  Order? _getMyOrder(BuildContext context, Rational? price) {
    final makerFormBloc = RepositoryProvider.of<MakerFormBloc>(context);
    final Coin? sellCoin = makerFormBloc.sellCoin;
    final Coin? buyCoin = makerFormBloc.buyCoin;
    final Rational? sellAmount = makerFormBloc.sellAmount;

    if (sellCoin == null) return null;
    if (buyCoin == null) return null;
    if (sellAmount == null || sellAmount == Rational.zero) return null;
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
    final makerFormBloc = RepositoryProvider.of<MakerFormBloc>(context);
    if (makerFormBloc.sellAmount == null) makerFormBloc.setMaxSellAmount();
    makerFormBloc.setPriceValue(order.price.toDouble().toStringAsFixed(8));
  }
}
