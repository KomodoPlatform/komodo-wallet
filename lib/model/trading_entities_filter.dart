import 'package:komodo_wallet/model/my_orders/my_order.dart';

enum TradingStatus {
  successful,
  failed,
}

class TradingEntitiesFilter {
  TradingEntitiesFilter({
    this.sellCoin,
    this.buyCoin,
    this.startDate,
    this.endDate,
    this.statuses,
    this.shownSides,
  });

  factory TradingEntitiesFilter.from(TradingEntitiesFilter? data) {
    if (data == null) return TradingEntitiesFilter();

    return TradingEntitiesFilter(
      buyCoin: data.buyCoin,
      endDate: data.endDate,
      sellCoin: data.sellCoin,
      shownSides: data.shownSides,
      startDate: data.startDate,
      statuses: data.statuses,
    );
  }

  bool get isEmpty {
    return (sellCoin?.isEmpty ?? true) &&
        (buyCoin?.isEmpty ?? true) &&
        startDate == null &&
        endDate == null &&
        (statuses?.isEmpty ?? true) &&
        (shownSides?.isEmpty ?? true);
  }

  String? sellCoin;
  String? buyCoin;
  DateTime? startDate;
  DateTime? endDate;
  List<TradingStatus>? statuses;
  List<TradeSide>? shownSides;
}
