import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/src/buttons/multiselect_dropdown/filter_container.dart';
import 'package:komodo_ui_kit/src/buttons/ui_dropdown.dart';

class MultiSelectDropdownButton<T> extends StatefulWidget {
  final String title;
  final List<T>? items;
  final ValueChanged<List<T>>? onChanged;
  final List<T>? selectedItems;
  final Widget? icon;
  final BorderRadius? borderRadius;
  final TextStyle? style;
  final String Function(T) displayItem;
  final UIChipColorScheme colorScheme;

  const MultiSelectDropdownButton({
    required this.title,
    required this.items,
    required this.onChanged,
    this.selectedItems,
    this.icon,
    this.borderRadius,
    super.key,
    this.style,
    required this.displayItem,
    required this.colorScheme,
  });

  @override
  State<MultiSelectDropdownButton<T>> createState() =>
      _MultiSelectDropdownButtonState<T>();
}

class _MultiSelectDropdownButtonState<T>
    extends State<MultiSelectDropdownButton<T>> {
  final List<int> _selectedIndexes = [];
  UIChipState state = UIChipState.empty;

  TextStyle get _textStyle =>
      widget.style ??
      Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.secondary) ??
      TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.secondary,
        fontWeight: FontWeight.w500,
      );

  @override
  void initState() {
    _updateSelectedIndexes();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant MultiSelectDropdownButton<T> oldWidget) {
    _updateSelectedIndexes();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    _updateSelectedIndexes();
    super.didChangeDependencies();
  }

  void _updateSelectedIndexes() {
    if (widget.items == null ||
        widget.items!.isEmpty ||
        (widget.selectedItems == null &&
            widget.items!
                .where(
                  (T item) => widget.selectedItems?.contains(item) ?? false,
                )
                .isEmpty)) {
      _updateButtonState(false);
      return;
    }

    if (widget.selectedItems?.isEmpty ?? false) {
      _selectedIndexes.clear();
      _updateButtonState(false);
      return;
    }
    for (int itemIndex = 0; itemIndex < widget.items!.length; itemIndex++) {
      if (widget.selectedItems!
          .contains(widget.items![itemIndex] == widget.selectedItems)) {
        _selectedIndexes.add(itemIndex);
      }
    }
    _updateButtonState(false);
    return;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items!;
    return UiDropdown(
      borderRadius: BorderRadius.circular(16),
      dropdown: _MultiselectDropdownContainer(
        items: [
          for (int index = 0; index < items.length; index += 1)
            _MultiSelectDropdownItem<T>(
              title: widget.displayItem(items[index]),
              index: index,
              isSelected: _selectedIndexes.contains(index),
              onChange: (isShown, value) {
                if (isShown!) {
                  _selectedIndexes.add(value);
                } else {
                  _selectedIndexes.remove(value);
                }
                if (widget.onChanged != null) {
                  widget.onChanged!(
                    _selectedIndexes.map((e) => items[e]).toList(),
                  );
                }
              },
              textStyle: _textStyle,
            ),
        ],
        backgroundColor: widget.colorScheme.emptyContainerColor,
      ),
      switcher: UIChip(
        title: widget.title,
        status: state,
        colorScheme: widget.colorScheme,
      ),
      onSwitch: _updateButtonState,
    );
  }

  void _updateButtonState(bool isOpened) {
    setState(() {
      if (isOpened) {
        state = UIChipState.pressed;
      } else {
        if (_selectedIndexes.isEmpty) {
          state = UIChipState.empty;
        } else {
          state = UIChipState.selected;
        }
      }
    });
  }
}

class _MultiSelectDropdownItem<T> extends StatefulWidget {
  final bool isSelected;
  final void Function(bool?, int) onChange;
  final String title;
  final int index;
  final TextStyle textStyle;

  const _MultiSelectDropdownItem({
    super.key,
    required this.isSelected,
    required this.onChange,
    required this.title,
    required this.index,
    required this.textStyle,
  });

  @override
  State<_MultiSelectDropdownItem<T>> createState() =>
      _MultiSelectDropdownItemState<T>();
}

class _MultiSelectDropdownItemState<T>
    extends State<_MultiSelectDropdownItem<T>> {
  bool isSelected = false;
  @override
  void initState() {
    isSelected = widget.isSelected;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      key: Key('filter-chain-${widget.title}'),
      children: [
        Container(
          child: Transform.scale(
            scale: 0.7,
            child: Checkbox(
              value: isSelected,
              splashRadius: 18,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: (bool? choosed) {
                onChange(choosed ?? false);
              },
            ),
          ),
        ),
        Text(
          widget.title,
          style: widget.textStyle,
        ),
      ],
    );
  }

  void onChange(bool choosed) {
    setState(() {
      isSelected = !isSelected;
    });
    widget.onChange(choosed, widget.index);
  }
}

class _MultiselectDropdownContainer<T> extends StatelessWidget {
  final Color? backgroundColor;
  final List<_MultiSelectDropdownItem<T>> items;
  const _MultiselectDropdownContainer({
    Key? key,
    required this.backgroundColor,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: backgroundColor,
        ),
        padding: const EdgeInsets.fromLTRB(5, 4, 12, 4),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items,
          ),
        ),
      ),
    );
  }
}
