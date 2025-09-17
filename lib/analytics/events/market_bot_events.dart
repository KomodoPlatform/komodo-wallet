import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:web_dex/bloc/analytics/analytics_event.dart';
import 'package:web_dex/bloc/analytics/analytics_repo.dart';

/// E27: Bot config wizard opened
class MarketbotSetupStartedEventData implements AnalyticsEventData {
  const MarketbotSetupStartedEventData({
    required this.strategyType,
    required this.pairsCount,
  });

  final String strategyType;
  final int pairsCount;

  @override
  String get name => 'marketbot_setup_start';

  @override
  JsonMap get parameters => {
    'strategy_type': strategyType,
    'pairs_count': pairsCount,
  };
}

class AnalyticsMarketbotSetupStartedEvent extends AnalyticsSendDataEvent {
  AnalyticsMarketbotSetupStartedEvent({
    required String strategyType,
    required int pairsCount,
  }) : super(
         MarketbotSetupStartedEventData(
           strategyType: strategyType,
           pairsCount: pairsCount,
         ),
       );
}

/// E28: Bot configured & saved
class MarketbotSetupCompleteEventData implements AnalyticsEventData {
  const MarketbotSetupCompleteEventData({
    required this.strategyType,
    required this.baseCapital,
  });

  final String strategyType;
  final double baseCapital;

  @override
  String get name => 'marketbot_setup_complete';

  @override
  JsonMap get parameters => {
    'strategy_type': strategyType,
    'base_capital': baseCapital,
  };
}

class AnalyticsMarketbotSetupCompleteEvent extends AnalyticsSendDataEvent {
  AnalyticsMarketbotSetupCompleteEvent({
    required String strategyType,
    required double baseCapital,
  }) : super(
         MarketbotSetupCompleteEventData(
           strategyType: strategyType,
           baseCapital: baseCapital,
         ),
       );
}

/// E29: Bot placed a trade
class MarketbotTradeExecutedEventData implements AnalyticsEventData {
  const MarketbotTradeExecutedEventData({
    required this.pair,
    required this.tradeSize,
    required this.profitUsd,
  });

  final String pair;
  final double tradeSize;
  final double profitUsd;

  @override
  String get name => 'marketbot_trade_executed';

  @override
  JsonMap get parameters => {
    'pair': pair,
    'trade_size': tradeSize,
    'profit_usd': profitUsd,
  };
}

class AnalyticsMarketbotTradeExecutedEvent extends AnalyticsSendDataEvent {
  AnalyticsMarketbotTradeExecutedEvent({
    required String pair,
    required double tradeSize,
    required double profitUsd,
  }) : super(
         MarketbotTradeExecutedEventData(
           pair: pair,
           tradeSize: tradeSize,
           profitUsd: profitUsd,
         ),
       );
}

/// E30: Bot error encountered
class MarketbotErrorEventData implements AnalyticsEventData {
  const MarketbotErrorEventData({
    required this.errorCode,
    required this.strategyType,
  });

  final String errorCode;
  final String strategyType;

  @override
  String get name => 'marketbot_error';

  @override
  JsonMap get parameters => {
    'error_code': errorCode,
    'strategy_type': strategyType,
  };
}

class AnalyticsMarketbotErrorEvent extends AnalyticsSendDataEvent {
  AnalyticsMarketbotErrorEvent({
    required String errorCode,
    required String strategyType,
  }) : super(
         MarketbotErrorEventData(
           errorCode: errorCode,
           strategyType: strategyType,
         ),
       );
}
