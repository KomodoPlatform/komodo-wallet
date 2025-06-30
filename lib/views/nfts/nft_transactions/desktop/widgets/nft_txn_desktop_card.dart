import 'package:app_theme/app_theme.dart';
import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/rpc/nft_transaction/nft_transactions_response.dart';
import 'package:web_dex/shared/widgets/nft/nft_badge.dart';
import 'package:web_dex/views/nfts/nft_transactions/common/utils/formatter.dart';
import 'package:web_dex/views/nfts/nft_transactions/common/widgets/nft_txn_date.dart';
import 'package:web_dex/views/nfts/nft_transactions/common/widgets/nft_txn_hash.dart';
import 'package:web_dex/views/nfts/nft_transactions/common/widgets/nft_txn_media.dart';
import 'package:web_dex/views/nfts/nft_transactions/common/widgets/nft_txn_status.dart';
import 'package:web_dex/views/nfts/nft_transactions/desktop/widgets/nft_txn_desktop_wrapper.dart';

class NftTxnDesktopCard extends StatefulWidget {
  final NftTransaction transaction;
  final VoidCallback onPressed;

  const NftTxnDesktopCard({
    super.key,
    required this.transaction,
    required this.onPressed,
  });

  @override
  State<NftTxnDesktopCard> createState() => _NftTxnDesktopCardState();
}

class _NftTxnDesktopCardState extends State<NftTxnDesktopCard>
    with AutomaticKeepAliveClientMixin {
  bool isSelected = false;

  @override
  bool get wantKeepAlive => isSelected;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final colorScheme = Theme.of(context).extension<ColorSchemeExtension>();

    return GestureDetector(
      onTap: () {
        widget.onPressed();

        setState(() {
          isSelected = !isSelected;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        decoration: BoxDecoration(
          color: colorScheme?.surfCont,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            NftTxnDesktopWrapper(
              firstChild: NftTxnStatus(
                status: widget.transaction.status,
              ),
              secondChild: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BlockchainBadge(
                    blockchain: widget.transaction.chain,
                    width: 75,
                  ),
                ],
              ),
              thirdChild: NftTxnMedia(
                imagePath: widget.transaction.imageUrl,
                title: widget.transaction.tokenName,
                collectionName: widget.transaction.collectionName ?? '-',
                amount: widget.transaction.amount,
              ),
              fourthChild: NftTxnDate(
                blockTimestamp: widget.transaction.blockTimestamp,
              ),
              fifthChild: NftTxnHash(
                transaction: widget.transaction,
              ),
            ),
            _AdditionalTxnData(
              transaction: widget.transaction,
              isShown: isSelected,
            )
          ],
        ),
      ),
    );
  }
}

class _AdditionalTxnData extends StatelessWidget {
  const _AdditionalTxnData({
    required this.transaction,
    required this.isShown,
  });
  final NftTransaction transaction;
  final bool isShown;

  static const _placeholderSizeOfTransactionFee = Size(91.0, 16);
  static const _placeholderSizeOfSuccessStatus = Size(40.0, 16);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<ColorSchemeExtension>();
    final textScheme = Theme.of(context).extension<TextThemeExtension>();
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 150),
        firstCurve: Curves.easeInOut,
        secondCurve: Curves.easeInOut,
        firstChild: const SizedBox(width: double.maxFinite),
        secondChild: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TableView(
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: colorScheme?.green,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${LocaleKeys.confirmations.tr()}:',
                          style: textScheme?.bodyXS
                              .copyWith(color: colorScheme?.s70),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          null,
                          color: colorScheme?.green,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${LocaleKeys.blockHeight.tr()}:',
                          style: textScheme?.bodyXS
                              .copyWith(color: colorScheme?.s70),
                        ),
                      ],
                    ),
                    _Value(
                      value: transaction.confirmations.toString(),
                      status: transaction.detailsFetchStatus,
                      defaultSize: _placeholderSizeOfSuccessStatus,
                    ),
                    _Value(
                      value: transaction.blockNumber.toString(),
                    ),
                    true,
                  ),
                  _TableView(
                    Text(
                      '${LocaleKeys.transactionFee.tr()}:',
                      style:
                          textScheme?.bodyXS.copyWith(color: colorScheme?.s70),
                    ),
                    const SizedBox(),
                    _Value(
                      value: NftTxFormatter.getFeeValue(transaction),
                      status: transaction.detailsFetchStatus,
                      defaultSize: _placeholderSizeOfTransactionFee,
                    ),
                    _Value(
                      value: NftTxFormatter.getUsdPriceOfFee(transaction),
                      status: transaction.detailsFetchStatus,
                      defaultSize: _placeholderSizeOfTransactionFee,
                    ),
                    false,
                  ),
                  _TableView(
                    Text(
                      '${LocaleKeys.from.tr()}:',
                      style:
                          textScheme?.bodyXS.copyWith(color: colorScheme?.s70),
                    ),
                    Text(
                      '${LocaleKeys.to.tr()}:',
                      style:
                          textScheme?.bodyXS.copyWith(color: colorScheme?.s70),
                    ),
                    Text(
                      transaction.fromAddress,
                      style: textScheme?.bodyXS,
                    ),
                    Text(
                      transaction.toAddress,
                      style: textScheme?.bodyXS,
                    ),
                    false,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(width: 16),
                  Text(
                    '${LocaleKeys.fullHash.tr()}:',
                    style: textScheme?.bodyXS.copyWith(color: colorScheme?.s70),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    transaction.transactionHash,
                    style: textScheme?.bodyXS,
                  ),
                ],
              ),
            ],
          ),
        ),
        crossFadeState:
            !isShown ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      ),
    );
  }
}

class _TableView extends StatelessWidget {
  final Widget titleOne;
  final Widget titleTwo;
  final Widget valueOne;
  final Widget valueTwo;
  final bool isLeftAligned;

  const _TableView(this.titleOne, this.titleTwo, this.valueOne, this.valueTwo,
      this.isLeftAligned);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isLeftAligned ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment:
              isLeftAligned ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            titleOne,
            const SizedBox(width: 4),
            valueOne,
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment:
              isLeftAligned ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            titleTwo,
            const SizedBox(width: 4),
            valueTwo,
          ],
        ),
      ],
    );
  }
}

class _Value extends StatelessWidget {
  final String value;

  final NftTxnDetailsStatus status;
  final Size? defaultSize;
  const _Value({
    required this.value,
    this.status = NftTxnDetailsStatus.success,
    this.defaultSize,
  });

  static const double iconSize = 12.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<ColorSchemeExtension>();
    final textScheme = Theme.of(context).extension<TextThemeExtension>();
    switch (status) {
      case NftTxnDetailsStatus.initial:
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const UiSpinner(
              height: iconSize,
              width: iconSize,
              strokeWidth: 1,
            ),
            if (defaultSize != null)
              SizedBox(
                  width: defaultSize!.width - iconSize,
                  height: defaultSize!.height),
          ],
        );
      case NftTxnDetailsStatus.success:
        return Text(value, style: textScheme?.bodyXS);
      case NftTxnDetailsStatus.failure:
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_outlined,
              color: colorScheme?.error,
              size: iconSize,
            ),
            if (defaultSize != null)
              SizedBox(
                  width: defaultSize!.width - iconSize,
                  height: defaultSize!.height),
          ],
        );
    }
  }
}
