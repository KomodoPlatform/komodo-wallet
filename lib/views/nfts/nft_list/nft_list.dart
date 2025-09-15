import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/nfts/nft_main_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/nft.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/views/nfts/nft_list/nft_list_item.dart';
import 'package:web_dex/views/nfts/nft_main/nft_refresh_button.dart';

const _nftItemMobileSize = Size(169, 207);
const _maxNftItemSize = Size(248, 308);
const double _paddingBetweenNft = 12;

class NftList extends StatelessWidget {
  const NftList({super.key});

  @override
  Widget build(BuildContext context) {
    final List<NftToken>? nftList = context
        .select<NftMainBloc, List<NftToken>?>(
          (bloc) => bloc.state.nfts[bloc.state.selectedChain],
        );
    final bool isInitialized = context.select<NftMainBloc, bool>(
      (bloc) => bloc.state.isInitialized,
    );
    final List<NftToken> list = nftList ?? [];

    if (list.isEmpty && isInitialized) {
      return isMobile
          ? const SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NothingShow(),
                  SizedBox(height: 24),
                  NftRefreshButton(),
                ],
              ),
            )
          : Container(
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 72.0),
              child: const Column(
                children: [
                  _NothingShow(),
                  SizedBox(height: 24),
                  NftRefreshButton(),
                ],
              ),
            );
    }

    return _Layout(nftList: list, onTap: _onNftTap, onSendTap: _onSendNftTap);
  }

  void _onNftTap(String uuid) {
    routingState.nftsState.setDetailsAction(uuid, false);
  }

  void _onSendNftTap(String uuid) {
    routingState.nftsState.setDetailsAction(uuid, true);
  }
}

class _Layout extends StatelessWidget {
  const _Layout({
    required this.nftList,
    required this.onTap,
    required this.onSendTap,
  });
  final List<NftToken> nftList;
  final Function(String) onTap;
  final Function(String) onSendTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = _calculateNftCountInRow(constraints.maxWidth);
        final ScrollController scrollController = ScrollController();
        return DexScrollbar(
          scrollController: scrollController,
          isMobile: isMobile,
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    mainAxisSpacing: _paddingBetweenNft,
                    crossAxisSpacing: _paddingBetweenNft,
                    crossAxisCount: count,
                    mainAxisExtent: isMobile
                        ? _nftItemMobileSize.height
                        : _maxNftItemSize.height,
                  ),
                  itemCount: nftList.length,
                  itemBuilder: (context, index) => NftListItem(
                    key: ValueKey(nftList[index].uuid),
                    nft: nftList[index],
                    onTap: onTap,
                    onSendTap: onSendTap,
                  ),
                ),
                const SizedBox(height: 40),
                const Align(
                  alignment: Alignment.center,
                  child: NftRefreshButton(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _calculateNftCountInRow(double maxWidth) {
    if (isDesktop) return 4;
    if (isTablet) return 3;

    final maxCount = maxWidth / _nftItemMobileSize.width;
    if (nftList.length == 1 && maxCount > 2.5) {
      return 2;
    }
    final max = maxCount.toInt();
    if (nftList.length <= max) {
      return nftList.length;
    }
    return max;
  }
}

class _NothingShow extends StatelessWidget {
  const _NothingShow();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).extension<TextThemeExtension>()!;
    final String? chain = context.select<NftMainBloc, String?>(
      (bloc) => bloc.state.selectedChain.coinAbbr(),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(LocaleKeys.noCollectibles.tr(), style: textTheme.heading1),
        Text(
          LocaleKeys.tryReceiveNft.tr(args: [chain ?? '']),
          style: textTheme.bodyM,
        ),
      ],
    );
  }
}
