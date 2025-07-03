// TODO! Renmove confusion between PriceChartInterval and missing feature of
// price chart period selection

enum PriceChartPeriod {
  oneHour,
  oneDay,
  oneWeek,
  oneMonth,
  oneYear;

  String get name {
    switch (this) {
      case PriceChartPeriod.oneHour:
        return '1H';
      case PriceChartPeriod.oneDay:
        return '1D';
      case PriceChartPeriod.oneWeek:
        return '1W';
      case PriceChartPeriod.oneMonth:
        return '1M';
      case PriceChartPeriod.oneYear:
        return '1Y';
    }
  }

  // TODO: Localize this
  String get formatted {
    switch (this) {
      case PriceChartPeriod.oneHour:
        return '1h';
      case PriceChartPeriod.oneDay:
        return '1d';
      case PriceChartPeriod.oneWeek:
        return '1w';
      case PriceChartPeriod.oneMonth:
        return '1M';
      case PriceChartPeriod.oneYear:
        return '1y';
    }
  }
}
