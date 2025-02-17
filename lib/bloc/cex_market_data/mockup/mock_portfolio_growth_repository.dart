import 'package:http/http.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:komodo_persistence_layer/komodo_persistence_layer.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/generator.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/mock_transaction_history_repository.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/performance_mode.dart';
import 'package:web_dex/bloc/cex_market_data/models/graph_cache.dart';
import 'package:web_dex/bloc/cex_market_data/models/graph_type.dart';
import 'package:web_dex/bloc/cex_market_data/portfolio_growth/portfolio_growth_repository.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';

class MockPortfolioGrowthRepository extends PortfolioGrowthRepository {
  final PerformanceMode performanceMode;

  MockPortfolioGrowthRepository({
    required super.cexRepository,
    required super.transactionHistoryRepo,
    required super.cacheProvider,
    required this.performanceMode,
    required super.coinsRepository,
  });

  MockPortfolioGrowthRepository.withDefaults({
    required this.performanceMode,
    required CoinsRepo coinsRepository,
    required Mm2Api mm2Api,
  }) : super(
          cexRepository: BinanceRepository(
            binanceProvider: const BinanceProvider(),
          ),
          transactionHistoryRepo: MockTransactionHistoryRepo(
            api: mm2Api,
            client: Client(),
            performanceMode: performanceMode,
            demoDataGenerator: DemoDataCache.withDefaults(),
          ),
          cacheProvider: HiveLazyBoxProvider<String, GraphCache>(
            name: GraphType.balanceGrowth.tableName,
          ),
          coinsRepository: coinsRepository,
        );
}
