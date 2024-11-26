// TODO(Francois): delete once the migration is done
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc_state.dart';
import 'package:web_dex/bloc/auth_bloc/auth_repository.dart';
import 'package:web_dex/bloc/dex_repository.dart';
import 'package:web_dex/bloc/dex_tab_bar/dex_tab_bar_bloc.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_bot/market_maker_bot_bloc.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_order_list/market_maker_bot_order_list_repository.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_order_list/market_maker_order_list_bloc.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_trade_form/market_maker_trade_form_bloc.dart';
import 'package:web_dex/bloc/settings/settings_repository.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/services/orders_service/my_orders_service.dart';
import 'package:web_dex/views/dex/entity_details/trading_details.dart';
import 'package:web_dex/views/market_maker_bot/market_maker_bot_view.dart';

class MarketMakerBotPage extends StatefulWidget {
  const MarketMakerBotPage() : super(key: const Key('market-maker-bot-page'));

  @override
  State<StatefulWidget> createState() => _MarketMakerBotPageState();
}

class _MarketMakerBotPageState extends State<MarketMakerBotPage> {
  bool isTradingDetails = false;

  @override
  void initState() {
    routingState.marketMakerState.addListener(_onRouteChange);
    super.initState();
  }

  @override
  void dispose() {
    routingState.marketMakerState.removeListener(_onRouteChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderListRepository = MarketMakerBotOrderListRepository(
      myOrdersService,
      SettingsRepository(),
      coinsBloc,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<DexTabBarBloc>(
          create: (BuildContext context) => DexTabBarBloc(
            authRepo,
            tradingEntitiesBloc,
            orderListRepository,
          )..add(const StartListening()),
        ),
        BlocProvider<MarketMakerTradeFormBloc>(
          create: (BuildContext context) => MarketMakerTradeFormBloc(
            dexRepo: DexRepository(),
            coinsRepo: coinsBloc,
          ),
        ),
        BlocProvider<MarketMakerOrderListBloc>(
          create: (BuildContext context) => MarketMakerOrderListBloc(
            MarketMakerBotOrderListRepository(
              myOrdersService,
              SettingsRepository(),
              coinsBloc,
            ),
          ),
        ),
      ],
      child: BlocListener<AuthBloc, AuthBlocState>(
        listener: (context, state) {
          if (state.mode == AuthorizeMode.noLogin) {
            context
                .read<MarketMakerBotBloc>()
                .add(const MarketMakerBotStopRequested());
          }
        },
        child: isTradingDetails
            ? TradingDetails(uuid: routingState.marketMakerState.uuid)
            : MarketMakerBotView(),
      ),
    );
  }

  void _onRouteChange() {
    setState(
      () => isTradingDetails = routingState.marketMakerState.isTradingDetails,
    );
  }
}
