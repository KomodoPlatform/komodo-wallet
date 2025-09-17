import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_order_list/market_maker_bot_order_list_repository.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_order_list/trade_pair.dart';
import 'package:web_dex/model/my_orders/my_order.dart';
import 'package:web_dex/model/trading_entities_filter.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/views/market_maker_bot/market_maker_bot_order_list_header.dart';

part 'market_maker_order_list_event.dart';
part 'market_maker_order_list_state.dart';

class MarketMakerOrderListBloc
    extends Bloc<MarketMakerOrderListEvent, MarketMakerOrderListState> {
  MarketMakerOrderListBloc(
    MarketMakerBotOrderListRepository orderListRepository,
  ) : _orderListRepository = orderListRepository,
      super(MarketMakerOrderListState.initial()) {
    on<MarketMakerOrderListRequested>(_onOrderListRequested);
    on<MarketMakerOrderListSortChanged>(_onOrderListSortChanged);
    on<MarketMakerOrderListFilterChanged>(_onOrderListFilterChanged);
  }

  final MarketMakerBotOrderListRepository _orderListRepository;

  void _onOrderListRequested(
    MarketMakerOrderListRequested event,
    Emitter<MarketMakerOrderListState> emit,
  ) async {
    emit(state.copyWith(status: MarketMakerOrderListStatus.loading));

    try {
      List<TradePair> orders = await _orderListRepository.getTradePairs();
      _sortOrders(orders, state.sortData);
      if (state.filterData != null) {
        orders = _applyFilters(state.filterData!, orders);
      }
      emit(
        state.copyWith(
          makerBotOrders: orders,
          status: MarketMakerOrderListStatus.success,
        ),
      );

      return await emit.forEach(
        Stream.periodic(
          event.updateInterval,
        ).asyncMap((_) => _orderListRepository.getTradePairs()),
        onData: (orders) {
          _sortOrders(orders, state.sortData);
          if (state.filterData != null) {
            orders = _applyFilters(state.filterData!, orders);
          }
          return state.copyWith(
            makerBotOrders: orders,
            status: MarketMakerOrderListStatus.success,
          );
        },
      );
    } catch (e, s) {
      log(
        'Failed to load market maker orders: $e',
        trace: s,
        isError: true,
        path: 'MarketMakerOrderListBloc',
      );
      emit(state.copyWith(status: MarketMakerOrderListStatus.failure));
    }
  }

  void _onOrderListSortChanged(
    MarketMakerOrderListSortChanged event,
    Emitter<MarketMakerOrderListState> emit,
  ) {
    List<TradePair> sortedOrders = state.makerBotOrders;
    final sortData = event.sortData;

    _sortOrders(sortedOrders, sortData);
    if (state.filterData != null) {
      sortedOrders = _applyFilters(state.filterData!, sortedOrders);
    }

    emit(state.copyWith(makerBotOrders: sortedOrders, sortData: sortData));
  }

  void _onOrderListFilterChanged(
    MarketMakerOrderListFilterChanged event,
    Emitter<MarketMakerOrderListState> emit,
  ) {
    List<TradePair> filteredOrders = state.makerBotOrders;
    final filterData = event.filterData;

    _sortOrders(filteredOrders, state.sortData);
    if (filterData != null) {
      filteredOrders = _applyFilters(filterData, filteredOrders);
    }

    emit(
      state.copyWith(makerBotOrders: filteredOrders, filterData: filterData),
    );
  }

  void _sortOrders(
    List<TradePair> sortedOrders,
    SortData<MarketMakerBotOrderListType> sortData,
  ) {
    // Retrieve the sorting function based on the sort type.
    var sortingFunction = sortFunctions[sortData.sortType];
    if (sortingFunction != null) {
      sortedOrders.sort((a, b) {
        // Apply the sorting function.
        var result = sortingFunction(a, b);
        // Reverse the result if sortDirection is descending.
        return sortData.sortDirection == SortDirection.decrease
            ? -result
            : result;
      });
    }
  }
}

// Define a map that associates each sort type with a sorting function.
final sortFunctions =
    <MarketMakerBotOrderListType, int Function(TradePair, TradePair)>{
      MarketMakerBotOrderListType.date: (a, b) =>
          a.order?.createdAt.compareTo(b.order?.createdAt ?? 0) ?? 0,
      MarketMakerBotOrderListType.margin: (a, b) =>
          double.tryParse(
            a.config.spread,
          )?.compareTo(double.tryParse(b.config.spread) ?? 0) ??
          0,
      MarketMakerBotOrderListType.receive: (a, b) =>
          a.config.relCoinId.compareTo(b.config.relCoinId),
      MarketMakerBotOrderListType.send: (a, b) =>
          a.config.baseCoinId.compareTo(b.config.baseCoinId),
      MarketMakerBotOrderListType.updateInterval: (a, b) =>
          a.config.priceElapsedValidity?.compareTo(
            b.config.priceElapsedValidity ?? 0,
          ) ??
          0,
      MarketMakerBotOrderListType.price: (a, b) =>
          (a.order?.price ?? 0).compareTo(b.order?.price ?? 0),
    };

List<TradePair> _applyFilters(
  TradingEntitiesFilter filters,
  List<TradePair> orders,
) {
  return orders.where((order) {
    final String? sellCoin = filters.sellCoin;
    final String? buyCoin = filters.buyCoin;
    final int? startDate = filters.startDate?.millisecondsSinceEpoch;
    final int? endDate = filters.endDate?.millisecondsSinceEpoch;
    final List<TradeSide>? shownSides = filters.shownSides;

    if (sellCoin != null && order.config.baseCoinId != sellCoin) return false;
    if (buyCoin != null && order.config.relCoinId != buyCoin) return false;

    if (order.order != null) {
      if (startDate != null && order.order!.createdAt < startDate / 1000) {
        return false;
      }
      if (endDate != null &&
          order.order!.createdAt > (endDate + millisecondsIn24H) / 1000) {
        return false;
      }
      if ((shownSides != null && shownSides.isNotEmpty) &&
          !shownSides.contains(order.order!.orderType)) {
        return false;
      }
    }

    return true;
  }).toList();
}
