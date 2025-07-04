import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/views/nfts/common/widgets/nft_image.dart';

class NftTxnMedia extends StatelessWidget {
  final String? imagePath;
  final String? title;
  final String collectionName;
  final String amount;
  const NftTxnMedia({
    required this.imagePath,
    required this.title,
    required this.collectionName,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<ColorSchemeExtension>();
    final textScheme = Theme.of(context).extension<TextThemeExtension>();
    final titleTextStyle = textScheme?.bodySBold;

    final subtitleTextStyle = textScheme?.bodyXS.copyWith(
      color: colorScheme?.s50,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 40, maxHeight: 40),
          child: NftImage(imagePath: imagePath),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(title ?? '-',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: titleTextStyle),
                    ),
                    Text(' ($amount)', maxLines: 1, style: titleTextStyle),
                  ],
                ),
              ),
              Text(collectionName,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: subtitleTextStyle),
            ],
          ),
        )
      ],
    );
  }
}
