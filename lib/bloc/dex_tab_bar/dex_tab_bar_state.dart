part of 'dex_tab_bar_bloc.dart';

class DexTabBarState extends Equatable {
  const DexTabBarState({
    required this.tabIndex,
    required this.filters,
    required this.ordersCount,
    required this.inProgressCount,
    required this.completedCount,
    required this.tradeBotOrdersCount,
  });

  const DexTabBarState.initial()
    : tabIndex = 0,
      filters = const {},
      ordersCount = 0,
      inProgressCount = 0,
      completedCount = 0,
      tradeBotOrdersCount = 0;

  final int tabIndex;
  final Map<ITabTypeEnum, TradingEntitiesFilter?> filters;
  final int ordersCount;
  final int inProgressCount;
  final int completedCount;
  final int tradeBotOrdersCount;

  DexTabBarState copyWith({
    int? tabIndex,
    Map<ITabTypeEnum, TradingEntitiesFilter?>? filters,
    int? ordersCount,
    int? inProgressCount,
    int? completedCount,
    int? tradeBotOrdersCount,
  }) {
    return DexTabBarState(
      tabIndex: tabIndex ?? this.tabIndex,
      filters: filters ?? this.filters,
      ordersCount: ordersCount ?? this.ordersCount,
      inProgressCount: inProgressCount ?? this.inProgressCount,
      completedCount: completedCount ?? this.completedCount,
      tradeBotOrdersCount: tradeBotOrdersCount ?? this.tradeBotOrdersCount,
    );
  }

  @override
  List<Object?> get props => [
    tabIndex,
    filters,
    ordersCount,
    inProgressCount,
    completedCount,
    tradeBotOrdersCount,
  ];
}
