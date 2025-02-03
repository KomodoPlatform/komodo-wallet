import 'package:http/http.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/generator.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/performance_mode.dart';
import 'package:web_dex/bloc/transaction_history/transaction_history_repo.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/mm2/mm2_api/rpc/my_tx_history/transaction.dart';
import 'package:web_dex/model/coin.dart';

class MockTransactionHistoryRepo extends TransactionHistoryRepo {
  final PerformanceMode performanceMode;
  final DemoDataCache demoDataGenerator;

  MockTransactionHistoryRepo({
    required Mm2Api api,
    required Client client,
    required this.performanceMode,
    required this.demoDataGenerator,
    required super.sdk,
  });

  // TODO: SDK Port needed, not sure about this part
  Future<List<Transaction>> fetchTransactions(Coin coin) async {
    return demoDataGenerator.loadTransactionsDemoData(
      performanceMode,
      coin.abbr,
    );
  }
}
