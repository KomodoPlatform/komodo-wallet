import 'package:komodo_ui_kit/komodo_ui_kit.dart';

/// Available sort types for Coins Manager list.
enum CoinsManagerSortType {
  protocol,
  balance,
  name,
  none,
}

/// Sort configuration for Coins Manager.
class CoinsManagerSortData implements SortData<CoinsManagerSortType> {
  const CoinsManagerSortData({
    required this.sortDirection,
    required this.sortType,
  });

  @override
  final CoinsManagerSortType sortType;

  @override
  final SortDirection sortDirection;
}
