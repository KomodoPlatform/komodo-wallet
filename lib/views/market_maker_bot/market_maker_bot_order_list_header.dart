import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/shared/ui/ui_list_header_with_sortings.dart';

class MarketMakerBotOrderListHeader extends StatelessWidget {
  const MarketMakerBotOrderListHeader({
    Key? key,
    required this.sortData,
    required this.onSortChange,
  }) : super(key: key);
  final SortData<MarketMakerBotOrderListType> sortData;
  final void Function(SortData<MarketMakerBotOrderListType>) onSortChange;

  @override
  Widget build(BuildContext context) {
    return UiListHeaderWithSorting<MarketMakerBotOrderListType>(
      items: _headerItems,
      sortData: sortData,
      onSortChange: onSortChange,
    );
  }
}

List<SortHeaderItemData<MarketMakerBotOrderListType>> _headerItems = [
  SortHeaderItemData<MarketMakerBotOrderListType>(
    text: LocaleKeys.offer.tr(),
    value: MarketMakerBotOrderListType.send,
    flex: 5,
  ),
  SortHeaderItemData<MarketMakerBotOrderListType>(
    text: LocaleKeys.asking.tr(),
    value: MarketMakerBotOrderListType.receive,
    flex: 5,
  ),
  SortHeaderItemData<MarketMakerBotOrderListType>(
    text: LocaleKeys.price.tr(),
    value: MarketMakerBotOrderListType.price,
    flex: 3,
  ),
  SortHeaderItemData<MarketMakerBotOrderListType>(
    text: LocaleKeys.margin.tr(),
    value: MarketMakerBotOrderListType.margin,
    flex: 3,
  ),
  SortHeaderItemData<MarketMakerBotOrderListType>(
    text: LocaleKeys.updateInterval.tr(),
    value: MarketMakerBotOrderListType.updateInterval,
    flex: 4,
  ),
  SortHeaderItemData<MarketMakerBotOrderListType>(
    text: LocaleKeys.date.tr(),
    value: MarketMakerBotOrderListType.date,
    flex: 4,
  ),
  SortHeaderItemData<MarketMakerBotOrderListType>(
    text: '',
    flex: 5,
    value: MarketMakerBotOrderListType.none,
    isEmpty: true,
  ),
];

enum MarketMakerBotOrderListType {
  send,
  receive,
  price,
  margin,
  updateInterval,
  date,
  none,
}
