import 'package:app_theme/app_theme.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/nft_withdraw/nft_withdraw_bloc.dart';
import 'package:web_dex/bloc/nft_withdraw/nft_withdraw_repo.dart';
import 'package:web_dex/bloc/nfts/nft_main_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/model/nft.dart';
import 'package:web_dex/views/nfts/details_page/desktop/nft_details_header_desktop.dart';
import 'package:web_dex/views/nfts/details_page/desktop/nft_details_page_desktop.dart';
import 'package:web_dex/views/nfts/details_page/mobile/nft_details_page_mobile.dart';

class NftDetailsPage extends StatelessWidget {
  const NftDetailsPage({super.key, required this.uuid, required this.isSend});
  final String uuid;
  final bool isSend;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).extension<TextThemeExtension>()!;

    return BlocSelector<NftMainBloc, NftMainState, bool>(
      selector: (state) {
        return state.isInitialized;
      },
      builder: (context, isInitialized) {
        if (!isInitialized) {
          return const Center(
            child: UiSpinner(
              width: 24,
              height: 24,
            ),
          );
        }
        final nfts = context.read<NftMainBloc>().state.nfts;
        final NftToken? nft = nfts.values
            .firstWhereOrNull(
              (list) =>
                  list?.firstWhereOrNull((token) => token.uuid == uuid) != null,
            )
            ?.firstWhereOrNull((token) => token.uuid == uuid);
        final mm2Api = RepositoryProvider.of<Mm2Api>(context);
        final kdfSdk = RepositoryProvider.of<KomodoDefiSdk>(context);

        if (nft == null) {
          return Column(
            children: [
              if (isMobile) const SizedBox(height: 50),
              const NftDetailsHeaderDesktop(),
              const SizedBox(height: 80),
              Center(
                child: Text(
                  LocaleKeys.nothingFound.tr(),
                  style: textTheme.heading1,
                ),
              ),
            ],
          );
        }

        return BlocProvider<NftWithdrawBloc>(
          key: Key('nft-withdraw-bloc-provider-${nft.uuid}'),
          create: (context) => NftWithdrawBloc(
            nft: nft,
            repo: NftWithdrawRepo(api: mm2Api),
            kdfSdk: kdfSdk,
            coinsRepository: RepositoryProvider.of<CoinsRepo>(context),
          ),
          child: isMobile
              ? NftDetailsPageMobile(isRouterSend: isSend)
              : NftDetailsPageDesktop(isSend: isSend),
        );
      },
    );
  }
}
