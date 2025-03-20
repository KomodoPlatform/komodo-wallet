import 'package:equatable/equatable.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:komodo_persistence_layer/komodo_persistence_layer.dart';
import 'package:web_dex/bloc/cex_market_data/charts.dart';
import 'package:web_dex/bloc/cex_market_data/models/graph_type.dart';

/// Cache for the portfolio growth graph data.
class GraphCache extends Equatable implements ObjectWithPrimaryKey<String> {
  /// Create a new instance of the cache.
  const GraphCache({
    required this.coinId,
    required this.fiatCoinId,
    required this.lastUpdated,
    required this.graph,
    required this.graphType,
    required this.walletId,
    required this.isHdWallet,
  });

  factory GraphCache.fromJson(Map<String, dynamic> json) {
    return GraphCache(
      coinId: json.value<String>('coinId'),
      fiatCoinId: json.value<String>('fiatCoinId'),
      lastUpdated: DateTime.parse(json.value<String>('lastUpdated')),
      graph: List.from(json.value<List<dynamic>>('portfolioGrowthGraphs')),
      graphType: json.value<GraphType>('graphType'),
      walletId: json.value<String>('walletId'),
      // Explicitly set the default value to false for backwards compatibility.
      isHdWallet: json.valueOrNull<bool>('isHdWallet') ?? false,
    );
  }

  static String getPrimaryKey({
    required String coinId,
    required String fiatCoinId,
    required GraphType graphType,
    required String walletId,
    required bool isHdWallet,
  }) =>
      '$coinId-$fiatCoinId-${graphType.name}-$walletId-$isHdWallet';

  /// The komodo coin abbreviation from the coins repository (e.g. BTC, etc.).
  final String coinId;

  /// The fiat coin abbreviation (e.g. USDT, etc.).
  final String fiatCoinId;

  /// The timestamp of the last update.
  final DateTime lastUpdated;

  /// The portfolio growth graph data.
  final ChartData graph;

  /// The type of the graph.
  final GraphType graphType;

  /// The wallet ID.
  final String walletId;

  /// The flag indicating if the wallet is an HD wallet. A wallet with
  /// [walletId] can be either a regular wallet or an HD wallet.
  final bool isHdWallet;

  Map<String, dynamic> toJson() {
    return {
      'coinId': coinId,
      'fiatCoinId': fiatCoinId,
      'lastUpdated': lastUpdated.toIso8601String(),
      'portfolioGrowthGraphs': graph,
      'graphType': graphType,
      'walletId': walletId,
    };
  }

  GraphCache copyWith({
    String? coinId,
    String? fiatCoinId,
    DateTime? lastUpdated,
    ChartData? portfolioGrowthGraphs,
    GraphType? graphType,
    String? walletId,
    bool? isHdWallet,
  }) {
    return GraphCache(
      coinId: coinId ?? this.coinId,
      fiatCoinId: fiatCoinId ?? this.fiatCoinId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      graph: portfolioGrowthGraphs ?? graph,
      graphType: graphType ?? this.graphType,
      walletId: walletId ?? this.walletId,
      isHdWallet: isHdWallet ?? this.isHdWallet,
    );
  }

  @override
  List<Object?> get props => [
        coinId,
        fiatCoinId,
        lastUpdated,
        graph,
        graphType,
        walletId,
      ];

  @override
  String get primaryKey => GraphCache.getPrimaryKey(
        coinId: coinId,
        fiatCoinId: fiatCoinId,
        graphType: graphType,
        walletId: walletId,
        isHdWallet: isHdWallet,
      );
}
