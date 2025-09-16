import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/mm2/rpc/nft_transaction/nft_transactions_response.dart';

class NftTxnStatus extends StatelessWidget {
  final NftTransactionStatuses? status;
  const NftTxnStatus({required this.status});

  @override
  Widget build(BuildContext context) {
    final statusIconPath = status == NftTransactionStatuses.receive
        ? '$assetsPath/custom_icons/arrow_down.svg'
        : '$assetsPath/custom_icons/arrow_up.svg';
    final colorScheme = Theme.of(context).extension<ColorSchemeExtension>()!;
    final textScheme = Theme.of(context).extension<TextThemeExtension>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          statusIconPath,
          width: 16,
          height: 16,
          colorFilter: ColorFilter.mode(colorScheme.secondary, BlendMode.srcIn),
        ),
        const SizedBox(width: 4),
        Text(
          status.toString(),
          style: textScheme.bodyXS.copyWith(color: colorScheme.secondary),
        ),
      ],
    );
  }
}
