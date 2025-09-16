import 'package:equatable/equatable.dart';
import 'package:web_dex/mm2/mm2_api/rpc/market_maker_bot/message_service_config/message_service_config.dart';
import 'package:web_dex/mm2/mm2_api/rpc/market_maker_bot/trade_coin_pair_config.dart';
import 'package:web_dex/shared/constants.dart';

/// Settings for the KDF Simple Market Maker Bot.
class MarketMakerBotSettings extends Equatable {
  const MarketMakerBotSettings({
    required this.isMMBotEnabled,
    required this.priceUrl,
    required this.botRefreshRate,
    required this.tradeCoinPairConfigs,
    this.messageServiceConfig,
  });

  /// Initial (default) settings for the Market Maker Bot.
  ///
  /// The Market Maker Bot is disabled by default and all other settings are
  /// empty or zero.
  factory MarketMakerBotSettings.initial() {
    return MarketMakerBotSettings(
      isMMBotEnabled: false,
      priceUrl: pricesUrlV3.toString(),
      botRefreshRate: 60,
      tradeCoinPairConfigs: const [],
      messageServiceConfig: null,
    );
  }

  /// Creates a Market Maker Bot settings object from a JSON map.
  /// Returns the initial settings if the JSON map is null or does not contain
  /// the required `is_market_maker_bot_enabled` key.
  factory MarketMakerBotSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null || !json.containsKey('is_market_maker_bot_enabled')) {
      return MarketMakerBotSettings.initial();
    }

    return MarketMakerBotSettings(
      isMMBotEnabled: json['is_market_maker_bot_enabled'] as bool,
      priceUrl: json['price_url'] as String,
      botRefreshRate: json['bot_refresh_rate'] as int,
      tradeCoinPairConfigs: (json['trade_coin_pair_configs'] as List<dynamic>)
          .map((e) => TradeCoinPairConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      messageServiceConfig: json['message_service_config'] == null
          ? null
          : MessageServiceConfig.fromJson(
              json['message_service_config'] as Map<String, dynamic>,
            ),
    );
  }

  /// Whether the Market Maker Bot is enabled (menu item is shown or not).
  final bool isMMBotEnabled;

  /// The URL to fetch the price data from.
  final String priceUrl;

  /// The refresh rate of the bot in seconds.
  final int botRefreshRate;

  /// The list of trade coin pair configurations.
  final List<TradeCoinPairConfig> tradeCoinPairConfigs;

  /// The message service configuration.
  ///
  /// This is used to enable Telegram notifications for the bot.
  final MessageServiceConfig? messageServiceConfig;

  Map<String, dynamic> toJson() {
    return {
      'is_market_maker_bot_enabled': isMMBotEnabled,
      'price_url': priceUrl,
      'bot_refresh_rate': botRefreshRate,
      'trade_coin_pair_configs':
          tradeCoinPairConfigs.map((e) => e.toJson()).toList(),
      if (messageServiceConfig != null)
        'message_service_config': messageServiceConfig?.toJson(),
    };
  }

  MarketMakerBotSettings copyWith({
    bool? isMMBotEnabled,
    String? priceUrl,
    int? botRefreshRate,
    List<TradeCoinPairConfig>? tradeCoinPairConfigs,
    MessageServiceConfig? messageServiceConfig,
  }) {
    return MarketMakerBotSettings(
      isMMBotEnabled: isMMBotEnabled ?? this.isMMBotEnabled,
      priceUrl: priceUrl ?? this.priceUrl,
      botRefreshRate: botRefreshRate ?? this.botRefreshRate,
      tradeCoinPairConfigs: tradeCoinPairConfigs ?? this.tradeCoinPairConfigs,
      messageServiceConfig: messageServiceConfig ?? this.messageServiceConfig,
    );
  }

  @override
  List<Object?> get props => [
        isMMBotEnabled,
        priceUrl,
        botRefreshRate,
        tradeCoinPairConfigs,
        messageServiceConfig,
      ];
}
