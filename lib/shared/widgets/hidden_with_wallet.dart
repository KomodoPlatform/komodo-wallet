import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/auth_bloc/auth_bloc.dart';

class HiddenWithWallet extends StatelessWidget {
  const HiddenWithWallet({Key? key, required this.child}) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthBlocState>(builder: (context, state) {
      return state.currentUser == null ? child : const SizedBox.shrink();
    });
  }
}
