import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/nft_withdraw/nft_withdraw_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/widgets/hash_explorer_link.dart';
import 'package:web_dex/views/nfts/common/widgets/nft_image.dart';
import 'package:web_dex/views/nfts/details_page/common/nft_data_row.dart';

class NftWithdrawSuccess extends StatefulWidget {
  const NftWithdrawSuccess({super.key, required this.state});
  final NftWithdrawSuccessState state;

  @override
  State<NftWithdrawSuccess> createState() => _NftWithdrawSuccessState();
}

class _NftWithdrawSuccessState extends State<NftWithdrawSuccess> {
  @override
  void dispose() {
    context.read<NftWithdrawBloc>().add(const NftWithdrawInit());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<ColorSchemeExtension>()!;
    final textTheme = Theme.of(context).extension<TextThemeExtension>()!;
    final nft = widget.state.nft;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: colorScheme.surfContLow,
      ),
      child: Column(children: [
        SvgPicture.asset(
          '$assetsPath/ui_icons/success.svg',
          colorFilter: ColorFilter.mode(
            colorScheme.primary,
            BlendMode.srcIn,
          ),
          height: 64,
          width: 64,
        ),
        const SizedBox(height: 12),
        Text(
          LocaleKeys.successfullySent.tr(),
          style: textTheme.heading2.copyWith(color: colorScheme.primary),
        ),
        const SizedBox(height: 20),
        if (isMobile)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: colorScheme.surfContHigh),
                    bottom: BorderSide(color: colorScheme.surfContHigh))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 40,
                        maxHeight: 40,
                      ),
                      child: NftImage(imageUrl: nft.imageUrl),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          nft.name,
                          style: textTheme.bodySBold.copyWith(
                            color: colorScheme.primary,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          nft.collectionName ?? '',
                          style: textTheme.bodyXS.copyWith(
                            color: colorScheme.s70,
                            height: 1,
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        SizedBox(height: isMobile ? 38 : 4),
        NftDataRow(
          title: LocaleKeys.date.tr(),
          value: DateFormat('dd MMM yyyy HH:mm').format(
              DateTime.fromMillisecondsSinceEpoch(
                  widget.state.timestamp * 1000)),
        ),
        const SizedBox(height: 24),
        NftDataRow(
          title: LocaleKeys.transactionId.tr(),
          valueWidget: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: HashExplorerLink(
              hash: widget.state.txHash,
              type: HashExplorerType.tx,
              coin: widget.state.nft.parentCoin,
            ),
          ),
        ),
        const SizedBox(height: 24),
        NftDataRow(
          title: LocaleKeys.to.tr(),
          valueWidget: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 165),
            child: HashExplorerLink(
              hash: widget.state.to,
              type: HashExplorerType.address,
              coin: widget.state.nft.parentCoin,
            ),
          ),
        ),
      ]),
    );
  }
}
