import 'dart:async';

import 'package:web_dex/blocs/orderbook_bloc.dart';
import 'package:web_dex/mm2/mm2_api/rpc/orderbook/orderbook_response.dart';
import 'package:web_dex/model/coin.dart';

class OrderbookModel {
  OrderbookModel({
    required Coin? base,
    required Coin? rel,
    required this.orderBookRepository,
  }) {
    _base = base;
    _rel = rel;
    _updateListener();
  }

  final OrderbookBloc orderBookRepository;

  Coin? _base;
  Coin? get base => _base;
  set base(Coin? value) {
    _base = value;
    _updateListener();
  }

  Coin? _rel;
  Coin? get rel => _rel;
  set rel(Coin? value) {
    _rel = value;
    _updateListener();
  }

  StreamSubscription? _orderbookListener;

  OrderbookResponse? _response;
  final _responseCtrl = StreamController<OrderbookResponse?>.broadcast();
  Sink<OrderbookResponse?> get _inResponse => _responseCtrl.sink;
  Stream<OrderbookResponse?> get outResponse => _responseCtrl.stream;
  OrderbookResponse? get response => _response;
  set response(OrderbookResponse? value) {
    _response = value;
    _inResponse.add(_response);
  }

  bool get isComplete => base?.abbr != null && rel?.abbr != null;

  void dispose() {
    _orderbookListener?.cancel();
    _responseCtrl.close();
  }

  void reload() {
    _updateListener();
  }

  void _updateListener() {
    _orderbookListener?.cancel();
    response = null;
    if (base == null || rel == null) return;

    final stream =
        orderBookRepository.getOrderbookStream(base!.abbr, rel!.abbr);
    _orderbookListener = stream.listen((resp) => response = resp);
  }

  @override
  String toString() {
    return 'OrderbookModel(base:${base?.abbr}, rel:${rel?.abbr} isComplete:$isComplete);';
  }
}
