import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/model/wallet.dart';

class HiddenWithoutWallet extends StatelessWidget {
  const HiddenWithoutWallet({
    Key? key,
    required this.child,
    this.isHiddenForHw = false,
    this.isHiddenElse = true,
  }) : super(key: key);
  final Widget child;
  final bool isHiddenForHw;
  final bool isHiddenElse;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthBlocState>(
      builder: (context, state) {
        final Wallet? currentWallet = state.currentUser?.wallet;
        if (currentWallet == null) {
          if (isHiddenElse) {
            return const SizedBox.shrink();
          }
        }

        if (isHiddenForHw && currentWallet?.isHW == true) {
          return const SizedBox.shrink();
        }

        return child;
      },
    );
  }
}
