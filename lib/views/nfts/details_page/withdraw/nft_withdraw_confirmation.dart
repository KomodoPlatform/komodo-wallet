import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/bloc/nft_withdraw/nft_withdraw_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/shared/utils/formatters.dart';
import 'package:web_dex/shared/widgets/truncate_middle_text.dart';
import 'package:web_dex/views/nfts/details_page/common/nft_data_row.dart';

class NftWithdrawConfirmation extends StatelessWidget {
  const NftWithdrawConfirmation({required this.state});
  final NftWithdrawConfirmState state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).extension<TextThemeExtension>()!;
    final colorScheme = Theme.of(context).extension<ColorSchemeExtension>()!;
    final txDetails = state.txDetails;

    final feeString =
        '${truncateDecimal(txDetails.feeDetails.feeValue ?? '', decimalRange)} ${Coin.normalizeAbbr(txDetails.feeDetails.coin)}';
    return Column(
      children: [
        NftDataRow(
            titleWidget: Flexible(
              child: Text(
                LocaleKeys.recipientAddress.tr(),
                style:
                    textTheme.bodyS.copyWith(color: colorScheme.s50, height: 1),
              ),
            ),
            valueWidget: Flexible(
              child: TruncatedMiddleText(
                txDetails.to.first,
                style: textTheme.bodySBold
                    .copyWith(color: colorScheme.secondary, height: 1),
              ),
            )),
        const SizedBox(height: 15),
        NftDataRow(
          title: LocaleKeys.tokensAmount.tr(),
          titleStyle: TextStyle(color: colorScheme.s50),
          value: txDetails.amount,
        ),
        const SizedBox(height: 15),
        NftDataRow(
          title: LocaleKeys.networkFee.tr(),
          titleStyle: TextStyle(color: colorScheme.s50),
          value: feeString,
        ),
      ],
    );
  }
}
