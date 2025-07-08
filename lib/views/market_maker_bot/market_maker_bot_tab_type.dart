import 'package:web_dex/localization/app_localizations.dart';
import 'package:web_dex/bloc/dex_tab_bar/dex_tab_bar_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/dex_list_type.dart';
import 'package:web_dex/views/market_maker_bot/tab_type_enum.dart';

enum MarketMakerBotTabType implements ITabTypeEnum {
  marketMaker,
  inProgress,
  orders,
  history;

  @override
  String name(DexTabBarState bloc) {
    switch (this) {
      case marketMaker:
        return LocaleKeys.makeMarket.tr();
      case orders:
        return '${LocaleKeys.orders.tr()} (${bloc.tradeBotOrdersCount})';
      case inProgress:
        return '${LocaleKeys.inProgress.tr()} (${bloc.inProgressCount})';
      case history:
        return '${LocaleKeys.history.tr()} (${bloc.completedCount})';
    }
  }

  @override
  String get key {
    switch (this) {
      case marketMaker:
        return 'market-maker-bot-tab';
      case orders:
        return 'market-maker-orders-tab';
      case inProgress:
        return 'market-maker-in-progress-tab';
      case history:
        return 'market-maker-history-tab';
    }
  }

  /// This is a temporary solution to avoid changing the entire DEX flow to add
  /// the market maker bot tab.
  // TODO: separate the tab widget logic from the page logic
  DexListType toDexListType() {
    switch (this) {
      case marketMaker:
        return DexListType.swap;
      case orders:
        return DexListType.orders;
      case inProgress:
        return DexListType.inProgress;
      case history:
        return DexListType.history;
    }
  }
}
