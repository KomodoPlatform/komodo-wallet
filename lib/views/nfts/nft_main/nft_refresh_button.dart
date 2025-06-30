import 'package:app_theme/app_theme.dart';
import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/nfts/nft_main_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/nft.dart';

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
