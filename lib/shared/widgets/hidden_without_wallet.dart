import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/auth_bloc/auth_bloc.dart';
import 'package:komodo_wallet/model/wallet.dart';

class HiddenWithoutWallet extends StatelessWidget {
  const HiddenWithoutWallet(
      {Key? key, required this.child, this.isHiddenForHw = false})
      : super(key: key);
  final Widget child;
  final bool isHiddenForHw;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthBlocState>(builder: (context, state) {
      final Wallet? currentWallet = state.currentUser?.wallet;
      if (currentWallet == null) {
        return const SizedBox.shrink();
      }

      if (isHiddenForHw && currentWallet.isHW) {
        return const SizedBox.shrink();
      }

      return child;
    });
  }
}
