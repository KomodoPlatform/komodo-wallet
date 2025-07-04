import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/coins_bloc/coins_bloc.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/router/state/routing_state.dart';
import 'package:komodo_wallet/router/state/wallet_state.dart';
import 'package:komodo_wallet/views/wallet/coin_details/coin_details.dart';
import 'package:komodo_wallet/views/wallet/coins_manager/coins_manager_page.dart';
import 'package:komodo_wallet/views/wallet/wallet_page/wallet_main/wallet_main.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({
    required this.coinAbbr,
    required this.action,
  });
  final String? coinAbbr;
  final CoinsManagerAction action;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoinsBloc, CoinsState>(
      builder: (context, state) {
        final Coin? coin = state.walletCoins[coinAbbr ?? ''];
        if (coin != null) {
          return CoinDetails(
            key: Key(coin.abbr),
            coin: coin,
            onBackButtonPressed: _onBackButtonPressed,
          );
        }

        final action = this.action;
        if (action != CoinsManagerAction.none) {
          return CoinsManagerPage(
            action: action,
            closePage: _onBackButtonPressed,
          );
        }

        return const WalletMain();
      },
    );
  }

  void _onBackButtonPressed() {
    routingState.resetDataForPageContent();
  }
}
