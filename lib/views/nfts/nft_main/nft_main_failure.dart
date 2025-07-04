import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/nfts/nft_main_bloc.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/mm2/mm2_api/rpc/base.dart';
import 'package:komodo_wallet/mm2/mm2_api/rpc/errors.dart';
import 'package:komodo_wallet/views/nfts/common/widgets/nft_failure.dart';

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
