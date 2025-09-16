import 'package:web_dex/model/my_orders/maker_order.dart';
import 'package:web_dex/model/my_orders/taker_order.dart';

class MyOrdersResponse {
  MyOrdersResponse({
    required this.result,
  });

  factory MyOrdersResponse.fromJson(Map<String, dynamic> json) =>
      MyOrdersResponse(
        result: MyOrdersResponseResult.fromJson(
          Map<String, dynamic>.from(json['result'] as Map? ?? {}),
        ),
      );

  MyOrdersResponseResult result;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'result': result.toJson(),
      };
}

class MyOrdersResponseResult {
  MyOrdersResponseResult({
    required this.makerOrders,
    required this.takerOrders,
  });

  factory MyOrdersResponseResult.fromJson(Map<String, dynamic> json) =>
      MyOrdersResponseResult(
        makerOrders: Map<dynamic, dynamic>.from(json['maker_orders']).map(
          (dynamic k, dynamic v) =>
              MapEntry<String, MakerOrder>(k, MakerOrder.fromJson(v)),
        ),
        takerOrders: Map<dynamic, dynamic>.from(json['taker_orders']).map(
          (dynamic k, dynamic v) =>
              MapEntry<String, TakerOrder>(k, TakerOrder.fromJson(v)),
        ),
      );

  Map<String, MakerOrder> makerOrders;
  Map<String, TakerOrder> takerOrders;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'maker_orders':
            Map<dynamic, dynamic>.from(makerOrders).map<dynamic, dynamic>(
          (dynamic k, dynamic v) => MapEntry<String, dynamic>(k, v.toJson()),
        ),
        'taker_orders':
            Map<dynamic, dynamic>.from(takerOrders).map<dynamic, dynamic>(
          (dynamic k, dynamic v) => MapEntry<String, dynamic>(k, v.toJson()),
        ),
      };
}
