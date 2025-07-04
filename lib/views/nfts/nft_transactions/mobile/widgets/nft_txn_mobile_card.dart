import 'package:app_theme/app_theme.dart';
import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/rpc/nft_transaction/nft_transactions_response.dart';
import 'package:web_dex/shared/widgets/nft/nft_badge.dart';
import 'package:web_dex/views/nfts/nft_transactions/common/utils/formatter.dart';
import 'package:web_dex/views/nfts/nft_transactions/common/widgets/nft_txn_date.dart';
import 'package:web_dex/views/nfts/nft_transactions/common/widgets/nft_txn_media.dart';
import 'package:web_dex/views/nfts/nft_transactions/common/widgets/nft_txn_status.dart';
import 'package:web_dex/views/nfts/nft_transactions/mobile/widgets/nft_txn_copied_text.dart';

class NftTxnMobileCard extends StatefulWidget {
  final NftTransaction transaction;

  final VoidCallback onPressed;
  const NftTxnMobileCard({
    super.key,
    required this.transaction,
    required this.onPressed,
  });

  @override
  State<NftTxnMobileCard> createState() => _NftTxnMobileCardState();
}

class _NftTxnMobileCardState extends State<NftTxnMobileCard>
    with AutomaticKeepAliveClientMixin {
  bool isSelected = false;

  @override
  bool get wantKeepAlive => isSelected;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final colorScheme = Theme.of(context).extension<ColorSchemeExtension>();
    final textScheme = Theme.of(context).extension<TextThemeExtension>();

    return GestureDetector(
      onTap: () {
        widget.onPressed();

        setState(() {
          isSelected = !isSelected;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme?.surfCont,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                NftTxnStatus(status: widget.transaction.status),
                BlockchainBadge(
                  blockchain: widget.transaction.chain,
                  width: 75,
                ),
                NftTxnDate(
                  blockTimestamp: widget.transaction.blockTimestamp,
                ),
              ],
            ),
            const SizedBox(height: 16),
            NftTxnMedia(
              imagePath: widget.transaction.imageUrl,
              title: widget.transaction.tokenName,
              collectionName: widget.transaction.collectionName ?? '-',
              amount: widget.transaction.amount,
            ),
            const SizedBox(height: 16),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              firstChild: const SizedBox.shrink(),
              crossFadeState: isSelected
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              secondChild: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      NftTxnCopiedText(
                        transaction: widget.transaction,
                        explorerType: NftTxnExplorerType.tx,
                        title: LocaleKeys.hash.tr(),
                      ),
                      _AdditionalInfoLine(
                        title: LocaleKeys.confirmations.tr(),
                        successChild: Builder(builder: (context) {
                          bool isConfirmed =
                              widget.transaction.confirmations != null;
                          return Row(
                            children: [
                              Icon(
                                isConfirmed
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.warning,
                                color: isConfirmed
                                    ? colorScheme?.green
                                    : colorScheme?.yellow,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(widget.transaction.confirmations.toString(),
                                  style: textScheme?.bodyXSBold),
                            ],
                          );
                        }),
                        status: widget.transaction.detailsFetchStatus,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      NftTxnCopiedText(
                        transaction: widget.transaction,
                        explorerType: NftTxnExplorerType.from,
                        title: LocaleKeys.from.tr(),
                      ),
                      _AdditionalInfoLine(
                        title: LocaleKeys.transactionFee.tr(),
                        successChild: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              NftTxFormatter.getFeeValue(widget.transaction),
                              style: textScheme?.bodyXSBold,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              NftTxFormatter.getUsdPriceOfFee(
                                  widget.transaction),
                              style: textScheme?.bodyXSBold,
                            ),
                          ],
                        ),
                        status: widget.transaction.detailsFetchStatus,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      NftTxnCopiedText(
                        transaction: widget.transaction,
                        explorerType: NftTxnExplorerType.to,
                        title: LocaleKeys.to.tr(),
                      ),
                      _AdditionalInfoLine(
                        title: LocaleKeys.blockHeight.tr(),
                        successChild: Text(
                            widget.transaction.blockNumber.toString(),
                            style: textScheme?.bodyXSBold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdditionalInfoLine extends StatelessWidget {
  const _AdditionalInfoLine({
    required this.title,
    required this.successChild,
    this.status = NftTxnDetailsStatus.success,
  });

  static const double iconSize = 14.0;

  final String title;
  final Widget successChild;
  final NftTxnDetailsStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<ColorSchemeExtension>();
    final textScheme = Theme.of(context).extension<TextThemeExtension>();
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                title,
                style: textScheme?.bodyXS.copyWith(color: colorScheme?.s70),
                textAlign: TextAlign.start,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Builder(builder: (context) {
            switch (status) {
              case NftTxnDetailsStatus.initial:
                return const UiSpinner(
                  height: iconSize,
                  width: iconSize,
                  strokeWidth: 1,
                );
              case NftTxnDetailsStatus.success:
                return successChild;

              case NftTxnDetailsStatus.failure:
                return Icon(
                  Icons.error_outline_outlined,
                  color: colorScheme?.error,
                  size: iconSize,
                );
            }
          }),
        ],
      ),
    );
  }
}
