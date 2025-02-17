import 'package:http/http.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/generator.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/performance_mode.dart';
import 'package:web_dex/bloc/transaction_history/transaction_history_repo.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';

class MockTransactionHistoryRepo implements TransactionHistoryRepo {
  final PerformanceMode performanceMode;
  final DemoDataCache demoDataGenerator;

  MockTransactionHistoryRepo({
    required Mm2Api api,
    required Client client,
    required this.performanceMode,
    required this.demoDataGenerator,
  });
  @override
  Future<List<Transaction>> fetch(AssetId assetId) {
    return demoDataGenerator.loadTransactionsDemoData(
      performanceMode,
      assetId.id,
    );
  }

  @override
  Future<List<Transaction>> fetchCompletedTransactions(AssetId assetId) {
    return fetch(assetId);
  }
}
