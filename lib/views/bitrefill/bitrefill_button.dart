import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui/komodo_ui.dart' show showAddressSearch;
import 'package:web_dex/bloc/bitrefill/bloc/bitrefill_bloc.dart';
import 'package:web_dex/bloc/bitrefill/models/bitrefill_event.dart';
import 'package:web_dex/bloc/bitrefill/models/bitrefill_event_factory.dart';
import 'package:web_dex/bloc/bitrefill/models/bitrefill_payment_intent_event.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_bloc.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/views/bitrefill/bitrefill_inappwebview_button.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:get_it/get_it.dart';

/// A button that opens the Bitrefill widget in a new window or tab.
/// The Bitrefill widget is a web page that allows the user to purchase gift
/// cards and mobile top-ups with cryptocurrency.
///
/// The widget is disabled if the Bitrefill widget fails to load, if the coin
/// is not supported, or if the coin is suspended.
///
/// The widget returns a payment intent event when the user completes a purchase.
/// The event is passed to the [onPaymentRequested] callback.
///
/// Multi-address support: When the user has multiple addresses, an address
/// selector dialog will be shown allowing them to choose which address to use
/// as the refund address for the Bitrefill transaction.
class BitrefillButton extends StatefulWidget {
  const BitrefillButton({
    required this.coin,
    required this.onPaymentRequested,
    super.key,
    this.windowTitle = 'Bitrefill',
    this.tooltip,
  });

  final Coin coin;
  final String windowTitle;
  final String? tooltip;
  final void Function(BitrefillPaymentIntentEvent) onPaymentRequested;

  @override
  State<BitrefillButton> createState() => _BitrefillButtonState();
}

class _BitrefillButtonState extends State<BitrefillButton> {
  String? _selectedRefundAddress;

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

        final isShown =
            bitrefillLoadSuccess && isCoinSupported && !widget.coin.isSuspended;

        final isEnabled = isShown && hasNonZeroBalance || kDebugMode;

        final String url = state is BitrefillLoadSuccess ? state.url : '';

        if (!isShown) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            BitrefillInAppWebviewButton(
              windowTitle: widget.windowTitle,
              url: url,
              enabled: isEnabled,
              tooltip: _getTooltipMessage(
                  hasNonZeroBalance, isEnabled, isCoinSupported),
              onMessage: handleMessage,
              onPressed: () async =>
                  _handleButtonPress(context, hasNonZeroBalance),
            ),
          ],
        );
      },
    );
  }

  /// Gets the appropriate tooltip message based on balance and coin status
  String? _getTooltipMessage(
      bool hasNonZeroBalance, bool isEnabled, bool isCoinSupported) {
    if (widget.tooltip != null) {
      return widget.tooltip;
    }

    // Show tooltip when button is disabled to explain why
    if (!isEnabled) {
      if (widget.coin.isSuspended) {
        return '${widget.coin.abbr} is currently suspended';
      }

      if (!isCoinSupported) {
        return '${widget.coin.abbr} is not supported by Bitrefill';
      }

      if (!hasNonZeroBalance) {
        return 'No ${widget.coin.abbr} balance available for spending';
      }
    }

    return null;
  }

  /// Handles button press with address selection if needed
  Future<void> _handleButtonPress(
    BuildContext context,
    bool hasNonZeroBalance,
  ) async {
    if (!hasNonZeroBalance) {
      return; // Button should be disabled anyway
    }

    // Check if we need to show address selector
    final addressesBloc = context.read<CoinAddressesBloc>();
    final addresses = addressesBloc.state.addresses;

    if (addresses.length > 1) {
      // Show address selector if multiple addresses are available
      final selectedAddress = await showAddressSearch(
        context,
        addresses: addresses,
        assetNameLabel: widget.coin.abbr,
      );

      if (selectedAddress != null && context.mounted) {
        setState(() {
          _selectedRefundAddress = selectedAddress.address;
        });

        // Reload Bitrefill with new address
        context.read<BitrefillBloc>().add(
              BitrefillLoadRequested(
                coin: widget.coin,
                refundAddress: _selectedRefundAddress,
              ),
            );
      }
    }
    // If single address or no address selection needed, the button will work with existing URL
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
