import 'package:dragon_charts_flutter/dragon_charts_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart'
    show SparklineRepository;
import 'package:komodo_defi_types/komodo_defi_types.dart' show AssetId;
import 'package:web_dex/generated/codegen_loader.g.dart';

class CoinSparkline extends StatelessWidget {
  const CoinSparkline({required this.coinId, required this.repository});

  final AssetId coinId;
  final SparklineRepository repository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<double>?>(
      future: repository.fetchSparkline(coinId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError) {
          return const SizedBox.shrink();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
          return const SizedBox.shrink();
        } else {
          return Tooltip(
            message: LocaleKeys.priceHistorySparklineTooltip.tr(),
            child: LimitedBox(
              maxWidth: 90,
              maxHeight: 35,
              child: SparklineChart(
                data: snapshot.data!,
                positiveLineColor: Colors.green,
                negativeLineColor: Colors.red,
                lineThickness: 1.0,
                isCurved: true,
              ),
            ),
          );
        }
      },
    );
  }
}
