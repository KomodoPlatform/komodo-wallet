import 'dart:async';

import 'package:web_dex/blocs/bloc_base.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/mm2/mm2_api/rpc/orderbook/orderbook_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/orderbook/orderbook_response.dart';

class OrderbookBloc implements BlocBase {
  OrderbookBloc({required Mm2Api api}) {
    _api = api;

    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) async => await _updateOrderbooks(),
    );
  }

  late Mm2Api _api;
  Timer? _timer;

  // keys are 'base/rel' Strings
  final Map<String, OrderbookSubscription> _subscriptions = {};

  @override
  void dispose() {
    _timer?.cancel();
    _subscriptions.forEach((pair, subs) => subs.controller.close());
  }

  OrderbookResponse? getInitialData(String base, String rel) {
    final String pair = '$base/$rel';
    final OrderbookSubscription? subscription = _subscriptions[pair];

    return subscription?.initialData;
  }

  Stream<OrderbookResponse?> getOrderbookStream(String base, String rel) {
    final String pair = '$base/$rel';
    final OrderbookSubscription? subscription = _subscriptions[pair];

    if (subscription != null) {
      return subscription.stream;
    } else {
      final controller = StreamController<OrderbookResponse?>.broadcast();
      final sink = controller.sink;
      final stream = controller.stream;

      _subscriptions[pair] = OrderbookSubscription(
        initialData: null,
        controller: controller,
        sink: sink,
        stream: stream,
      );

      _fetchOrderbook(pair);
      return _subscriptions[pair]!.stream;
    }
  }

  Future<void> _updateOrderbooks() async {
    final List<String> pairs = List.from(_subscriptions.keys);

    for (String pair in pairs) {
      final OrderbookSubscription? subscription = _subscriptions[pair];
      if (subscription == null) {
        continue;
      }
      if (!subscription.controller.hasListener) {
        continue;
      }

      await _fetchOrderbook(pair);
    }
  }

  Future<void> _fetchOrderbook(String pair) async {
    final OrderbookSubscription? subscription = _subscriptions[pair];
    if (subscription == null) return;

    final List<String> coins = pair.split('/');

    final OrderbookResponse response = await _api.getOrderbook(OrderbookRequest(
      base: coins[0],
      rel: coins[1],
    ));

    subscription.initialData = response;
    subscription.sink.add(response);
  }
}

class OrderbookSubscription {
  OrderbookSubscription({
    required this.initialData,
    required this.controller,
    required this.sink,
    required this.stream,
  });

  OrderbookResponse? initialData;
  final StreamController<OrderbookResponse?> controller;
  final Sink<OrderbookResponse?> sink;
  final Stream<OrderbookResponse?> stream;
}
