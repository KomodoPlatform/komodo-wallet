import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/shared/ui/ui_list_header_with_sortings.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class OrderListHeader extends StatelessWidget {
  const OrderListHeader({
    Key? key,
    required this.sortData,
    required this.onSortChange,
  }) : super(key: key);
  final SortData<OrderListSortType> sortData;
  final void Function(SortData<OrderListSortType>) onSortChange;

  @override
  Widget build(BuildContext context) {
    return UiListHeaderWithSorting<OrderListSortType>(
      items: _headerItems,
      sortData: sortData,
      onSortChange: onSortChange,
    );
  }
}

List<SortHeaderItemData<OrderListSortType>> _headerItems = [
  SortHeaderItemData<OrderListSortType>(
    text: LocaleKeys.send.tr(),
    value: OrderListSortType.send,
  ),
  SortHeaderItemData<OrderListSortType>(
    text: LocaleKeys.receive.tr(),
    value: OrderListSortType.receive,
  ),
  SortHeaderItemData<OrderListSortType>(
    text: LocaleKeys.price.tr(),
    value: OrderListSortType.price,
  ),
  SortHeaderItemData<OrderListSortType>(
    text: LocaleKeys.date.tr(),
    value: OrderListSortType.date,
  ),
  SortHeaderItemData<OrderListSortType>(
    text: LocaleKeys.orderType.tr(),
    flex: 0,
    width: 100,
    value: OrderListSortType.orderType,
  ),
  SortHeaderItemData<OrderListSortType>(
    text: '',
    flex: 0,
    width: 80,
    value: OrderListSortType.none,
    isEmpty: true,
  ),
];

enum OrderListSortType {
  send,
  receive,
  price,
  date,
  orderType,
  none,
}
