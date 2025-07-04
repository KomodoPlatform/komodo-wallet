import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_wallet/bloc/nft_withdraw/nft_withdraw_bloc.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/router/state/routing_state.dart';
import 'package:komodo_wallet/views/nfts/common/widgets/nft_image.dart';
import 'package:komodo_wallet/views/nfts/details_page/common/nft_data.dart';
import 'package:komodo_wallet/views/nfts/details_page/common/nft_description.dart';
import 'package:komodo_wallet/views/nfts/details_page/desktop/nft_details_header_desktop.dart';
import 'package:komodo_wallet/views/nfts/details_page/withdraw/nft_withdraw_view.dart';

class NftDetailsPageDesktop extends StatelessWidget {
  const NftDetailsPageDesktop({required this.isSend});
  final bool isSend;

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<NftWithdrawBloc>();
    final state = bloc.state;
    final nft = state.nft;

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        const NftDetailsHeaderDesktop(),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 389, maxHeight: 440),
                child: NftImage(imagePath: nft.imageUrl),
              ),
            ),
            const SizedBox(width: 32),
            Flexible(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 416, maxHeight: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    NftDescription(
                      nft: nft,
                      isDescriptionShown: !isSend,
                    ),
                    const SizedBox(height: 12),
                    if (state is! NftWithdrawSuccessState) NftData(nft: nft),
                    if (isSend)
                      Flexible(
                        child: NftWithdrawView(nft: nft),
                      )
                    else ...[
                      const Spacer(),
                      UiPrimaryButton(
                          text: LocaleKeys.send.tr(),
                          height: 40,
                          onPressed: () {
                            routingState.nftsState
                                .setDetailsAction(nft.uuid, true);
                          }),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
