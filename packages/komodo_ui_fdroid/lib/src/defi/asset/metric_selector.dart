import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';

/// Model representing metric data
typedef MetricData =
    ({double value, double trendPercentage, AssetId? selectedAsset});

extension MetricDataMethods on MetricData {
  MetricData copyWith({
    double? value,
    double? trendPercentage,
    ValueGetter<AssetId>? selectedAsset,
  }) {
    return (
      value: value ?? this.value,
      trendPercentage: trendPercentage ?? this.trendPercentage,
      selectedAsset:
          selectedAsset == null ? this.selectedAsset : selectedAsset.call(),
    );
  }
}

/// Controller for managing MetricSelector state
class MetricSelectorController extends ChangeNotifier {
  MetricSelectorController({
    required this.data,
    required this.availableAssets,
    this.allowEmptySelection = true,
  }) : _searchController = SearchableSelectController<AssetId>();

  final MetricData data;
  final List<AssetId> availableAssets;
  final bool allowEmptySelection;
  final SearchableSelectController<AssetId> _searchController;

  SearchableSelectController<AssetId> get searchController => _searchController;

  void selectAsset(AssetId? asset) {
    _searchController.select(asset);
    notifyListeners();
  }

  List<DropdownMenuItem<AssetId>> buildSelectItems({
    DropdownMenuItem<AssetId> Function(AssetId)? customItemBuilder,
  }) {
    return availableAssets
        .map(
          (id) =>
              customItemBuilder?.call(id) ??
              DropdownMenuItem<AssetId>(
                value: id,
                child: Row(
                  children: [
                    AssetIcon(id),
                    const SizedBox(width: 8),
                    Text(id.symbol.common),
                  ],
                ),
              ),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

/// A control widget that displays a selectable metric with a trend.
///
/// This is an enhanced version of the original SelectedCoinGraphControl that
/// maintains backwards compatibility while being more generic for other use
/// cases.
///
/// There may be breaking changes in the near future that enhance
/// re-usability and customization, but the initial version will be focused on
/// migrating from the Komodo Wallet app to the new SDK repository.
///
/// E.g.:
/// - Most constrained due to specific coin selection behavior
/// - Fixed 3-section layout
///
/// Could be improved with:
/// - Flexible section layout/ordering
/// - Custom selection mechanisms
/// - Different metric visualizations
/// - Better state management
/// - More flexible sizing
class MetricSelector extends StatelessWidget {
  /// A control widget that displays a selectable metric with a trend.
  const MetricSelector({
    required this.controller,
    this.customItemBuilder,
    this.emptySelectionLabel = 'All',
    this.onAssetSelected,
    super.key,
  });

  /// Controller managing selection and metric state
  final MetricSelectorController controller;

  /// Custom builder for search items
  final DropdownMenuItem<AssetId> Function(AssetId)? customItemBuilder;

  /// Label to show when nothing is selected
  final String emptySelectionLabel;

  /// Callback when an asset is selected
  final void Function(AssetId?)? onAssetSelected;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return SizedBox(
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: SearchableSelect<AssetId>(
                  controller: controller.searchController,
                  items: controller.buildSelectItems(
                    customItemBuilder: customItemBuilder,
                  ),
                  hint: emptySelectionLabel,
                  onChanged: (AssetId? assetId) {
                    if (assetId != null) {
                      onAssetSelected?.call(assetId);
                    }
                  },
                  selectedItemBuilder: (context, selectedAsset) {
                    // Return null if no asset is selected
                    if (selectedAsset == null) return null;

                    // Build a widget for the selected asset
                    return _buildAssetSelectionView(context, selectedAsset);
                  },
                ),
              ),
              const SizedBox(width: 12),
              _MetricValueText(value: controller.data.value),
              const SizedBox(width: 12),
              TrendPercentageText(percentage: controller.data.trendPercentage),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssetSelectionView(BuildContext context, AssetId assetId) {
    return Row(
      children: [
        AssetIcon(assetId),
        const SizedBox(width: 8),
        Text(assetId.symbol.common),
        if (controller.allowEmptySelection) ...[
          const SizedBox(width: 4),
          IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.clear),
            iconSize: 16,
            splashRadius: 20,
            onPressed: () {
              controller.selectAsset(null);
              onAssetSelected?.call(null);
            },
          ),
        ],
      ],
    );
  }
}

/// Widget for displaying formatted metric value
class _MetricValueText extends StatelessWidget {
  const _MetricValueText({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Text(
      (NumberFormat.currency(symbol: r'$')
            ..minimumSignificantDigits = 3
            ..minimumFractionDigits = 2)
          .format(value),
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
