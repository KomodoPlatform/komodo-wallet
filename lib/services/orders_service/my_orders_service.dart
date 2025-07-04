import 'package:komodo_wallet/mm2/mm2_api/mm2_api.dart';
import 'package:komodo_wallet/mm2/mm2_api/rpc/cancel_order/cancel_order_request.dart';
import 'package:komodo_wallet/mm2/mm2_api/rpc/my_orders/my_orders_response.dart';
import 'package:komodo_wallet/mm2/mm2_api/rpc/order_status/cancellation_reason.dart';
import 'package:komodo_wallet/mm2/mm2_api/rpc/order_status/order_status_response.dart';
import 'package:komodo_wallet/model/my_orders/my_order.dart';
import 'package:komodo_wallet/model/my_orders/taker_order.dart';
import 'package:komodo_wallet/services/mappers/my_orders_mappers.dart';

class MyOrdersService {
  MyOrdersService(this._mm2Api);

  final Mm2Api _mm2Api;

  Future<List<MyOrder>?> getOrders() async {
    final MyOrdersResponse? response = await _mm2Api.getMyOrders();

    if (response == null) {
      return null;
    }

    return mapMyOrdersResponseToOrders(response);
  }

  Future<OrderStatus?> getStatus(String uuid) async {
    try {
      final OrderStatusResponse? response = await _mm2Api.getOrderStatus(uuid);
      if (response == null) {
        return null;
      }
      final dynamic order = response.order;
      if (order is TakerOrder) {
        return OrderStatus(
          takerOrderStatus: TakerOrderStatus(
            order: mapMyOrderResponseTakerOrderToOrder(order, uuid),
            cancellationReason: _getTakerOrderCancellationReason(
                response.cancellationReason ?? ''),
          ),
        );
      } else {
        return OrderStatus(
          makerOrderStatus: MakerOrderStatus(
            order: mapMyOrderResponseMakerOrderToOrder(order, uuid),
            cancellationReason: _getMakerOrderCancellationReason(
                response.cancellationReason ?? ''),
          ),
        );
      }
    } catch (_) {
      return null;
    }
  }

  Future<String?> cancelOrder(String uuid) async {
    final Map<String, dynamic> response =
        await _mm2Api.cancelOrder(CancelOrderRequest(uuid: uuid));
    return response['error'];
  }

  TakerOrderCancellationReason _getTakerOrderCancellationReason(String reason) {
    switch (reason) {
      case 'Cancelled':
        return TakerOrderCancellationReason.cancelled;
      case 'Fulfilled':
        return TakerOrderCancellationReason.fulfilled;
      case 'TimedOut':
        return TakerOrderCancellationReason.timedOut;
      case 'ToMaker':
        return TakerOrderCancellationReason.toMaker;
      default:
        return TakerOrderCancellationReason.none;
    }
  }

  MakerOrderCancellationReason _getMakerOrderCancellationReason(String reason) {
    switch (reason) {
      case 'Cancelled':
        return MakerOrderCancellationReason.cancelled;
      case 'Fulfilled':
        return MakerOrderCancellationReason.fulfilled;
      case 'InsufficientBalance':
        return MakerOrderCancellationReason.insufficientBalance;
      default:
        return MakerOrderCancellationReason.none;
    }
  }
}

class OrderStatus {
  OrderStatus({this.takerOrderStatus, this.makerOrderStatus});
  final TakerOrderStatus? takerOrderStatus;
  final MakerOrderStatus? makerOrderStatus;
}

class TakerOrderStatus {
  TakerOrderStatus({required this.order, required this.cancellationReason});
  final TakerOrderCancellationReason cancellationReason;
  final MyOrder order;
}

class MakerOrderStatus {
  MakerOrderStatus({required this.order, required this.cancellationReason});
  final MakerOrderCancellationReason cancellationReason;
  final MyOrder order;
}
