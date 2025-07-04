import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_wallet/bloc/coins_bloc/coins_repo.dart';
import 'package:komodo_wallet/bloc/nft_receive/bloc/nft_receive_bloc.dart';
import 'package:komodo_wallet/bloc/nfts/nft_main_bloc.dart';
import 'package:komodo_wallet/views/nfts/nft_receive/nft_receive_view.dart';

class NftReceivePage extends StatelessWidget {
  const NftReceivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NftMainBloc, NftMainState>(
      builder: (context, state) {
        return BlocProvider(
          create: (context) => NftReceiveBloc(
            coinsRepo: RepositoryProvider.of<CoinsRepo>(context),
            sdk: RepositoryProvider.of<KomodoDefiSdk>(context),
          )..add(NftReceiveStarted(chain: state.selectedChain)),
          child: NftReceiveView(),
        );
      },
    );
  }
}
