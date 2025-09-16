import 'package:web_dex/mm2/mm2_api/rpc/my_orders/my_orders_response.dart';
import 'package:web_dex/model/my_orders/maker_order.dart';
import 'package:web_dex/model/my_orders/my_order.dart';
import 'package:web_dex/model/my_orders/taker_order.dart';

MyOrder mapMyOrderResponseTakerOrderToOrder(TakerOrder order, String uuid) =>
    MyOrder(
      cancelable: order.cancellable,
      base: order.request.base,
      rel: order.request.rel,
      orderType: TradeSide.taker,
      createdAt: order.createdAt ~/ 1000,
      baseAmount: order.request.baseAmount,
      relAmount: order.request.relAmount,
      uuid: uuid,
    );

MyOrder mapMyOrderResponseMakerOrderToOrder(MakerOrder order, String uuid) =>
    MyOrder(
      cancelable: order.cancellable,
      baseAmount: order.maxBaseVol,
      baseAmountAvailable: order.availableAmount,
      minVolume: double.tryParse(order.minBaseVol),
      base: order.base,
      rel: order.rel,
      orderType: TradeSide.maker,
      startedSwaps: order.startedSwaps,
      createdAt: order.createdAt ~/ 1000,
      relAmount: order.price * order.maxBaseVol,
      relAmountAvailable: order.price * order.availableAmount,
      uuid: uuid,
    );

List<MyOrder> mapMyOrdersResponseToOrders(MyOrdersResponse myOrders) {
  final List<MyOrder> takerOrders = myOrders.result.takerOrders.entries
      .map<MyOrder>((entry) =>
          mapMyOrderResponseTakerOrderToOrder(entry.value, entry.key))
      .toList();

  final List<MyOrder> makerOrders = myOrders.result.makerOrders.entries
      .map<MyOrder>((MapEntry<String, MakerOrder> entry) =>
          mapMyOrderResponseMakerOrderToOrder(entry.value, entry.key))
      .toList();

  return [...takerOrders, ...makerOrders];
}
