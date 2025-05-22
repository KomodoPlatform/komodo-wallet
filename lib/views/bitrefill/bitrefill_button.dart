import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/bitrefill/bloc/bitrefill_bloc.dart';
import 'package:web_dex/bloc/bitrefill/models/bitrefill_event.dart';
import 'package:web_dex/bloc/bitrefill/models/bitrefill_event_factory.dart';
import 'package:web_dex/bloc/bitrefill/models/bitrefill_payment_intent_event.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/views/bitrefill/bitrefill_inappwebview_button.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:get_it/get_it.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

/// A button that opens the Bitrefill widget in a new window or tab.
/// The Bitrefill widget is a web page that allows the user to purchase gift
/// cards and mobile top-ups with cryptocurrency.
///
/// The widget is disabled if the Bitrefill widget fails to load, if the coin
/// is not supported, or if the coin is suspended.
///
/// The widget returns a payment intent event when the user completes a purchase.
/// The event is passed to the [onPaymentRequested] callback.
class BitrefillButton extends StatefulWidget {
  const BitrefillButton({
    required this.coin,
    required this.onPaymentRequested,
    super.key,
    this.windowTitle = 'Bitrefill',
  });

  final Coin coin;
  final String windowTitle;
  final void Function(BitrefillPaymentIntentEvent) onPaymentRequested;

  @override
  State<BitrefillButton> createState() => _BitrefillButtonState();
}

class _BitrefillButtonState extends State<BitrefillButton> {
  @override
  void initState() {
    context
        .read<BitrefillBloc>()
        .add(BitrefillLoadRequested(coin: widget.coin));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    void handleMessage(String event) => _handleMessage(event, context);
    final KomodoDefiSdk sdk = GetIt.I<KomodoDefiSdk>();

    return BlocConsumer<BitrefillBloc, BitrefillState>(
      listener: (BuildContext context, BitrefillState state) {
        if (state is BitrefillPaymentInProgress) {
          widget.onPaymentRequested(state.paymentIntent);
        }
      },
      builder: (BuildContext context, BitrefillState state) {
        final bool bitrefillLoadSuccess = state is BitrefillLoadSuccess;
        bool isCoinSupported = false;
        if (bitrefillLoadSuccess) {
          isCoinSupported = state.supportedCoins.contains(widget.coin.abbr);
        }

        final double coinBalance =
            sdk.balances.lastKnown(widget.coin.id)?.spendable.toDouble() ?? 0.0;
        final bool hasNonZeroBalance = coinBalance > 0;

        final bool shouldShow =
            bitrefillLoadSuccess && isCoinSupported && !widget.coin.isSuspended;

        final bool isEnabled = shouldShow && hasNonZeroBalance;

        final String url = state is BitrefillLoadSuccess ? state.url : '';

        if (!shouldShow) {
          return const SizedBox.shrink();
        }

        // Show tooltip if balance is zero
        final String tooltipMessage =
            !hasNonZeroBalance ? LocaleKeys.zeroBalanceTooltip.tr() : '';

        return Tooltip(
          message: tooltipMessage,
          child: BitrefillInAppWebviewButton(
            key: Key(
                'coin-details-bitrefill-button-${widget.coin.abbr.toLowerCase()}'),
            windowTitle: widget.windowTitle,
            url: url,
            enabled: isEnabled,
            onMessage: handleMessage,
          ),
        );
      },
    );
  }

  /// Handles messages from the Bitrefill widget.
  /// The message is a JSON string that contains the event name and event data.
  /// The event name is used to create a [BitrefillWidgetEvent] object.
  void _handleMessage(String event, BuildContext context) {
    // Convert from JSON string to Map here to avoid library and
    // platform-specific javascript object conversion issues.
    final Map<String, dynamic> decodedEvent =
        jsonDecode(event) as Map<String, dynamic>;

    final BitrefillWidgetEvent bitrefillEvent =
        BitrefillEventFactory.createEvent(decodedEvent);
    if (bitrefillEvent is BitrefillPaymentIntentEvent) {
      context
          .read<BitrefillBloc>()
          .add(BitrefillPaymentIntentReceived(bitrefillEvent));
    }
  }
}
