import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_persistence_layer/komodo_persistence_layer.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/generator.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/mock_transaction_history_repository.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/performance_mode.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/models/profit_loss_cache.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/profit_loss_calculator.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/profit_loss_repository.dart';

class MockProfitLossRepository extends ProfitLossRepository {
  MockProfitLossRepository({
    required this.performanceMode,
    required super.transactionHistoryRepo,
    required super.cexRepository,
    required super.profitLossCacheProvider,
    required super.profitLossCalculator,
    required super.sdk,
  });

  factory MockProfitLossRepository.withDefaults({
    required PerformanceMode performanceMode,
    required KomodoDefiSdk sdk,
    String cacheTableName = 'mock_profit_loss',
  }) {
    return MockProfitLossRepository(
      profitLossCacheProvider:
          HiveLazyBoxProvider<String, ProfitLossCache>(name: cacheTableName),
      cexRepository: BinanceRepository(
        binanceProvider: const BinanceProvider(),
      ),
      performanceMode: performanceMode,
      transactionHistoryRepo: MockTransactionHistoryRepo(
        performanceMode: performanceMode,
        demoDataGenerator: DemoDataCache.withDefaults(),
      ),
      profitLossCalculator: RealisedProfitLossCalculator(
        BinanceRepository(
          binanceProvider: const BinanceProvider(),
        ),
      ),
      sdk: sdk,
    );
  }

  final PerformanceMode performanceMode;
}
