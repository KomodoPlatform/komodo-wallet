import 'package:flutter/material.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:komodo_ui_kit/src/images/coin_icon.dart';

/// A specialized version of [SearchableSelect] for cryptocurrency selection.
class CoinSelect extends StatelessWidget {
  const CoinSelect({
    super.key,
    required this.coins,
    required this.onCoinSelected,
    this.customCoinItemBuilder,
    this.initialCoin,
    this.controller,
  });

  /// List of coin IDs to show in the selector
  final List<String> coins;

  /// Callback when a coin is selected
  final Function(String coinId) onCoinSelected;

  /// Optional custom builder for coin items
  final SelectItem<String> Function(String coinId)? customCoinItemBuilder;

  /// Optional initial selected coin
  final String? initialCoin;

  /// Optional controller for external state management
  final SearchableSelectController<String>? controller;

  SelectItem<String> _defaultCoinItemBuilder(String coin) {
    return SelectItem<String>(
      id: coin,
      title: coin,
      value: coin,
      leading: CoinIcon.ofSymbol(coin),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = coins
        .map(
          (coin) =>
              customCoinItemBuilder?.call(coin) ??
              _defaultCoinItemBuilder(coin),
        )
        .toList();

    // Find initial value if provided
    final initialValue = initialCoin != null
        ? items.firstWhere(
            (item) => item.value == initialCoin,
            orElse: () => items.first,
          )
        : null;

    return SearchableSelect<String>(
      items: items,
      onItemSelected: (item) => onCoinSelected(item.value),
      hint: 'Select a coin',
      initialValue: initialValue?.value,
      controller: controller,
    );
  }
}
