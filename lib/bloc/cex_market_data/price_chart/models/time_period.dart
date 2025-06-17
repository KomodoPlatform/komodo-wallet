// TODO! Renmove confusion between PriceChartInterval and missing feature of
// price chart period selection

enum TimePeriod {
  oneHour,
  oneDay,
  oneWeek,
  oneMonth,
  oneYear;

  String get name {
    switch (this) {
      case TimePeriod.oneHour:
        return '1H';
      case TimePeriod.oneDay:
        return '1D';
      case TimePeriod.oneWeek:
        return '1W';
      case TimePeriod.oneMonth:
        return '1M';
      case TimePeriod.oneYear:
        return '1Y';
    }
  }

  // TODO: Localize
  String formatted() => name;

  Duration get duration {
    switch (this) {
      case TimePeriod.oneHour:
        return const Duration(hours: 1);
      case TimePeriod.oneDay:
        return const Duration(days: 1);
      case TimePeriod.oneWeek:
        return const Duration(days: 7);
      case TimePeriod.oneMonth:
        return const Duration(days: 30);
      case TimePeriod.oneYear:
        return const Duration(days: 365);
    }
  }
}
