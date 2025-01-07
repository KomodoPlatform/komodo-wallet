import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/views/wallet/coin_details/faucet/faucet_view.dart';

import 'cubit/faucet_cubit.dart';

class FaucetPage extends StatelessWidget {
  const FaucetPage({
    Key? key,
    required this.coinAbbr,
    required this.onBackButtonPressed,
    required this.coinAddress,
  }) : super(key: key);

  final String coinAbbr;
  final String? coinAddress;
  final VoidCallback onBackButtonPressed;

  @override
  Widget build(BuildContext context) {
    final kdfSdk = RepositoryProvider.of<KomodoDefiSdk>(context);
    return BlocProvider(
      create: (context) => FaucetCubit(coinAbbr: coinAbbr, kdfSdk: kdfSdk),
      child: FaucetView(
        onBackButtonPressed: onBackButtonPressed,
      ),
    );
  }
}
