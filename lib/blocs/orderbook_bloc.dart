import 'dart:async';

import 'package:komodo_defi_rpc_methods/komodo_defi_rpc_methods.dart'
    show GeneralErrorResponse, OrderbookResponse;
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/blocs/bloc_base.dart';
import 'package:web_dex/shared/utils/utils.dart';

class OrderbookBloc implements BlocBase {
  OrderbookBloc({required KomodoDefiSdk sdk}) {
    _sdk = sdk;

    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) async => await _updateOrderbooks(),
    );
  }

  late KomodoDefiSdk _sdk;
  Timer? _timer;

  // keys are 'base/rel' Strings
  final Map<String, OrderbookSubscription> _subscriptions = {};

  @override
  void dispose() {
    _timer?.cancel();
    _subscriptions.forEach((pair, subs) => subs.controller.close());
  }

  OrderbookResult? getInitialData(String base, String rel) {
    final String pair = '$base/$rel';
    final OrderbookSubscription? subscription = _subscriptions[pair];

    return subscription?.initialData;
  }

  Stream<OrderbookResult?> getOrderbookStream(String base, String rel) {
    final String pair = '$base/$rel';
    final OrderbookSubscription? subscription = _subscriptions[pair];

    if (subscription != null) {
      return subscription.stream;
    } else {
      final controller = StreamController<OrderbookResult?>.broadcast();
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
    final List<String> pairs = List.of(_subscriptions.keys);

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

    try {
      final OrderbookResponse response = await _sdk.client.rpc.orderbook
          .orderbook(base: coins[0], rel: coins[1]);

      final result = OrderbookResult(response: response);
      subscription.initialData = result;
      subscription.sink.add(result);
    } on GeneralErrorResponse catch (error) {
      final message = error.error ?? error.toString();
      log(
        'Orderbook request failed for pair $pair: $message',
        path: 'OrderbookBloc._fetchOrderbook',
        isError: true,
      ).ignore();
      final result = OrderbookResult(error: message);
      subscription.initialData = result;
      subscription.sink.add(result);
    } catch (e, s) {
      log(
        'Unexpected orderbook error for pair $pair: $e',
        path: 'OrderbookBloc._fetchOrderbook',
        trace: s,
        isError: true,
      ).ignore();
      final result = OrderbookResult(error: e.toString());
      subscription.initialData = result;
      subscription.sink.add(result);
    }
  }
}

class OrderbookSubscription {
  OrderbookSubscription({
    required this.initialData,
    required this.controller,
    required this.sink,
    required this.stream,
  });

  OrderbookResult? initialData;
  final StreamController<OrderbookResult?> controller;
  final Sink<OrderbookResult?> sink;
  final Stream<OrderbookResult?> stream;
}

class OrderbookResult {
  const OrderbookResult({this.response, this.error});

  final OrderbookResponse? response;
  final String? error;

  bool get hasError => error != null;
}
