import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Controller for managing selection state
class SearchableSelectController<T> extends ChangeNotifier {
  T? _value;

  T? get value => _value;

  void select(T? value) {
    if (_value != value) {
      _value = value;
      notifyListeners();
    }
  }

  void clear() {
    select(null);
  }
}

/// Widget that displays a searchable select input
class SearchableSelect<T> extends StatefulWidget {
  const SearchableSelect({
    required this.items,
    required this.onChanged,
    super.key,
    this.value,
    this.hint,
    this.selectedItemBuilder,
    this.decoration,
    this.controller,
    this.forceDropdown = false,
    this.isExpanded = true,
    this.validator,
    this.autovalidateMode,
    this.focusNode,
  });

  /// The list of items the user can select from
  final List<DropdownMenuItem<T>> items;

  /// Called when the user selects an item
  final ValueChanged<T?>? onChanged;

  /// The currently selected value
  final T? value;

  /// Text that describes the search field
  final String? hint;

  /// A builder to customize the selected item appearance
  final SelectedItemBuilder<T>? selectedItemBuilder;

  /// Decoration for the search input field
  final InputDecoration? decoration;

  /// Optional controller for programmatic control
  final SearchableSelectController<T>? controller;

  /// Forces dropdown mode even on mobile
  final bool forceDropdown;

  /// Whether the button should expand to fill its parent
  final bool isExpanded;

  /// Optional validator function for form integration
  final FormFieldValidator<T>? validator;

  /// Auto validation mode for form integration
  final AutovalidateMode? autovalidateMode;

  /// Focus node for managing focus
  final FocusNode? focusNode;

  @override
  State<SearchableSelect<T>> createState() => _SearchableSelectState<T>();
}

typedef SelectedItemBuilder<T> =
    Widget? Function(BuildContext context, T? selectedItem);

