import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/nfts/nft_main_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/nft.dart';
import 'package:web_dex/views/nfts/common/widgets/nft_connect_wallet.dart';
import 'package:web_dex/views/nfts/nft_list/nft_list.dart';
import 'package:web_dex/views/nfts/nft_main/nft_main_controls.dart';
import 'package:web_dex/views/nfts/nft_main/nft_main_failure.dart';
import 'package:web_dex/views/nfts/nft_main/nft_main_loading.dart';
import 'package:web_dex/views/nfts/nft_tabs/nft_tabs.dart';

class NftMain extends StatelessWidget {
  const NftMain({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = context.select<AuthBloc, bool>(
        (bloc) => bloc.state.mode == AuthorizeMode.logIn);
    final bool isInitial =
        context.select<NftMainBloc, bool>((bloc) => !bloc.state.isInitialized);

    final bool hasLoaded = context.select<NftMainBloc, bool>(
        (bloc) => bloc.state.sortedChains.isNotEmpty);
    if (isLoggedIn && (isInitial || !hasLoaded)) {
      return const NftMainLoading();
    }
    final ColorSchemeExtension colorScheme =
        Theme.of(context).extension<ColorSchemeExtension>()!;
    final textTheme = Theme.of(context).extension<TextThemeExtension>()!;
    final List<NftBlockchains> tabs =
        context.select<NftMainBloc, List<NftBlockchains>>(
            (bloc) => bloc.state.sortedChains);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile)
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 15),
            alignment: Alignment.center,
            child: Text(
              LocaleKeys.yourCollectibles.tr(),
              textAlign: TextAlign.center,
              style: textTheme.bodyMBold.copyWith(color: colorScheme.secondary),
            ),
          ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colorScheme.surfContHighest,
              ),
            ),
          ),
          child: NftTabs(tabs: tabs),
        ),
        const SizedBox(height: 20),
        const NftMainControls(),
        const SizedBox(height: 20),
        Flexible(
          child: Builder(builder: (context) {
            final mode = context
                .select<AuthBloc, AuthorizeMode>((bloc) => bloc.state.mode);
            if (mode != AuthorizeMode.logIn) {
              return isMobile
                  ? const Center(child: NftConnectWallet())
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      key: Key('msg-connect-wallet'),
                      children: [NftConnectWallet()],
                    );
            }

            final BaseError? error = context
                .select<NftMainBloc, BaseError?>((bloc) => bloc.state.error);
            if (error != null) {
              return NftMainFailure(error: error);
            }

            return const NftList();
          }),
        ),
      ],
    );
  }
}
