import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/nft_withdraw/nft_withdraw_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/nft.dart';
import 'package:web_dex/router/state/nfts_state.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/views/common/page_header/page_header.dart';
import 'package:web_dex/views/nfts/common/widgets/nft_image.dart';
import 'package:web_dex/views/nfts/details_page/common/nft_data.dart';
import 'package:web_dex/views/nfts/details_page/common/nft_description.dart';
import 'package:web_dex/views/nfts/details_page/mobile/nft_details_header_mobile.dart';
import 'package:web_dex/views/nfts/details_page/withdraw/nft_withdraw_view.dart';

class NftDetailsPageMobile extends StatefulWidget {
  const NftDetailsPageMobile({required this.isRouterSend});
  final bool isRouterSend;

  @override
  State<NftDetailsPageMobile> createState() => _NftDetailsPageMobileState();
}

class _NftDetailsPageMobileState extends State<NftDetailsPageMobile> {
  bool _isSend = false;

  @override
  void initState() {
    _isSend = widget.isRouterSend;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NftWithdrawBloc, NftWithdrawState>(
        builder: (BuildContext context, NftWithdrawState state) {
      final nft = state.nft;

      return SingleChildScrollView(
        child: _isSend
            ? _Send(
                nft: nft,
                close: _closeSend,
              )
            : _Details(
                nft: nft,
                onBack: _livePage,
                onSend: _showSend,
              ),
      );
    });
  }

  void _showSend() {
    setState(() {
      _isSend = true;
    });
  }

  void _closeSend() {
    if (widget.isRouterSend) {
      _livePage();
    } else {
      setState(() {
        _isSend = false;
      });
    }
  }

  void _livePage() {
    routingState.nftsState.pageState = NFTSelectedState.none;
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.nft,
    required this.onBack,
    required this.onSend,
  });
  final NftToken nft;
  final VoidCallback onBack;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 50),
        PageHeader(
          title: nft.name,
          onBackButtonPressed: onBack,
        ),
        const SizedBox(height: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 343),
          child: NftImage(
            imageUrl: nft.imageUrl,
          ),
        ),
        const SizedBox(height: 28),
        UiPrimaryButton(
          text: LocaleKeys.send.tr(),
          height: 40,
          onPressed: onSend,
        ),
        const SizedBox(height: 28),
        NftDescription(nft: nft)
      ],
    );
  }
}

class _Send extends StatelessWidget {
  const _Send({
    required this.nft,
    required this.close,
  });
  final NftToken nft;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).extension<TextThemeExtension>()!;
    final colorScheme = Theme.of(context).extension<ColorSchemeExtension>()!;
    final state = context.read<NftWithdrawBloc>().state;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 50),
        NftDetailsHeaderMobile(
          close: close,
        ),
        const SizedBox(height: 10),
        if (state is! NftWithdrawSuccessState)
          Padding(
            padding: const EdgeInsets.only(bottom: 28.0),
            child: NftData(
              nft: nft,
              header: Column(
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
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              nft.name,
                              style: textTheme.bodySBold.copyWith(
                                  color: colorScheme.primary, height: 1),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              nft.collectionName ?? '',
                              style: textTheme.bodyXS
                                  .copyWith(color: colorScheme.s70, height: 1),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: colorScheme.surfContHigh,
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          )
        else
          const SizedBox(height: 50),
        NftWithdrawView(nft: nft),
      ],
    );
  }
}
