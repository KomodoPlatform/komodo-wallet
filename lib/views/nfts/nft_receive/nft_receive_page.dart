import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/nft_receive/bloc/nft_receive_bloc.dart';
import 'package:web_dex/bloc/nfts/nft_main_bloc.dart';
import 'package:web_dex/blocs/current_wallet_bloc.dart';
import 'package:web_dex/views/nfts/nft_receive/nft_receive_view.dart';

class NftReceivePage extends StatelessWidget {
  const NftReceivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NftMainBloc, NftMainState>(
      builder: (context, state) {
        return BlocProvider(
          create: (context) => NftReceiveBloc(
            coinsRepo: RepositoryProvider.of<CoinsRepo>(context),
            currentWalletBloc:
                RepositoryProvider.of<CurrentWalletBloc>(context),
          )..add(NftReceiveEventInitial(chain: state.selectedChain)),
          child: NftReceiveView(),
        );
      },
    );
  }
}
