import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/bloc/dex_repository.dart';
import 'package:web_dex/bloc/taker_form/taker_bloc.dart';
import 'package:web_dex/bloc/taker_form/taker_event.dart';
import 'package:web_dex/blocs/blocs.dart';
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
    final takerBloc = context.read<TakerBloc>();
    takerBloc.add(TakerSetDefaults());
    takerBloc.add(TakerSetWalletIsReady(coinsBloc.loginActivationFinished));
    _coinsListener = coinsBloc.outLoginActivationFinished.listen((value) {
      takerBloc.add(TakerSetWalletIsReady(value));
    });

    routingState.dexState.addListener(_consumeRouteParameters);
    super.initState();
  }

  void _consumeRouteParameters() async {
    if (routingState.dexState.orderType == 'taker') {
      final fromCurrency = routingState.dexState.fromCurrency;
      final toCurrency = routingState.dexState.toCurrency;
      final fromAmount = routingState.dexState.fromAmount;
      routingState.dexState.clearDexParams();

      await dexRepository.waitOrderbookAvailability();

      if (mounted) {
        final takerBloc = context.read<TakerBloc>();
        Coin? sellCoin =
            fromCurrency.isNotEmpty ? coinsBloc.getCoin(fromCurrency) : null;
        Coin? buyCoin =
            toCurrency.isNotEmpty ? coinsBloc.getCoin(toCurrency) : null;

        if (sellCoin != null || buyCoin != null) {
          takerBloc.add(
              TakerSetSellCoin(sellCoin, autoSelectOrderAbbr: buyCoin?.abbr));

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
    return const TakerFormLayout();
  }
}
