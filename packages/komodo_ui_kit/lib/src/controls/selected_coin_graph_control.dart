import 'package:flutter/material.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui_kit/src/images/coin_icon.dart';

class SelectedCoinGraphControl extends StatelessWidget {
  const SelectedCoinGraphControl({
    required this.centreAmount,
    required this.percentageIncrease,
    this.onCoinSelected,
    this.emptySelectAllowed = true,
    this.selectedCoinId,
    this.availableCoins,
    this.customCoinItemBuilder,
    super.key,
  });

  final Function(String?)? onCoinSelected;
  final bool emptySelectAllowed;
  final String? selectedCoinId;
  final double centreAmount;
  final double percentageIncrease;

  /// A list of coin IDs that are available for selection.
  ///
  /// Must be non-null and not empty if [onCoinSelected] is non-null.
  final List<AssetId>? availableCoins;

  final DropdownMenuItem<AssetId> Function(AssetId)? customCoinItemBuilder;

  @override
  Widget build(BuildContext context) {
    // assert(onCoinSelected != null || emptySelectAllowed);

    // If onCoinSelected is non-null, then availableCoins must be non-null
    assert(
      onCoinSelected == null || availableCoins != null,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 280) {
          return _buildSegmentedButton(context);
        } else {
          return _buildDropdownButton(context);
        }
      },
    );
  }

  Widget _buildSegmentedButton(BuildContext context) {
    return SizedBox(
      height: 40,
      child: DividedButton(
        onPressed: onCoinSelected == null
            ? null
            : () async {
                final selectedCoin = await showCoinSearch(
                  context,
                  coins: availableCoins!,
                  customCoinItemBuilder: customCoinItemBuilder,
                );
                if (selectedCoin != null) {
                  onCoinSelected?.call(selectedCoin.id);
                }
              },
        children: [
          Container(
            // Min width of 48
            constraints: const BoxConstraints(minWidth: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),

            child: selectedCoinId != null
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CoinIcon(selectedCoinId!, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        selectedCoinId!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (emptySelectAllowed && selectedCoinId != null) ...[
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 16,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.clear),
                            iconSize: 16,
                            splashRadius: 20,
                            onPressed: () => onCoinSelected?.call(null),
                          ),
                        ),
                      ],
                    ],
                  )
                : Text('All', style: Theme.of(context).textTheme.bodyLarge),
          ),
          Text(
            (NumberFormat.currency(symbol: "\$")
                  ..minimumSignificantDigits = 3
                  ..minimumFractionDigits = 2)
                .format(centreAmount),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  // TODO: Incorporate into theme and remove duplication accross charts
                  fontWeight: FontWeight.w600,
                ),
          ),
          Row(
            children: [
              TrendPercentageText(
                percentage: percentageIncrease,
              ),
              if (onCoinSelected != null) ...[
                const SizedBox(width: 2),
                const Icon(Icons.expand_more),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownButton(BuildContext context) {
    final theme = Theme.of(context);
    final segmentedStyle = theme.segmentedButtonTheme.style;

    final backgroundColor = segmentedStyle?.backgroundColor?.resolve({}) ??
        theme.colorScheme.surfaceContainerLowest;

    final foregroundColor = segmentedStyle?.foregroundColor?.resolve({}) ??
        theme.colorScheme.onSurfaceVariant;

    final borderRadius =
        segmentedStyle?.shape?.resolve({}) is RoundedRectangleBorder
            ? (segmentedStyle!.shape!.resolve({}) as RoundedRectangleBorder)
                .borderRadius
            : BorderRadius.circular(8);

    final textStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: foregroundColor,
    );

    final validIds = availableCoins?.map((c) => c.id).toSet();
    final safeSelectedId =
        validIds?.contains(selectedCoinId) == true ? selectedCoinId : null;

    return SizedBox(
      width: 135,
      height: 40,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          border: Border.all(
            color: segmentedStyle?.side?.resolve({})?.color ??
                Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: DropdownButton<String>(
          value: safeSelectedId,
          onChanged: onCoinSelected,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          icon: Icon(Icons.keyboard_arrow_down, color: foregroundColor),
          style: textStyle,
          dropdownColor: backgroundColor,
          items: availableCoins?.map((coin) {
            return DropdownMenuItem<String>(
              value: coin.id,
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Row(
                  children: [
                    AssetIcon(coin, size: 18),
                    const SizedBox(width: 6),
                    Text(coin.id, style: textStyle),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
