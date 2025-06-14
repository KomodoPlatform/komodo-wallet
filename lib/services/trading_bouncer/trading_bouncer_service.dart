import 'package:http/http.dart' as http;
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/shared/constants.dart';

/// Service responsible for toggling trading features based on server status.
class TradingBouncerService {
  const TradingBouncerService();

  /// Queries the status endpoint and updates [kIsWalletOnly].
  /// Returns `true` when trading should be disabled.
  Future<bool> checkTradingStatus() async {
    try {
      final res = await http.get(Uri.parse(tradingBouncerEndpoint));
      final walletOnly = res.statusCode != 200;
      updateWalletOnly(walletOnly);
      return walletOnly;
    } catch (_) {
      updateWalletOnly(true);
      return true;
    }
  }
}

const TradingBouncerService tradingBouncerService = TradingBouncerService();
