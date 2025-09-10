import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/dex_repository.dart';
import 'package:web_dex/bloc/taker_form/taker_bloc.dart';
import 'package:web_dex/bloc/taker_form/taker_event.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/views/dex/simple/form/taker/taker_form_layout.dart';

class TakerForm extends StatefulWidget {
  const TakerForm({super.key});

  @override
  State<TakerForm> createState() => _TakerFormState();
}

class _TakerFormState extends State<TakerForm> {
  StreamSubscription<bool>? _coinsListener;

  @override
  void initState() {
    final authBlocState = context.read<AuthBloc>().state;
    final takerBloc = context.read<TakerBloc>();
    takerBloc.add(TakerSetDefaults());
    takerBloc.add(TakerSetWalletIsReady(authBlocState.isSignedIn));
    routingState.dexState.addListener(_consumeRouteParameters);
    super.initState();
  }

  void _consumeRouteParameters() async {
    final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
    final dexRepository = RepositoryProvider.of<DexRepository>(context);

    if (routingState.dexState.orderType == 'taker') {
      final fromCurrency = routingState.dexState.fromCurrency;
      final toCurrency = routingState.dexState.toCurrency;
      final fromAmount = routingState.dexState.fromAmount;
      routingState.dexState.clearDexParams();

      await dexRepository.waitOrderbookAvailability();

      if (mounted) {
        final takerBloc = context.read<TakerBloc>();
        Coin? sellCoin = fromCurrency.isNotEmpty
            ? coinsRepository.getCoin(fromCurrency)
            : null;
        Coin? buyCoin = toCurrency.isNotEmpty
            ? coinsRepository.getCoin(toCurrency)
            : null;

        if (sellCoin != null || buyCoin != null) {
          takerBloc.add(
            TakerSetSellCoin(sellCoin, autoSelectOrderAbbr: buyCoin?.abbr),
          );

          if (fromAmount.isNotEmpty) {
            Rational? sellAmount;
            try {
              sellAmount = Rational.parse(fromAmount);
            } catch (_) {}

            if (sellAmount != null) {
              takerBloc.add(TakerSetSellAmount(sellAmount));
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _coinsListener?.cancel();
    routingState.dexState.removeListener(_consumeRouteParameters);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthBlocState>(
      listenWhen: (previous, current) =>
          previous.isSignedIn != current.isSignedIn,
      listener: (context, state) {
        final takerBloc = context.read<TakerBloc>();
        takerBloc.add(TakerSetWalletIsReady(state.isSignedIn));
      },
      child: const TakerFormLayout(),
    );
  }
}
