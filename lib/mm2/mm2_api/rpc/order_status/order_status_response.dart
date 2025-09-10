import 'package:web_dex/model/my_orders/maker_order.dart';
import 'package:web_dex/model/my_orders/my_order.dart';
import 'package:web_dex/model/my_orders/taker_order.dart';

class OrderStatusResponse {
  OrderStatusResponse({
    required this.type,
    required this.order,
    required this.cancellationReason,
  });

  factory OrderStatusResponse.fromJson(Map<dynamic, dynamic> json) {
    final TradeSide type = json['type'] == 'Taker'
        ? TradeSide.taker
        : TradeSide.maker;
    return OrderStatusResponse(
      type: type,
      order: type == TradeSide.taker
          ? TakerOrder.fromJson(json['order'])
          : MakerOrder.fromJson(json['order']),
      cancellationReason: json['cancellation_reason'],
    );
  }

  final TradeSide type;
  final dynamic order; // TakerOrder or MakerOrder
  final String? cancellationReason;
}
