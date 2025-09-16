import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';

class NftDataRow extends StatelessWidget {
  const NftDataRow({
    super.key,
    this.title,
    this.titleWidget,
    this.value,
    this.valueWidget,
    this.titleStyle,
    this.valueStyle,
  });
  final String? title;
  final Widget? titleWidget;
  final String? value;
  final Widget? valueWidget;
  final TextStyle? titleStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).extension<TextThemeExtension>()!;
    final colorScheme = Theme.of(context).extension<ColorSchemeExtension>()!;
    final title = this.title;
    final titleWidget = this.titleWidget;
    final value = this.value;
    final valueWidget = this.valueWidget;
    final titleStyle = textTheme.bodyS
        .copyWith(color: colorScheme.s70, height: 1)
        .merge(this.titleStyle);
    final valueStyle = textTheme.bodySBold
        .copyWith(color: colorScheme.secondary, height: 1)
        .merge(this.valueStyle);

    assert(value == null && valueWidget != null ||
        value != null && valueWidget == null);
    assert(title == null && titleWidget != null ||
        title != null && titleWidget == null);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (title != null)
          Text(
            title,
            style: titleStyle,
          )
        else if (titleWidget != null)
          titleWidget,
        if (value != null)
          Text(
            value,
            style: valueStyle,
          )
        else if (valueWidget != null)
          valueWidget,
      ],
    );
  }
}
