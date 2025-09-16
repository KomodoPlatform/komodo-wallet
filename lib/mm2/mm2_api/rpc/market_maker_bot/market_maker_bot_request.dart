import 'package:web_dex/mm2/mm2_api/rpc/base.dart';

import 'market_maker_bot_parameters.dart';

/// The request object to start or stop a market maker bot.
class MarketMakerBotRequest implements BaseRequest {
  MarketMakerBotRequest({
    this.userpass = '',
    this.mmrpc = "2.0",
    this.method = 'start_simple_market_maker_bot',
    this.params = const MarketMakerBotParameters(),
    required this.id,
  });

  /// The RPC user password populated by the MM2 API before sending,
  /// so this field should be left null or empty.
  @override
  String userpass;

  /// The MM2 RPC version. Defaults to "2.0".
  final String mmrpc;

  /// The name of the MM2 RPC method to call. Defaults to "start_simple_market_maker_bot".
  @override
  final String method;

  /// The parameters to pass to the MM2 RPC method. This includes the coin
  /// pairs to trade, the price URL, and the bot refresh rate. Defaults to null.
  final MarketMakerBotParameters? params;

  /// The ID of the market maker bot to start. Defaults to 0.
  final int id;

  @override
  Map<String, dynamic> toJson() => {
    'userpass': userpass,
    'mmrpc': mmrpc,
    'method': method,
    'params': params?.toJson() ?? {},
    'id': id,
  };

  MarketMakerBotRequest copyWith({
    String? mmrpc,
    String? method,
    MarketMakerBotParameters? params,
    int? id,
  }) {
    return MarketMakerBotRequest(
      mmrpc: mmrpc ?? this.mmrpc,
      method: method ?? this.method,
      params: params ?? this.params,
      id: id ?? this.id,
    );
  }
}
