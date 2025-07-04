import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/shared/ui/ui_list_header_with_sortings.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class InProgressListHeader extends StatelessWidget {
  const InProgressListHeader({
    Key? key,
    required this.sortData,
    required this.onSortChange,
  }) : super(key: key);
  final SortData<InProgressListSortType> sortData;
  final void Function(SortData<InProgressListSortType>) onSortChange;

  @override
  Widget build(BuildContext context) {
    return UiListHeaderWithSorting<InProgressListSortType>(
      items: _headerItems,
      sortData: sortData,
      onSortChange: onSortChange,
    );
  }
}

List<SortHeaderItemData<InProgressListSortType>> _headerItems = [
  SortHeaderItemData<InProgressListSortType>(
    text: LocaleKeys.status.tr(),
    value: InProgressListSortType.status,
  ),
  SortHeaderItemData<InProgressListSortType>(
    text: LocaleKeys.send.tr(),
    value: InProgressListSortType.send,
  ),
  SortHeaderItemData<InProgressListSortType>(
    text: LocaleKeys.receive.tr(),
    value: InProgressListSortType.receive,
  ),
  SortHeaderItemData<InProgressListSortType>(
    text: LocaleKeys.price.tr(),
    value: InProgressListSortType.price,
  ),
  SortHeaderItemData<InProgressListSortType>(
    text: LocaleKeys.date.tr(),
    value: InProgressListSortType.date,
  ),
  SortHeaderItemData<InProgressListSortType>(
    flex: 0,
    text: LocaleKeys.orderType.tr(),
    value: InProgressListSortType.orderType,
  ),
];

enum InProgressListSortType {
  status,
  send,
  receive,
  price,
  date,
  orderType,
  none,
}
