import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_repository.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_order_list/market_maker_bot_order_list_repository.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_order_list/trade_pair.dart';
import 'package:web_dex/blocs/trading_entities_bloc.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/my_orders/my_order.dart';
import 'package:web_dex/model/swap.dart';
import 'package:web_dex/model/trading_entities_filter.dart';
import 'package:web_dex/views/market_maker_bot/tab_type_enum.dart';

part 'dex_tab_bar_event.dart';
part 'dex_tab_bar_state.dart';

class DexTabBarBloc extends Bloc<DexTabBarEvent, DexTabBarState> {
  DexTabBarBloc(
    AuthRepository authRepo,
    this._tradingEntitiesBloc,
    this._tradingBotRepository,
  ) : super(const DexTabBarState.initial()) {
    on<TabChanged>(_onTabChanged);
    on<FilterChanged>(_onFilterChanged);
    on<StartListening>(_onStartListening);
    on<StopListening>(_onStopListening);
    on<MyOrdersUpdated>(_onMyOrdersUpdated);
    on<SwapsUpdated>(_onSwapsUpdated);
    on<TradeBotOrdersUpdated>(_onTradeBotOrdersUpdated);

    _authorizationSubscription = authRepo.authMode.listen((event) {
      if (event == AuthorizeMode.noLogin) {
        add(const TabChanged(0));
      }
    });
  }

  final TradingEntitiesBloc _tradingEntitiesBloc;
  final MarketMakerBotOrderListRepository _tradingBotRepository;

  StreamSubscription<AuthorizeMode>? _authorizationSubscription;
  StreamSubscription<List<MyOrder>>? _myOrdersSubscription;
  StreamSubscription<List<Swap>>? _swapsSubscription;
  StreamSubscription<List<TradePair>>? _tradeBotOrdersSubscription;

  @override
  Future<void> close() async {
    await _authorizationSubscription?.cancel();
    await _myOrdersSubscription?.cancel();
    await _swapsSubscription?.cancel();
    await _tradeBotOrdersSubscription?.cancel();
    return super.close();
  }

  Future<void> _onStartListening(
    StartListening event,
    Emitter<DexTabBarState> emit,
  ) async {
    _myOrdersSubscription = _tradingEntitiesBloc.outMyOrders.listen((myOrders) {
      add(MyOrdersUpdated(myOrders));
    });

    _swapsSubscription = _tradingEntitiesBloc.outSwaps.listen((swaps) {
      add(SwapsUpdated(swaps));
    });

    _tradeBotOrdersSubscription = Stream.periodic(const Duration(seconds: 3))
        .asyncMap((_) => _tradingBotRepository.getTradePairs())
        .listen((orders) {
      add(TradeBotOrdersUpdated(orders));
    });
  }

  Future<void> _onStopListening(
    StopListening event,
    Emitter<DexTabBarState> emit,
  ) async {
    await _myOrdersSubscription?.cancel();
    _myOrdersSubscription = null;

    await _swapsSubscription?.cancel();
    _swapsSubscription = null;

    await _tradeBotOrdersSubscription?.cancel();
    _tradeBotOrdersSubscription = null;
  }

  FutureOr<void> _onTabChanged(TabChanged event, Emitter<DexTabBarState> emit) {
    emit(state.copyWith(tabIndex: event.tabIndex));
  }

  void _onFilterChanged(FilterChanged event, Emitter<DexTabBarState> emit) {
    emit(
      state.copyWith(
        filters: {
          ...state.filters,
          event.tabType: event.filter!,
        },
      ),
    );
  }

  void _onMyOrdersUpdated(MyOrdersUpdated event, Emitter<DexTabBarState> emit) {
    final ordersCount = event.myOrders.length;
    emit(state.copyWith(ordersCount: ordersCount));
  }

  void _onSwapsUpdated(SwapsUpdated event, Emitter<DexTabBarState> emit) {
    final inProgressCount =
        event.swaps.where((swap) => !swap.isCompleted).length;
    final completedCount = event.swaps.where((swap) => swap.isCompleted).length;
    emit(
      state.copyWith(
        inProgressCount: inProgressCount,
        completedCount: completedCount,
      ),
    );
  }

  void _onTradeBotOrdersUpdated(
    TradeBotOrdersUpdated event,
    Emitter<DexTabBarState> emit,
  ) {
    emit(
      state.copyWith(
        tradeBotOrdersCount: event.tradeBotOrders.length,
      ),
    );
  }
}
