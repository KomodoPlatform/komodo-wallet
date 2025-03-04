import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/generator.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/performance_mode.dart';
import 'package:web_dex/bloc/transaction_history/transaction_history_repo.dart';

class MockTransactionHistoryRepo implements TransactionHistoryRepo {
  MockTransactionHistoryRepo({
    required this.performanceMode,
    required this.demoDataGenerator,
  });

  final PerformanceMode performanceMode;
  final DemoDataCache demoDataGenerator;

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
