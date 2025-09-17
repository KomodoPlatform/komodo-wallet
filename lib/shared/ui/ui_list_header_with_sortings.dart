import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class UiListHeaderWithSorting<T> extends StatelessWidget {
  const UiListHeaderWithSorting({
    Key? key,
    required this.items,
    required this.sortData,
    required this.onSortChange,
  }) : super(key: key);
  final List<SortHeaderItemData> items;
  final SortData<T> sortData;

  final void Function(SortData<T>) onSortChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 1, color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: items
            .map(
              (item) => Expanded(
                flex: item.flex,
                child: item.isEmpty
                    ? SizedBox(width: item.width)
                    : SizedBox(
                        width: item.width,
                        child: UiSortListButton<T>(
                          text: item.text,
                          value: item.value,
                          sortData: sortData,
                          onClick: onSortChange,
                        ),
                      ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class SortHeaderItemData<T> {
  SortHeaderItemData({
    required this.text,
    required this.value,
    this.flex = 1,
    this.isEmpty = false,
    this.width,
  });

  final String text;
  final T value;
  final int flex;
  final bool isEmpty;
  final double? width;
}
