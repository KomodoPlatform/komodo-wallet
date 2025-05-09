import 'package:flutter/material.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

class SelectedCoinGraphControl extends StatelessWidget {
  const SelectedCoinGraphControl({
    required this.centreAmount,
    required this.percentageIncrease,
    this.onCoinSelected,
    this.emptySelectAllowed = true,
    this.selectedCoinId,
    this.availableCoins,
    this.customCoinItemBuilder,
    this.forceDropdown = false,
    super.key,
  });
  final bool forceDropdown;
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
        return forceDropdown
            ? _buildDropdownButton(context)
            : _buildSegmentedButton(context);
      },
    );
  }

  Widget _buildSegmentedButton(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 230),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedCoinId != null) ...[
                    AssetIcon.ofTicker(selectedCoinId!, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      selectedCoinId!,
                      style: Theme.of(context).textTheme.bodyLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (emptySelectAllowed) ...[
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
                  ] else
                    Text('All', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
              Text(
                (NumberFormat.currency(symbol: "\$")
                      ..minimumSignificantDigits = 3
                      ..minimumFractionDigits = 2)
                    .format(centreAmount),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TrendPercentageText(percentage: percentageIncrease),
                  if (onCoinSelected != null) ...[
                    const SizedBox(width: 2),
                    const Icon(Icons.expand_more),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownButton(BuildContext context) {
    return DropdownWithSearch(
      selectedId: selectedCoinId,
      availableCoins: availableCoins!,
      onCoinSelected: (String id) => onCoinSelected?.call(id),
      customCoinItemBuilder: customCoinItemBuilder,
      width: 230,
    );
  }
}

class DropdownWithSearch extends StatelessWidget {
  const DropdownWithSearch({
    super.key,
    required this.availableCoins,
    required this.onCoinSelected,
    this.selectedId,
    this.customCoinItemBuilder,
    this.hint = 'Select coin',
    this.width = 230,
  });

  final List<AssetId> availableCoins;
  final void Function(String) onCoinSelected;
  final String? selectedId;
  final DropdownMenuItem<AssetId> Function(AssetId)? customCoinItemBuilder;
  final String hint;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final segmentedStyle = theme.segmentedButtonTheme.style;

    final backgroundColor = segmentedStyle?.backgroundColor?.resolve({}) ??
        theme.colorScheme.surfaceContainerLowest;

    final foregroundColor = segmentedStyle?.foregroundColor?.resolve({}) ??
        theme.colorScheme.onSurfaceVariant;

    final borderColor = segmentedStyle?.side?.resolve({})?.color ??
        theme.colorScheme.outlineVariant;

    final shape = segmentedStyle?.shape?.resolve({});
    final BorderRadius borderRadius = switch (shape) {
      RoundedRectangleBorder(:final borderRadius)
          when borderRadius is BorderRadius =>
        borderRadius,
      _ => BorderRadius.circular(8),
    };

    final textStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: foregroundColor,
    );

    AssetId? selectedCoin;
    for (final coin in availableCoins) {
      if (coin.id == selectedId) {
        selectedCoin = coin;
        break;
      }
    }

    return UnconstrainedBox(
      constrainedAxis: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: () async {
            final selected = await showCoinSearch(
              context,
              coins: availableCoins,
              customCoinItemBuilder: customCoinItemBuilder,
            );
            if (selected != null) {
              onCoinSelected(selected.id);
            }
          },
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                if (selectedCoin != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: AssetIcon(selectedCoin, size: 18),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      selectedCoin.id,
                      style: textStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Text(
                      hint,
                      style: textStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                Icon(Icons.keyboard_arrow_down, color: foregroundColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
