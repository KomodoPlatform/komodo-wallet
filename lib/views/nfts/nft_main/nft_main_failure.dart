import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/nfts/nft_main_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/mm2/mm2_api/rpc/errors.dart';
import 'package:web_dex/views/nfts/common/widgets/nft_failure.dart';

class NftMainFailure extends StatelessWidget {
  final BaseError error;

  const NftMainFailure({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final String? chain = context.select<NftMainBloc, String?>(
        (bloc) => bloc.state.selectedChain.coinAbbr());
    return NftFailure(
      title: LocaleKeys.loadingError.tr(),
      subtitle: LocaleKeys.unableRetrieveNftData.tr(args: [chain ?? '']),
      additionSubtitle: error is TransportError
          ? LocaleKeys.tryCheckInternetConnection.tr()
          : null,
      message: error.message,
      onTryAgain: () {
        context.read<NftMainBloc>().add(const NftMainChainUpdateRequested());
      },
    );
  }
}
