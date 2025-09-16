// TODO? The names of these classes don't seem to be very descriptive and the
// hierachy may be confusing. Consider renaming them if this is conirmed.

// TODO? Make all classes in this file generic classes with type parameters
// so that they can be re-used for other charts.
class CoinPriceInfo {
  final String ticker;
  final String name;
  final String id;

  final double selectedPeriodIncreasePercentage;

  CoinPriceInfo({
    required this.ticker,
    required this.selectedPeriodIncreasePercentage,
    required this.id,
    required this.name,
  });
}

class PriceChartSeriesPoint {
  final double usdValue;
  final double unixTimestamp;

  PriceChartSeriesPoint({
    required this.usdValue,
    required this.unixTimestamp,
  });
}

class PriceChartDataSeries {
  PriceChartDataSeries({
    required this.info,
    required this.data,
  });
  final CoinPriceInfo info;

  // TODO: Better approach to use class or Map? Latter allows us to cut out
  // the point class. E.g. Map<{x type}, {y type}>.
  final List<PriceChartSeriesPoint> data;
}
