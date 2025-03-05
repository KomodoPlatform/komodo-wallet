import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/ui/ui_primary_button.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/faucet_button/faucet_button_bloc.dart';
import 'package:web_dex/bloc/faucet_button/faucet_button_event.dart';
import 'package:web_dex/views/wallet/coin_details/faucet/cubit/faucet_state.dart';
import 'package:web_dex/views/wallet/coin_details/faucet/faucet_view.dart';

class FaucetButton extends StatefulWidget {
  const FaucetButton({
    super.key,
    required this.coinAbbr,
    required this.address,
    this.enabled = true,
  });

  final bool enabled;
  final String coinAbbr;
  final PubkeyInfo address;

  @override
  State<FaucetButton> createState() => _FaucetButtonState();
}

class _FaucetButtonState extends State<FaucetButton> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return BlocConsumer<FaucetBloc, FaucetState>(
      listenWhen: (previous, current) {
        return previous is! FaucetLoading && current is FaucetLoading;
      },
      listener: (context, state) {
        if (state is FaucetLoading && !_dialogShown) {
          _dialogShown = true;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => BlocProvider.value(
              value: context.read<FaucetBloc>(),
              child: FaucetView(
                coinAbbr: widget.coinAbbr,
                coinAddress: widget.address.address,
                onClose: () {
                  Navigator.of(dialogContext).pop();
                  _dialogShown = false;
                },
              ),
            ),
          ).then((_) => _dialogShown = false);
        }
      },
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.only(left: isMobile ? 4 : 8),
          child: Container(
            decoration: BoxDecoration(
              color: themeData.colorScheme.tertiary,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: UiPrimaryButton(
              key: const Key('coin-details-faucet-button'),
              height: isMobile ? 24.0 : 32.0,
              backgroundColor: themeData.colorScheme.tertiary,
              onPressed: state is FaucetLoading
                  ? null
                  : () {
                      print(
                          "🔥 Faucet button clicked for ${widget.coinAbbr} - ${widget.address.address}");
                      context.read<FaucetBloc>().add(FaucetRequested(
                            coinAbbr: widget.coinAbbr,
                            address: widget.address.address,
                          ));
                    },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 6.0 : 8.0,
                  horizontal: isMobile ? 8.0 : 12.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_drink_rounded,
                        color: Colors.blue, size: isMobile ? 14 : 16),
                    Text(
                      LocaleKeys.faucet.tr(),
                      style: TextStyle(
                          fontSize: isMobile ? 9 : 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
