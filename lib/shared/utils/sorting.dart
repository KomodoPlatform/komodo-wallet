import 'package:web_dex/model/my_orders/my_order.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

/// unit tests: [testSorting]
int sortByDouble(
  double first,
  double second,
  SortDirection sortDirection,
) {
  if (first == second) return -1;
  switch (sortDirection) {
    case SortDirection.increase:
      return first - second > 0 ? 1 : -1;
    case SortDirection.decrease:
      return second - first > 0 ? 1 : -1;
    case SortDirection.none:
      return -1;
  }
}

int sortByOrderType(
    TradeSide first, TradeSide second, SortDirection sortDirection) {
  if (first == second || sortDirection == SortDirection.none) return -1;
  switch (sortDirection) {
    case SortDirection.increase:
      return first == TradeSide.taker && second == TradeSide.maker ? 1 : -1;

    case SortDirection.decrease:
      return second == TradeSide.taker && first == TradeSide.maker ? 1 : -1;
    case SortDirection.none:
      return -1;
  }
}

int sortByBool(bool first, bool second, SortDirection sortDirection) {
  if (first == second) return -1;
  switch (sortDirection) {
    case SortDirection.increase:
      return first && !second ? 1 : -1;
    case SortDirection.decrease:
      return first && !second ? -1 : 1;
    case SortDirection.none:
      return -1;
  }
}
