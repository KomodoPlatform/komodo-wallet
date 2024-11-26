part of 'dex_tab_bar_bloc.dart';

abstract class DexTabBarEvent extends Equatable {
  const DexTabBarEvent();

  @override
  List<Object?> get props => [];
}

class TabChanged extends DexTabBarEvent {
  const TabChanged(this.tabIndex);
  final int tabIndex;
  @override
  List<Object> get props => [tabIndex];
}

class FilterChanged extends DexTabBarEvent {
  const FilterChanged({required this.tabType, required this.filter});

  final ITabTypeEnum tabType;
  final TradingEntitiesFilter? filter;

  @override
  List<Object?> get props => [tabType, filter];
}

class StartListening extends DexTabBarEvent {
  const StartListening();
}

class StopListening extends DexTabBarEvent {
  const StopListening();
}

class MyOrdersUpdated extends DexTabBarEvent {
  const MyOrdersUpdated(this.myOrders);
  final List<MyOrder> myOrders;

  @override
  List<Object?> get props => [myOrders];
}

class SwapsUpdated extends DexTabBarEvent {
  const SwapsUpdated(this.swaps);
  final List<Swap> swaps;

  @override
  List<Object?> get props => [swaps];
}

class TradeBotOrdersUpdated extends DexTabBarEvent {
  const TradeBotOrdersUpdated(this.tradeBotOrders);
  final List<TradePair> tradeBotOrders;

  @override
  List<Object?> get props => [tradeBotOrders];
}
