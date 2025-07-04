import 'package:equatable/equatable.dart';
import 'package:komodo_persistence_layer/komodo_persistence_layer.dart';
import 'package:komodo_wallet/bloc/cex_market_data/profit_loss/models/profit_loss.dart';

/// Cache for profit/loss data.
///
/// This class is used to store profit/loss data in a Hive box.
class ProfitLossCache extends Equatable
    implements ObjectWithPrimaryKey<String> {
  const ProfitLossCache({
    required this.coinId,
    required this.fiatCoinId,
    required this.lastUpdated,
    required this.profitLosses,
    required this.walletId,
    required this.isHdWallet,
  });

  /// The komodo coin abbreviation from the coins repository (e.g. BTC, KMD, etc.).
  final String coinId;

  /// The id of the stable coin that [coinId] is converted to (e.g. USDT, USD, etc.).
  /// This can be any coinId, but the intention is to use a stable coin to
  /// represent the fiat value of the coin in the profit/loss calculation.
  final String fiatCoinId;

  /// The wallet ID associated with the profit/loss data.
  final String walletId;

  /// Whether the wallet is an HD wallet. Same [walletId] can be used for both
  /// HD and non-HD wallets, but the profit/loss data will be different.
  final bool isHdWallet;

  /// The timestamp of the last update in seconds since epoch.
  /// (e.g. [DateTime.now().millisecondsSinceEpoch ~/ 1000])
  final DateTime lastUpdated;

  /// The list of [ProfitLoss] data.
  final List<ProfitLoss> profitLosses;

  @override
  String get primaryKey => getPrimaryKey(
        coinId: coinId,
        fiatCurrency: fiatCoinId,
        walletId: walletId,
        isHdWallet: isHdWallet,
      );

  static String getPrimaryKey({
    required String coinId,
    required String fiatCurrency,
    required String walletId,
    required bool isHdWallet,
  }) =>
      '$coinId-$fiatCurrency-$walletId-$isHdWallet';

  @override
  List<Object?> get props => [coinId, fiatCoinId, lastUpdated, profitLosses];
}
