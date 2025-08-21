import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

import 'package:komodo_ui/src/defi/asset/asset_icon.dart';

/// A widget that displays an [AssetIcon] with its protocol icon overlaid.
///
/// Similar to the legacy CoinLogo, but built on top of the new [Asset]
/// and [AssetIcon] APIs.
class AssetLogo extends StatelessWidget {
  /// Creates a new [AssetLogo] widget from an [Asset] instance.
  ///
  /// Example usage:
  /// ```dart
  /// AssetLogo(asset)
  /// ```
  const AssetLogo(
    this.asset, {
    this.size = 41,
    this.isDisabled = false,
    this.heroTag,
    super.key,
  }) : _assetId = null,
       _legacyTicker = null,
       isBlank = false;

  /// Creates a logo directly from an [AssetId].
  const AssetLogo.ofId(
    AssetId assetId, {
    this.size = 41,
    this.isDisabled = false,
    this.heroTag,
    super.key,
  }) : asset = null,
       _assetId = assetId,
       _legacyTicker = null,
       isBlank = false;

  /// Legacy constructor that accepts a raw ticker string.
  ///
  /// This mirrors [AssetIcon.ofTicker] and should only be used when an
  /// [Asset] or [AssetId] instance isn't available.
  const AssetLogo.ofTicker(
    String ticker, {
    this.size = 41,
    this.isDisabled = false,
    this.heroTag,
    super.key,
  }) : _legacyTicker = ticker,
       asset = null,
       _assetId = null,
       isBlank = false;

  /// Creates a placeholder [AssetLogo] widget.
  ///
  /// This displays the default placeholder icon (monetization_on_outlined)
  /// and should be used when no asset data is available or as a fallback.
  ///
  /// Set [isBlank] to true to display an empty circular container instead
  /// of the default icon, similar to the legacy placeholder behavior.
  const AssetLogo.placeholder({
    this.size = 41,
    this.isDisabled = false,
    this.isBlank = false,
    this.heroTag,
    super.key,
  }) : asset = null,
       _assetId = null,
       _legacyTicker = null;

  /// Asset to display the logo for.
  final Asset? asset;

  /// AssetId to display the logo for.
  final AssetId? _assetId;
  final String? _legacyTicker;

  /// Size of the main asset icon.
  final double size;

  /// Whether the asset is disabled. Disabled icons are displayed
  /// with reduced opacity.
  final bool isDisabled;

  /// Whether to display a blank placeholder instead of the default icon.
  /// Only used with the [AssetLogo.placeholder] constructor.
  final bool isBlank;

  /// Optional tag for wrapping the icon in a [Hero] widget.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final resolvedId = asset?.id ?? _assetId;
    final resolvedTicker = _legacyTicker;

    // Handle placeholder case
    if (resolvedId == null && resolvedTicker == null) {
      return _AssetLogoPlaceholder(
        isBlank: isBlank,
        isDisabled: isDisabled,
        size: size,
        heroTag: heroTag,
      );
    }

    final isChildAsset = resolvedId?.isChildAsset ?? false;

    // Use the parent coin ticker for child assets so that token logos display
    // the network they belong to (e.g. ETH for ERC20 tokens).
    final protocolTicker = isChildAsset ? resolvedId?.parentId?.id : null;
    final shouldShowProtocolIcon = isChildAsset && protocolTicker != null;

    final mainIcon =
        resolvedId != null
            ? AssetIcon(
              resolvedId,
              size: size,
              suspended: isDisabled,
              heroTag: heroTag,
            )
            : (resolvedTicker != null
                ? AssetIcon.ofTicker(
                  resolvedTicker,
                  size: size,
                  suspended: isDisabled,
                  heroTag: heroTag,
                )
                : throw ArgumentError(
                  'resolvedTicker cannot be null when both asset and '
                  'assetId are absent.',
                ));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        mainIcon,
        if (shouldShowProtocolIcon)
          AssetProtocolIcon(protocolTicker: protocolTicker, logoSize: size),
      ],
    );
  }
}

class _AssetLogoPlaceholder extends StatelessWidget {
  const _AssetLogoPlaceholder({
    required this.isBlank,
    required this.isDisabled,
    required this.size,
    this.heroTag,
  });

  final bool isBlank;
  final bool isDisabled;
  final double size;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final child =
        isBlank
            ? Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isDisabled
                        ? Theme.of(context).disabledColor
                        : Theme.of(context).colorScheme.secondaryContainer,
              ),
            )
            : Icon(
              Icons.monetization_on_outlined,
              size: size,
              color:
                  isDisabled
                      ? Theme.of(context).disabledColor
                      : Theme.of(context).colorScheme.onSecondaryContainer,
            );

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: child);
    }

    return child;
  }
}

/// A widget that displays a protocol icon with a circular border and shadow,
/// positioned absolutely within its parent widget.
///
/// This widget is typically used to overlay a protocol icon on top of an asset
/// logo to indicate the blockchain protocol or network the asset belongs to.
class AssetProtocolIcon extends StatelessWidget {
  /// Creates an [AssetProtocolIcon] widget.
  ///
  /// The [protocolTicker] and [logoSize] parameters are required.
  ///
  /// Optional parameters with their default behaviors:
  /// - [protocolSizeWithBorder]: Defaults to `logoSize * 0.45`
  /// - [protocolBorder]: Defaults to `protocolSizeWithBorder * 0.1`
  /// - [protocolLeftPosition]: Defaults to `logoSize * 0.55`
  /// - [protocolTopPosition]: Defaults to `logoSize * 0.55`
  const AssetProtocolIcon({
    required this.protocolTicker,
    required this.logoSize,
    this.protocolSizeWithBorder,
    this.protocolBorder,
    this.protocolLeftPosition,
    this.protocolTopPosition,
    super.key,
  });

  /// The ticker symbol of the protocol to display as an icon.
  final String protocolTicker;

  /// The size of the main logo that this protocol icon will be
  /// positioned relative to.
  final double logoSize;

  /// The total size of the protocol icon including its border.
  /// If null, defaults to `logoSize * 0.45`.
  final double? protocolSizeWithBorder;

  /// The thickness of the border around the protocol icon.
  /// If null, defaults to `protocolSizeWithBorder * 0.1`.
  final double? protocolBorder;

  /// The left position offset for the protocol icon.
  /// If null, defaults to `logoSize * 0.55`.
  final double? protocolLeftPosition;

  /// The top position offset for the protocol icon.
  /// If null, defaults to `logoSize * 0.55`.
  final double? protocolTopPosition;

  // Pre-computed values to avoid recalculation in build()
  double get _sizeWithBorder => protocolSizeWithBorder ?? logoSize * 0.45;
  double get _border => protocolBorder ?? _sizeWithBorder * 0.1;
  double get _leftPosition => protocolLeftPosition ?? logoSize * 0.55;
  double get _topPosition => protocolTopPosition ?? logoSize * 0.55;
  double get _iconSize => _sizeWithBorder - _border;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _leftPosition,
      top: _topPosition,
      width: _sizeWithBorder,
      height: _sizeWithBorder,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 2,
            ),
          ],
        ),
        child: Container(
          width: _iconSize,
          height: _iconSize,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: AssetIcon.ofTicker(protocolTicker, size: _iconSize),
        ),
      ),
    );
  }
}
