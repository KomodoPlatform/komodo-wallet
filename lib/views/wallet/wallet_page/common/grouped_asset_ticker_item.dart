import 'dart:math' show min;

import 'package:app_theme/src/dark/theme_custom_dark.dart';
import 'package:app_theme/src/light/theme_custom_light.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/widgets/asset_item/asset_item.dart';
import 'package:web_dex/shared/widgets/asset_item/asset_item_size.dart';
import 'package:web_dex/views/wallet/coin_details/coin_details_info/charts/coin_sparkline.dart';

/// A widget that displays a group of assets sharing the same ticker symbol.
///
/// Shows the same layout as AssetListItemDesktop but adds an expansion button
/// to show related assets that share the same ticker symbol.
class GroupedAssetTickerItem extends StatefulWidget {
  const GroupedAssetTickerItem({
    super.key,
    required this.assets,
    required this.backgroundColor,
    required this.onTap,
    this.onStatisticsTap,
    this.expanded,
    this.isActivating = false,
  });

  final List<AssetId> assets;
  final Color backgroundColor;
  final void Function(AssetId)? onTap;
  final void Function(AssetId, Duration period)? onStatisticsTap;
  final bool? expanded;
  final bool isActivating;

  @override
  State<GroupedAssetTickerItem> createState() => _GroupedAssetTickerItemState();
}

class _GroupedAssetTickerItemState extends State<GroupedAssetTickerItem> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.expanded ?? false;
  }

  @override
  void didUpdateWidget(GroupedAssetTickerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded != null && widget.expanded != oldWidget.expanded) {
      setState(() {
        _isExpanded = widget.expanded!;
      });
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  AssetId get _primaryAsset => widget.assets.first;

  @override
  Widget build(BuildContext context) {
    // TODO: Refactor to reduce unnecessary bloc references and rebuilds.
    final price =
        context.watch<CoinsBloc>().state.getPriceForAsset(_primaryAsset);
    final priceFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    final theme = Theme.of(context);

    return Opacity(
      opacity: widget.isActivating ? 0.3 : 1,
      child: Material(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        color: widget.backgroundColor,
        clipBehavior: Clip.hardEdge,
        type: MaterialType.card,
        borderOnForeground: true,
        child: InkWell(
          onTap:
              widget.onTap == null ? null : () => widget.onTap!(_primaryAsset),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 3,
                      child: AssetItem(
                        assetId: _primaryAsset,
                        size: AssetItemSize.large,
                      ),
                    ),
                    if (!isMobile)
                      Expanded(
                        flex: 2,
                        child: BlocBuilder<CoinsBloc, CoinsState>(
                          builder: (context, state) {
                            final formattedPrice = price?.price != null
                                ? priceFormatter.format(price!.price)
                                : '';
                            return Text(
                              formattedPrice,
                              style: theme.textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                    Expanded(
                      flex: isMobile ? 4 : 2,
                      child: BlocBuilder<CoinsBloc, CoinsState>(
                        builder: (context, state) {
                          final change24hPercent =
                              state.get24hChangeForAsset(_primaryAsset);
                          return change24hPercent == null
                              ? const SizedBox.shrink()
                              : Tooltip(
                                  message: LocaleKeys.change24h.tr(),
                                  child: InkWell(
                                    onTap: () => widget.onStatisticsTap?.call(
                                      _primaryAsset,
                                      const Duration(days: 1),
                                    ),
                                    child: TrendPercentageText(
                                      percentage: change24hPercent,
                                      upColor: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Theme.of(context)
                                              .extension<ThemeCustomDark>()!
                                              .increaseColor
                                          : Theme.of(context)
                                              .extension<ThemeCustomLight>()!
                                              .increaseColor,
                                      downColor: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Theme.of(context)
                                              .extension<ThemeCustomDark>()!
                                              .decreaseColor
                                          : Theme.of(context)
                                              .extension<ThemeCustomLight>()!
                                              .decreaseColor,
                                      iconSize: 16,
                                      percentagePrecision: 2,
                                      value: isMobile ? price?.price : null,
                                      valueFormatter: (price?.price != null)
                                          ? (value) =>
                                              priceFormatter.format(value)
                                          : null,
                                    ),
                                  ),
                                );
                        },
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 130,
                          maxHeight: 35,
                        ),
                        child: InkWell(
                          onTap: () => widget.onStatisticsTap?.call(
                            _primaryAsset,
                            const Duration(days: 7),
                          ),
                          child: CoinSparkline(coinId: _primaryAsset.id),
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 48),
                      child: !(widget.assets.length > 1)
                          ? null
                          : IconButton(
                              iconSize: 32,
                              icon: Icon(
                                _isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: theme.colorScheme.secondary,
                              ),
                              onPressed: _toggleExpanded,
                              tooltip: _isExpanded
                                  ? 'Hide related assets'
                                  : 'Show related assets',
                            ),
                    ),
                  ],
                ),
              ),
              if (_isExpanded)
                _ExpandedView(assets: widget.assets, theme: theme),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandedView extends StatelessWidget {
  const _ExpandedView({
    required this.assets,
    required this.theme,
  });

  final List<AssetId> assets;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
            child: Text(
              'Available on Networks:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          _AssetIconsRow(assets: assets),
        ],
      ),
    );
  }
}

class _AssetIconsRow extends StatelessWidget {
  const _AssetIconsRow({
    required this.assets,
  });

  final List<AssetId> assets;

  @override
  Widget build(BuildContext context) {
    final relatedAssets = assets.length > 1 ? assets.toList() : assets;

    return Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
      children: relatedAssets.map((asset) {
        return _AssetIconItem(asset: asset);
      }).toList(),
    );
  }
}

class _AssetIconItem extends StatelessWidget {
  const _AssetIconItem({
    required this.asset,
  });

  final AssetId asset;

  @override
  Widget build(BuildContext context) {
    final size = isMobile ? 50.0 : 66.0;
    final theme = Theme.of(context);

    return Tooltip(
      message: asset.id,
      child: InkWell(
        onTap: null,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          height: size,
          constraints: BoxConstraints(
            minWidth: size,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AssetLogo.ofTicker(
                  asset.subClass.iconTicker,
                  size: min(36, size * 0.6),
                ),
                const SizedBox(height: 2),
                Text(
                  asset.subClass.formatted,
                  style: theme.textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
