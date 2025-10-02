import 'dart:async';

import 'package:komodo_defi_rpc_methods/komodo_defi_rpc_methods.dart'
    show OrderbookResponse;
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/blocs/bloc_base.dart';
import 'package:web_dex/model/coin.dart';
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
  Set<String> _cachedActiveTickers = <String>{};
  DateTime? _lastActiveTickersFetch;
  Future<Set<String>>? _activeTickersRequest;

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

    String? missingCoin;
    try {
      missingCoin = await _missingActivatedCoin(coins);
    } catch (e, s) {
      log(
        'Failed to determine activation status for $pair: $e',
        path: 'OrderbookBloc._fetchOrderbook',
        trace: s,
        isError: true,
      ).ignore();
    }

    if (missingCoin != null) {
      final formattedCoin = Coin.normalizeAbbr(missingCoin);
      final result = OrderbookResult(error: '$formattedCoin is not activated');
      subscription.initialData = result;
      subscription.sink.add(result);
      return;
    }

    try {
      final OrderbookResponse response = await _sdk.client.rpc.orderbook
          .orderbook(base: coins[0], rel: coins[1]);

      final result = OrderbookResult(response: response);
      subscription.initialData = result;
      subscription.sink.add(result);
    } catch (e, s) {
      log(
        // Exception message can contain RPC pass, so avoid displaying it and logging it
        'Unexpected orderbook error for pair $pair',
        path: 'OrderbookBloc._fetchOrderbook',
        trace: s,
        isError: true,
      ).ignore();
      final result = OrderbookResult(error: 'Unexpected error for pair $pair');
      subscription.initialData = result;
      subscription.sink.add(result);
    }
  }

  Future<String?> _missingActivatedCoin(List<String> tickers) async {
    if (!await _sdk.auth.isSignedIn()) {
      return null;
    }

    final Set<String> activeTickers = await _getActiveTickers();

    for (final ticker in tickers) {
      if (!activeTickers.contains(ticker)) {
        return ticker;
      }
    }

    return null;
  }

  Future<Set<String>> _getActiveTickers() async {
    final DateTime now = DateTime.now();
    if (_lastActiveTickersFetch != null &&
        now.difference(_lastActiveTickersFetch!) < const Duration(seconds: 2)) {
      return _cachedActiveTickers;
    }

    _activeTickersRequest ??= _sdk.assets
        .getActivatedAssets()
        .then((List<Asset> assets) {
          _cachedActiveTickers = assets.map((asset) => asset.id.id).toSet();
          _lastActiveTickersFetch = DateTime.now();
          _activeTickersRequest = null;
          return _cachedActiveTickers;
        })
        .catchError((error) {
          _activeTickersRequest = null;
          throw error;
        });

    return _activeTickersRequest!;
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
