import 'package:app_theme/app_theme.dart';
import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/nft.dart';
import 'package:web_dex/shared/utils/formatters.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/widgets/hash_explorer_link.dart';
import 'package:web_dex/shared/widgets/nft/nft_badge.dart';
import 'package:web_dex/shared/widgets/simple_copyable_link.dart';
import 'package:web_dex/views/nfts/details_page/common/nft_data_row.dart';

class NftData extends StatelessWidget {
  const NftData({required this.nft, this.header});
  final NftToken nft;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<ColorSchemeExtension>()!;
    final textTheme = Theme.of(context).extension<TextThemeExtension>()!;
    final header = this.header;
    final double spaceBetweenRows = isMobile ? 20 : 15;

    return Container(
      padding: isMobile
          ? const EdgeInsets.fromLTRB(20, 15, 20, 30)
          : const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.surfContLow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) header,
          NftDataRow(
            title: LocaleKeys.tokensAmount.tr(),
            titleStyle: textTheme.bodyM.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
            value: nft.amount,
            valueStyle: textTheme.bodyM.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            height: 1,
            color: colorScheme.surfContHigh,
          ),
          const SizedBox(height: 15),
          NftDataRow(
            title: LocaleKeys.contractAddress.tr(),
            valueWidget: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: HashExplorerLink(
                coin: nft.parentCoin,
                hash: nft.tokenAddress,
                type: HashExplorerType.address,
              ),
            ),
          ),
          SizedBox(height: spaceBetweenRows),
          NftDataRow(
              title: LocaleKeys.tokenID.tr(),
              valueWidget: SimpleCopyableLink(
                text: truncateMiddleSymbols(nft.tokenId, 6, 7),
                valueToCopy: nft.tokenId,
                link: nft.tokenUri,
              )),
          SizedBox(height: spaceBetweenRows),
          NftDataRow(
            title: LocaleKeys.tokenStandard.tr(),
            value: nft.contractType.name.toUpperCase(),
          ),
          SizedBox(height: isMobile ? spaceBetweenRows : 8),
          NftDataRow(
            title: LocaleKeys.blockchain.tr(),
            valueWidget: BlockchainBadge(
              width: 76,
              padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 5),
              blockchain: nft.chain,
              iconSize: 10,
              iconColor: colorScheme.surf,
              textStyle:
                  textTheme.bodyXXSBold.copyWith(color: colorScheme.surf),
            ),
          ),
        ],
      ),
    );
  }
}