class _SearchableSelectState<T> extends State<SearchableSelect<T>> {
  T? _selectedValue;
  late final SearchableSelectController<T> _controller;
  bool _isControllerInternal = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _initializeController();
    _initializeSelection();
  }

  void _initializeController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _isControllerInternal = true;
      _controller = SearchableSelectController<T>();
    }
    _controller.addListener(_onControllerChange);
  }

  void _initializeSelection() {
    if (widget.value != null) {
      _selectedValue = widget.value;
      _controller.select(_selectedValue);
    } else if (_controller.value != null) {
      _selectedValue = _controller.value;
    }
  }

  void _onControllerChange() {
    if (mounted) {
      setState(() {
        _selectedValue = _controller.value;
      });
    }
  }

  @override
  void didUpdateWidget(SearchableSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChange);
      _initializeController();
    }

    if (oldWidget.value != widget.value && widget.value != null) {
      _initializeSelection();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    if (_isControllerInternal) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _showSearch(BuildContext context) async {
    final selected = await showSearchableSelect<T>(
      context: context,
      items: widget.items,
      searchHint: widget.hint ?? 'Search',
      isMobile: widget.forceDropdown ? false : null,
    );

    if (selected != null) {
      setState(() {
        _selectedValue = selected;
      });
      _controller.select(selected);
      widget.onChanged?.call(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use FormField for validation support
    return FormField<T>(
      initialValue: _selectedValue,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      builder: (FormFieldState<T> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Focus(
              focusNode: _focusNode,
              onFocusChange: (hasFocus) {
                if (hasFocus) {
                  _showSearch(context);
                }
              },
              child: SearchableSelectView(
                selectedItem: _selectedValue,
                hint: widget.hint,
                onTap: () => _showSearch(context),
                selectedItemBuilder: widget.selectedItemBuilder,
                decoration: widget.decoration,
                isExpanded: widget.isExpanded,
                hasError: field.hasError,
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  field.errorText ?? '',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Presentation widget for the searchable select
class SearchableSelectView<T> extends StatelessWidget {
  const SearchableSelectView({
    required this.selectedItem,
    required this.onTap,
    super.key,
    this.hint,
    this.selectedItemBuilder,
    this.decoration,
    this.isExpanded = true,
    this.hasError = false,
  });

  final T? selectedItem;
  final VoidCallback onTap;
  final String? hint;
  final SelectedItemBuilder<T>? selectedItemBuilder;
  final InputDecoration? decoration;
  final bool isExpanded;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        width: isExpanded ? double.infinity : null,
        decoration: BoxDecoration(
          border: Border.all(
            color:
                hasError
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface.withOpacity(0.1),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InputDecorator(
          decoration:
              decoration ??
              InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: theme.textTheme.bodyLarge?.fontSize,
                ),
                errorStyle:
                    hasError
                        ? TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 12,
                        )
                        : null,
                errorBorder:
                    hasError
                        ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: theme.colorScheme.error,
                          ),
                        )
                        : null,
              ),
          isEmpty: selectedItem == null,
          child:
              selectedItem == null
                  ? null
                  : selectedItemBuilder?.call(context, selectedItem) ??
                      DefaultSelectedItemView(item: selectedItem),
        ),
      ),
    );
  }
}

/// Default view for selected items
class DefaultSelectedItemView extends StatelessWidget {
  const DefaultSelectedItemView({required this.item, super.key});

  final dynamic item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (item is DropdownMenuItem) {
      final dropdownItem = item as DropdownMenuItem;
      if (dropdownItem.child is Row) {
        return dropdownItem.child;
      } else {
        return Row(
          children: [
            Expanded(
              child: DefaultTextStyle(
                style: theme.textTheme.bodyLarge!.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                child: dropdownItem.child,
              ),
            ),
          ],
        );
      }
    }

    // Fallback for legacy support
    return Row(
      children: [
        Expanded(
          child: Text(
            item.toString(),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class SearchableSelectorDelegate<T> extends SearchDelegate<T?> {
  SearchableSelectorDelegate(
    this.items, {
    this.searchHint = 'Search',
    this.itemBuilder,
  });

  final List<DropdownMenuItem<T>> items;
  final String searchHint;
  final Widget Function(DropdownMenuItem<T> item, VoidCallback? onTap)?
  itemBuilder;

  @override
  String get searchFieldLabel => searchHint;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  String _getItemText(DropdownMenuItem<T> item) {
    if (item.child is Text) {
      return (item.child as Text).data ?? '';
    }
    return item.value?.toString() ?? '';
  }

  @override
  Widget buildResults(BuildContext context) {
    final results =
        items
            .where(
              (item) => _getItemText(
                item,
              ).toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];

        // Use the _DropdownItemWidget for consistent styling
        return itemBuilder?.call(item, () => close(context, item.value)) ??
            _DropdownItemWidget(
              item: item,
              onTap: () => close(context, item.value),
            );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}

// Custom widget to display dropdown items safely
class _DropdownItemWidget<T> extends StatelessWidget {
  const _DropdownItemWidget({required this.item, this.onTap});

  final DropdownMenuItem<T> item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputTheme = theme.inputDecorationTheme;

    final defaultTextStyle = theme.textTheme.bodyLarge?.copyWith(
      color: inputTheme.labelStyle?.color ?? theme.colorScheme.onSurface,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            inputTheme.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child:
            defaultTextStyle == null
                ? item.child
                : DefaultTextStyle(style: defaultTextStyle, child: item.child),
      ),
    );
  }
}

Future<T?> showSearchableSelect<T>({
  required BuildContext context,
  required List<DropdownMenuItem<T>> items,
  String searchHint = 'Search',
  bool? isMobile,
}) async {
  isMobile ??= MediaQuery.of(context).size.width < 600;

  if (isMobile) {
    return showSearch<T?>(
      context: context,
      delegate: SearchableSelectorDelegate(items, searchHint: searchHint),
    );
  } else {
    return showDropdownSearch(
      context,
      items,
      searchHint: searchHint,
      minWidth: 300,
    );
  }
}

OverlayEntry? _overlayEntry;
Completer<dynamic>? _completer;

Future<T?> showDropdownSearch<T>(
  BuildContext context,
  List<DropdownMenuItem<T>> items, {
  String searchHint = 'Search',
  double? minWidth,
}) async {
  final renderBox = context.findRenderObject()! as RenderBox;
  final offset = renderBox.localToGlobal(Offset.zero);
  final screenHeight = MediaQuery.of(context).size.height;

  // Check if there's enough space below
  final spaceBelow = screenHeight - offset.dy - renderBox.size.height;
  final requiredSpace = math.min(
    300,
    items.length * 56.0 + 60.0,
  ); // estimate height
  final showAbove = spaceBelow < requiredSpace && offset.dy > spaceBelow;

  void clearOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _completer = null;
  }

  void onItemSelected(T? value) {
    _completer?.complete(value);
    clearOverlay();
  }

  clearOverlay();

  _completer = Completer<T?>();
  _overlayEntry = OverlayEntry(
    builder: (context) {
      // Calculate width based on minWidth parameter if provided
      final dropdownWidth =
          minWidth != null
              ? math.max(renderBox.size.width, minWidth)
              : renderBox.size.width;

      return GestureDetector(
        onTap: () => onItemSelected(null),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              left: offset.dx,
              // Position above or below based on available space
              top:
                  showAbove
                      ? offset.dy - requiredSpace
                      : offset.dy + renderBox.size.height,
              width: dropdownWidth,
              child: _SearchOverlay(
                items: items,
                onSelected: onItemSelected,
                searchHint: searchHint,
              ),
            ),
          ],
        ),
      );
    },
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    Overlay.of(context).insert(_overlayEntry!);
  });

  return _completer!.future as Future<T?>;
}

class _SearchOverlay<T> extends StatefulWidget {
  const _SearchOverlay({
    required this.items,
    required this.onSelected,
    this.searchHint = 'Search',
  });

  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onSelected;
  final String searchHint;

  @override
  State<_SearchOverlay<T>> createState() => _SearchOverlayState<T>();
}

class _SearchOverlayState<T> extends State<_SearchOverlay<T>> {
  late List<DropdownMenuItem<T>> filteredItems;
  String query = '';
  final FocusNode _focusNode = FocusNode();
  int _focusedIndex = -1;

  @override
  void initState() {
    super.initState();
    filteredItems = widget.items;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void updateSearchQuery(String newQuery) {
    setState(() {
      query = newQuery;
      filteredItems =
          widget.items
              .where(
                (item) => _getItemText(
                  item,
                ).toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
      // Reset focus when items change
      _focusedIndex = filteredItems.isNotEmpty ? 0 : -1;
    });
  }

  String _getItemText(DropdownMenuItem<T> item) {
    if (item.child is Text) {
      return (item.child as Text).data ?? '';
    }
    return item.value?.toString() ?? '';
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (filteredItems.isEmpty) return;

    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _focusedIndex = (_focusedIndex + 1) % filteredItems.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _focusedIndex =
              _focusedIndex <= 0 ? filteredItems.length - 1 : _focusedIndex - 1;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        if (_focusedIndex >= 0 && _focusedIndex < filteredItems.length) {
          widget.onSelected?.call(filteredItems[_focusedIndex].value);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        widget.onSelected?.call(null);
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputTheme = theme.inputDecorationTheme;

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyPress,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: theme.colorScheme.surface,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextFormField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: Icon(
                      Icons.search,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border:
                        inputTheme.border ??
                        defaultSearchableSelectTheme(
                          theme.brightness,
                          theme.colorScheme,
                        ).border,
                    // Use input theme colors for consistency
                    fillColor: inputTheme.fillColor,
                    filled: inputTheme.filled,
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: theme.textTheme.bodyLarge?.fontSize,
                    ),
                    contentPadding: inputTheme.contentPadding,
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  onChanged: updateSearchQuery,
                ),
              ),
              Flexible(
                child: ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final isSelected = index == _focusedIndex;

                    final itemWidget = _DropdownItemWidget(
                      item: item,
                      onTap: () => widget.onSelected?.call(item.value),
                    );

                    if (isSelected) {
                      return ColoredBox(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        child: itemWidget,
                      );
                    }

                    return itemWidget;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The recommended theme for the [SearchableSelect] widget.
///
/// NB! This is not applied automatically, and is only a suggestion. You need
/// to apply it to your theme.
InputDecorationTheme defaultSearchableSelectTheme(
  Brightness themeMode,
  ColorScheme colorScheme,
) {
  final isDark = themeMode == Brightness.dark;
  final surfaceColor = isDark ? Colors.grey[900] : Colors.grey[50];
  final borderColor =
      isDark
          ? colorScheme.onSurface.withOpacity(0.1)
          : colorScheme.outline.withOpacity(0.2);

  return InputDecorationTheme(
    filled: true,
    fillColor: surfaceColor?.withOpacity(0.5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}

/// A widget that displays a select item with the same parameters as SelectItem
class SelectItemWidget extends StatelessWidget {
  const SelectItemWidget({
    required this.id,
    required this.value,
    required this.title,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String id;
  final String value;
  final Widget title;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: DefaultTextStyle(
              style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              child: title,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

/// A model class representing a selectable item
class SelectItem {
  const SelectItem({
    required this.id,
    required this.value,
    required this.title,
    this.leading,
    this.trailing,
  });

  final String id;
  final String value;
  final Widget title;
  final Widget? leading;
  final Widget? trailing;
}
