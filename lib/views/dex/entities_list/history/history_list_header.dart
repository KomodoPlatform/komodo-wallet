import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/shared/ui/ui_list_header_with_sortings.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class HistoryListHeader extends StatelessWidget {
  const HistoryListHeader({
    Key? key,
    required this.sortData,
    required this.onSortChange,
  }) : super(key: key);
  final SortData<HistoryListSortType> sortData;
  final void Function(SortData<HistoryListSortType>) onSortChange;

  @override
  Widget build(BuildContext context) {
    return UiListHeaderWithSorting<HistoryListSortType>(
      items: _headerItems,
      sortData: sortData,
      onSortChange: onSortChange,
    );
  }
}

List<SortHeaderItemData<HistoryListSortType>> _headerItems = [
  SortHeaderItemData<HistoryListSortType>(
    text: LocaleKeys.status.tr(),
    value: HistoryListSortType.status,
  ),
  SortHeaderItemData<HistoryListSortType>(
    text: LocaleKeys.send.tr(),
    value: HistoryListSortType.send,
  ),
  SortHeaderItemData<HistoryListSortType>(
    text: LocaleKeys.receive.tr(),
    value: HistoryListSortType.receive,
  ),
  SortHeaderItemData<HistoryListSortType>(
    text: LocaleKeys.price.tr(),
    value: HistoryListSortType.price,
  ),
  SortHeaderItemData<HistoryListSortType>(
    text: LocaleKeys.date.tr(),
    value: HistoryListSortType.date,
  ),
  SortHeaderItemData<HistoryListSortType>(
    text: LocaleKeys.orderType.tr(),
    flex: 0,
    value: HistoryListSortType.orderType,
  ),
  SortHeaderItemData<HistoryListSortType>(
    text: '',
    width: 80,
    flex: 0,
    isEmpty: true,
    value: HistoryListSortType.none,
  ),
];

enum HistoryListSortType {
  status,
  send,
  receive,
  price,
  date,
  orderType,
  none,
}
