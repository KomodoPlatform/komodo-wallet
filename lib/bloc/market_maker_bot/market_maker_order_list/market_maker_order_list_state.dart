part of 'market_maker_order_list_bloc.dart';

enum MarketMakerOrderListStatus { initial, loading, success, failure }

class MarketMakerOrderListState extends Equatable {
  /// List of maker orders managed by the market maker bot.
  /// The list is sorted by the selected sort type.
  final List<TradePair> makerBotOrders;

  /// Status of the market maker order list.
  final MarketMakerOrderListStatus status;

  /// Sorting data for the market maker order list.
  final SortData<MarketMakerBotOrderListType> sortData;

  /// Filter data for the market maker order list.
  final TradingEntitiesFilter? filterData;

  const MarketMakerOrderListState({
    this.makerBotOrders = const [],
    required this.status,
    required this.sortData,
    this.filterData,
  });

  MarketMakerOrderListState.initial()
    : this(
        status: MarketMakerOrderListStatus.initial,
        sortData: initialSortState(),
      );

  MarketMakerOrderListState copyWith({
    List<TradePair>? makerBotOrders,
    MarketMakerOrderListStatus? status,
    SortData<MarketMakerBotOrderListType>? sortData,
    TradingEntitiesFilter? filterData,
  }) {
    return MarketMakerOrderListState(
      makerBotOrders: makerBotOrders ?? this.makerBotOrders,
      status: status ?? this.status,
      sortData: sortData ?? this.sortData,
      filterData: filterData ?? this.filterData,
    );
  }

  static SortData<MarketMakerBotOrderListType> initialSortState() {
    return const SortData<MarketMakerBotOrderListType>(
      sortDirection: SortDirection.increase,
      sortType: MarketMakerBotOrderListType.send,
    );
  }

  @override
  List<Object?> get props => [makerBotOrders, status, sortData, filterData];
}
