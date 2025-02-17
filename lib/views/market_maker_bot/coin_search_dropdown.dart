import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/widgets/coin_icon.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item_body.dart';
import 'package:web_dex/views/dex/simple/form/tables/orders_table/grouped_list_view.dart';

class CoinSelectItem {
  CoinSelectItem({
    required this.name,
    required this.coinId,
    required this.coinProtocol,
    this.leading,
    this.trailing,
    this.title,
  });

  final String name;
  final String coinId;
  final String coinProtocol;

  /// The widget to display on the right side of the list item.
  ///
  /// E.g. to show balance or price increase percentage.
  ///
  /// If null, nothing will be displayed.
  final Widget? trailing;

  /// The widget to display on the left side of the list item.
  ///
  /// E.g. to show the coin icon.
  ///
  /// If null, the CoinIcon will be displayed with a size of 20.
  final Widget? leading;

  /// The widget to display the title of the list item.
  ///
  /// If null, the [name] will be displayed.
  final Widget? title;
}

bool doesCoinMatchSearch(String searchQuery, CoinSelectItem item) {
  final lowerCaseQuery = searchQuery.toLowerCase();
  final nameContains = item.name.toLowerCase().contains(lowerCaseQuery);
  final idMatches = item.coinId.toLowerCase().contains(lowerCaseQuery);
  final protocolMatches =
      item.coinProtocol.toLowerCase().contains(lowerCaseQuery);

  return nameContains || idMatches || protocolMatches;
}

class CryptoSearchDelegate extends SearchDelegate<CoinSelectItem?> {
  CryptoSearchDelegate(this.items);

  final Iterable<CoinSelectItem> items;

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

  @override
  Widget buildResults(BuildContext context) {
    final results =
        items.where((item) => doesCoinMatchSearch(query, item)).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          leading: item.leading ?? CoinIcon(item.coinId),
          title: item.title ?? Text(item.name),
          trailing: item.trailing,
          onTap: () => close(context, item),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions =
        items.where((item) => doesCoinMatchSearch(query, item)).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final item = suggestions[index];
        return ListTile(
          leading: item.leading ?? CoinIcon(item.coinId),
          title: item.title ?? Text(item.name),
          trailing: item.trailing,
          onTap: () => query = item.name,
        );
      },
    );
  }
}

Future<CoinSelectItem?> showCoinSearch(
  BuildContext context, {
  required List<String> coins,

  /// The builder function to create a custom list item
  CoinSelectItem Function(String coinId)? customCoinItemBuilder,
  double maxHeight = 330,
}) async {
  final isMobile = MediaQuery.of(context).size.width < 600;

  final items = coins.map(
    (coin) =>
        customCoinItemBuilder?.call(coin) ?? _defaultCoinItemBuilder(coin),
  );

  if (isMobile) {
    return await showSearch<CoinSelectItem?>(
      context: context,
      delegate: CryptoSearchDelegate(items),
    );
  } else {
    return await showDropdownSearch(context, items, maxHeight: maxHeight);
  }
}

CoinSelectItem _defaultCoinItemBuilder(String coin) {
  return CoinSelectItem(
    name: coin,
    coinId: coin,
    coinProtocol: coin,
    leading: CoinIcon(coin),
  );
}

OverlayEntry? _overlayEntry;
Completer<CoinSelectItem?>? _completer;

Future<CoinSelectItem?> showDropdownSearch(
  BuildContext context,
  Iterable<CoinSelectItem> items, {
  double maxHeight = 330,
}) async {
  final renderBox = context.findRenderObject() as RenderBox;
  final offset = renderBox.localToGlobal(Offset.zero);

  void clearOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _completer = null;
  }

  void onItemSelected(CoinSelectItem? item) {
    _completer?.complete(item);
    clearOverlay();
  }

  clearOverlay();

  _completer = Completer<CoinSelectItem?>();
  _overlayEntry = OverlayEntry(
    builder: (context) {
      return GestureDetector(
        onTap: () => onItemSelected(null),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy + renderBox.size.height,
              width: renderBox.size.width,
              child: _DropdownSearch(
                items: items,
                onSelected: onItemSelected,
                maxHeight: maxHeight,
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

  return _completer!.future;
}

class _DropdownSearch extends StatefulWidget {
  final Iterable<CoinSelectItem> items;
  final ValueChanged<CoinSelectItem?> onSelected;
  final double maxHeight;

  const _DropdownSearch({
    required this.items,
    required this.onSelected,
    this.maxHeight = 300,
  });

  @override
  State<_DropdownSearch> createState() => __DropdownSearchState();
}

class __DropdownSearchState extends State<_DropdownSearch> {
  late Iterable<CoinSelectItem> filteredItems;
  String query = '';
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    filteredItems = widget.items;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void updateSearchQuery(String newQuery) {
    setState(() {
      query = newQuery;
      filteredItems = widget.items.where(
        (item) => doesCoinMatchSearch(query, item),
      );
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              focusNode: _focusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: updateSearchQuery,
            ),
          ),
          filteredItems.isNotEmpty
              ? GroupedListView<CoinSelectItem>(
                  items: filteredItems.toList(),
                  onSelect: widget.onSelected,
                  maxHeight: widget.maxHeight,
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(LocaleKeys.nothingFound.tr()),
                ),
        ],
      ),
    );
  }
}

