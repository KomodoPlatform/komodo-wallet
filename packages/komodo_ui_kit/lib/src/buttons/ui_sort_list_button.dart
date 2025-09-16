import 'package:flutter/material.dart';

class UiSortListButton<T> extends StatelessWidget {
  const UiSortListButton({
    required this.value,
    required this.sortData,
    required this.text,
    required this.onClick,
    this.iconWidth = 14,
    this.iconHeight = 6,
    super.key,
  });
  final String text;
  final T value;
  final SortData<T> sortData;
  final void Function(SortData<T>) onClick;
  final double iconWidth;
  final double iconHeight;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w500);
    return InkWell(
      onTap: _onClick,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: textStyle),
          SortListIcon<T>(
            currentSortData: sortData,
            iconWidth: iconWidth,
            iconHeight: iconHeight,
            sortType: value,
          ),
        ],
      ),
    );
  }

  void _onClick() {
    if (sortData.sortType != value) {
      onClick(
        SortData<T>(
          sortType: value,
          sortDirection: SortDirection.increase,
        ),
      );
      return;
    }

    switch (sortData.sortDirection) {
      case SortDirection.decrease:
        onClick(
          SortData<T>(
            sortType: value,
            sortDirection: SortDirection.none,
          ),
        );
        return;
      case SortDirection.increase:
        onClick(
          SortData<T>(
            sortType: value,
            sortDirection: SortDirection.decrease,
          ),
        );
        return;
      case SortDirection.none:
        onClick(
          SortData<T>(sortType: value, sortDirection: SortDirection.increase),
        );
        return;
    }
  }
}

class SortListIcon<T> extends StatelessWidget {
  const SortListIcon({
    required this.currentSortData,
    required this.iconWidth,
    required this.iconHeight,
    required this.sortType,
    super.key,
  });

  final SortData<T> currentSortData;
  final double iconWidth;
  final double iconHeight;
  final T sortType;

  @override
  Widget build(BuildContext context) {
    final buttonSortDirection = currentSortData.sortType == sortType
        ? currentSortData.sortDirection
        : SortDirection.none;

    if (currentSortData.sortType != sortType) {
      return SortListIconItem(
        sortDirection: buttonSortDirection,
        iconWidth: iconWidth,
        iconHeight: iconHeight,
      );
    }
    final color = currentSortData.sortDirection != SortDirection.none
        ? Theme.of(context).colorScheme.primary
        : null;
    return SortListIconItem(
      sortDirection: buttonSortDirection,
      iconWidth: iconWidth,
      iconHeight: iconHeight,
      iconColor: color,
    );
  }
}

class SortListIconItem extends StatelessWidget {
  const SortListIconItem({
    required this.sortDirection,
    required this.iconWidth,
    required this.iconHeight,
    this.iconColor,
    super.key,
  });
  final double iconWidth;
  final double iconHeight;
  final Color? iconColor;
  final SortDirection sortDirection;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        children: [
          if (sortDirection != SortDirection.decrease)
            Container(
              width: iconWidth,
              height: iconHeight,
              constraints: const BoxConstraints(),
              child: Icon(
                Icons.arrow_drop_up,
                color: iconColor ?? Colors.grey[300],
                size: iconWidth,
              ),
            ),
          if (sortDirection != SortDirection.increase)
            Container(
              width: iconWidth,
              height: iconHeight,
              constraints: const BoxConstraints(),
              child: Icon(
                Icons.arrow_drop_down,
                color: iconColor ?? Colors.grey[300],
                size: iconWidth,
              ),
            ),
          SizedBox(height: iconHeight),
        ],
      ),
    );
  }
}

enum SortDirection {
  increase,
  decrease,
  none,
}

class SortData<T> {
  const SortData({
    required this.sortDirection,
    required this.sortType,
  });
  final T sortType;
  final SortDirection sortDirection;
}
