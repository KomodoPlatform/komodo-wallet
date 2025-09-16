import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';

class NftNoLogin extends StatelessWidget {
  const NftNoLogin({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorSchemeExtension colorScheme =
        Theme.of(context).extension<ColorSchemeExtension>()!;
    final TextThemeExtension textTheme =
        Theme.of(context).extension<TextThemeExtension>()!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 124,
          height: 124,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfCont,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.secondary,
                  blurRadius: 24,
                )
              ]),
        ),
        const SizedBox(height: 32),
        Text(
          text,
          style: textTheme.bodySBold,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
