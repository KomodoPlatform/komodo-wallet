/// Defines size configurations for an AssetItem component.
class AssetItemSize {
  const AssetItemSize({
    required this.assetLogo,
    required this.title,
    required this.subtitle,
    required this.verticalSpacing,
  });

  /// Size preset for a large asset item
  static const AssetItemSize large = AssetItemSize(
    assetLogo: 34.0,
    title: 14.0,
    subtitle: 12.0,
    verticalSpacing: 6,
  );

  /// Size preset for a medium asset item
  static const AssetItemSize medium = AssetItemSize(
    assetLogo: 30.0,
    title: 13.0,
    subtitle: 11.0,
    verticalSpacing: 3.0,
  );

  /// Size preset for a small asset item
  static const AssetItemSize small = AssetItemSize(
    assetLogo: 26.0,
    title: 11.0,
    subtitle: 10.0,
    verticalSpacing: 3.0,
  );

  /// Size of the asset logo
  final double assetLogo;

  /// Text size for the title
  final double title;

  /// Text size for the subtitle
  final double subtitle;

  /// Standard spacing between elements
  final double verticalSpacing;
}