class CoinDropdown extends StatefulWidget {
  final List<CoinSelectItem> items;
  final Widget? child;
  final Function(CoinSelectItem) onItemSelected;

  const CoinDropdown({
    super.key,
    required this.items,
    required this.onItemSelected,
    this.child,
  });

  @override
  State<CoinDropdown> createState() => _CoinDropdownState();
}

class _CoinDropdownState extends State<CoinDropdown> {
  CoinSelectItem? selectedItem;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _showSearch(BuildContext context) async {
    _overlayEntry = _createOverlayEntry(context);
    Overlay.of(context).insert(_overlayEntry!);
  }

  OverlayEntry _createOverlayEntry(BuildContext context) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    final screenSize = MediaQuery.of(context).size;
    final availableHeightBelow = screenSize.height - offset.dy - size.height;
    final availableHeightAbove = offset.dy;

    final showAbove = availableHeightBelow < widget.items.length * 48 &&
        availableHeightAbove > availableHeightBelow;

    final dropdownHeight =
        (showAbove ? availableHeightAbove : availableHeightBelow)
            .clamp(100.0, 330.0);

    return OverlayEntry(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            _overlayEntry?.remove();
            _overlayEntry = null;
          },
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              Positioned(
                width: size.width,
                left: offset.dx,
                top: showAbove
                    ? offset.dy - dropdownHeight
                    : offset.dy + size.height,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(0.0, showAbove ? -size.height : 0.0),
                  child: Material(
                    elevation: 4.0,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: dropdownHeight,
                      ),
                      child: _DropdownSearch(
                        items: widget.items,
                        onSelected: (selected) {
                          if (selected == null) return;
                          setState(() {
                            selectedItem = selected;
                            _overlayEntry?.remove();
                            _overlayEntry = null;
                          });
                          widget.onItemSelected(selected);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
    final coin = selectedItem == null
        ? null
        : coinsRepository.getCoin(selectedItem!.coinId);

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: () => _showSearch(context),
        child: widget.child ??
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: CoinItemBody(coin: coin),
            ),
      ),
    );
  }
}

// Example usage

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final items = [
//       CoinSelectItem(
//         name: "KMD",
//         symbol: "KMD",
//         changePercent: 2.9,
//         trailing: const Text('+2.9%', style: TextStyle(color: Colors.green)),
//       ),
//       CoinSelectItem(
//         name: "SecondLive",
//         symbol: "SL",
//         changePercent: 322.9,
//         trailing: const Text('+322.9%', style: TextStyle(color: Colors.green)),
//       ),
//       CoinSelectItem(
//         name: "KiloEx",
//         symbol: "KE",
//         changePercent: -2.09,
//         trailing: const Text('-2.09%', style: TextStyle(color: Colors.red)),
//       ),
//       CoinSelectItem(
//         name: "Native",
//         symbol: "NT",
//         changePercent: 225.9,
//         trailing: const Text('+225.9%', style: TextStyle(color: Colors.green)),
//       ),
//       CoinSelectItem(
//         name: "XY Finance",
//         symbol: "XY",
//         changePercent: 62.9,
//         trailing: const Text('+62.9%', style: TextStyle(color: Colors.green)),
//       ),
//       CoinSelectItem(
//         name: "KMD",
//         symbol: "KMD",
//         changePercent: 2.9,
//         trailing: const Text('+2.9%', style: TextStyle(color: Colors.green)),
//       ),
//     ];

//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: const Text('Crypto Selector')),
//         body: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: CoinDropdown(
//             items: items,
//             onItemSelected: (item) {
//               // Handle item selection
//               print('Selected item: ${item.name}');
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
