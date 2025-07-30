import 'package:dragon_charts_flutter/dragon_charts_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/utils/utils.dart';

class CoinSparkline extends StatelessWidget {
  final String coinId;
  final SparklineRepository repository = sparklineRepository;

  CoinSparkline({required this.coinId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<double>?>(
      future: repository.fetchSparkline(abbr2Ticker(coinId)),
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
