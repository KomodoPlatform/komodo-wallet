import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_wallet/bloc/nfts/nft_main_bloc.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/model/nft.dart';

class NftRefreshButton extends StatelessWidget {
  const NftRefreshButton({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorSchemeExtension colorScheme =
        Theme.of(context).extension<ColorSchemeExtension>()!;
    final textTheme = Theme.of(context).extension<TextThemeExtension>()!;
    final selectedChain = context.select<NftMainBloc, NftBlockchains>(
        (bloc) => bloc.state.selectedChain);
    final isUpdating = context.select<NftMainBloc, bool>(
        (bloc) => bloc.state.updatingChains[selectedChain] ?? false);

    return UiPrimaryButton(
      width: 200,
      height: 40,
      backgroundColor: Colors.transparent,
      textStyle: textTheme.bodySBold.copyWith(color: colorScheme.primary),
      onPressed: () {
        final bloc = context.read<NftMainBloc>();
        bloc.add(NftMainChainNftsRefreshed(selectedChain));
      },
      text: LocaleKeys.refreshList.tr(args: [selectedChain.coinAbbr()]),
      child: isUpdating
          ? UiSpinner(
              color: colorScheme.primary,
            )
          : null,
    );
  }
}
