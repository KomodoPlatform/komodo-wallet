import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/model/nft.dart';

class NftDescription extends StatelessWidget {
  const NftDescription({required this.nft, this.isDescriptionShown = true});

  final NftToken nft;
  final bool isDescriptionShown;
  @override
  Widget build(BuildContext context) {
    final ColorSchemeExtension colorScheme = Theme.of(
      context,
    ).extension<ColorSchemeExtension>()!;
    final TextThemeExtension textTheme = Theme.of(
      context,
    ).extension<TextThemeExtension>()!;
    final String? description = nft.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          nft.collectionName ?? '',
          style: textTheme.bodyM.copyWith(color: colorScheme.s70, height: 1),
        ),
        const SizedBox(height: 3),
        Text(nft.name, style: textTheme.heading1.copyWith(height: 1)),
        if (isDescriptionShown && description != null && description.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 120.0),
            child: SingleChildScrollView(
              child: Text(description, style: textTheme.bodyS),
            ),
          ),
      ],
    );
  }
}
