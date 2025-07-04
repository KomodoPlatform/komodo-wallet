import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_wallet/bloc/analytics/analytics_bloc.dart';
import 'package:komodo_wallet/bloc/analytics/analytics_event.dart';
import 'package:komodo_wallet/bloc/auth_bloc/auth_bloc.dart';
import 'package:komodo_wallet/bloc/coins_bloc/coins_bloc.dart';
import 'package:komodo_wallet/bloc/trezor_init_bloc/trezor_init_bloc.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/model/authorize_mode.dart';
import 'package:komodo_wallet/model/hw_wallet/init_trezor.dart';
import 'package:komodo_wallet/model/hw_wallet/trezor_status.dart';
import 'package:komodo_wallet/model/main_menu_value.dart';
import 'package:komodo_wallet/model/text_error.dart';
import 'package:komodo_wallet/router/state/routing_state.dart';
import 'package:komodo_wallet/views/common/hw_wallet_dialog/hw_dialog_init.dart';
import 'package:komodo_wallet/views/common/hw_wallet_dialog/trezor_steps/trezor_dialog_error.dart';
import 'package:komodo_wallet/views/common/hw_wallet_dialog/trezor_steps/trezor_dialog_in_progress.dart';
import 'package:komodo_wallet/views/common/hw_wallet_dialog/trezor_steps/trezor_dialog_message.dart';
import 'package:komodo_wallet/views/common/hw_wallet_dialog/trezor_steps/trezor_dialog_pin_pad.dart';
import 'package:komodo_wallet/views/common/hw_wallet_dialog/trezor_steps/trezor_dialog_select_wallet.dart';
import 'package:komodo_wallet/views/common/hw_wallet_dialog/trezor_steps/trezor_dialog_success.dart';
import 'package:komodo_wallet/views/wallets_manager/wallets_manager_events_factory.dart';

class HardwareWalletsManager extends StatelessWidget {
  const HardwareWalletsManager(
      {super.key, required this.close, required this.eventType});

  final WalletsManagerEventType eventType;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) {
    return HardwareWalletsManagerView(
      close: close,
      eventType: eventType,
    );
  }
}

class HardwareWalletsManagerView extends StatefulWidget {
  const HardwareWalletsManagerView({
    super.key,
    required this.eventType,
    required this.close,
  });
  final WalletsManagerEventType eventType;
  final VoidCallback close;

  @override
  State<HardwareWalletsManagerView> createState() =>
      _HardwareWalletsManagerViewState();
}

class _HardwareWalletsManagerViewState
    extends State<HardwareWalletsManagerView> {
  @override
  void initState() {
    context.read<TrezorInitBloc>().add(const TrezorInitReset());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TrezorInitBloc, TrezorInitState>(
      listener: (context, state) {
        final status = state.status;
        if (status?.trezorStatus == InitTrezorStatus.ok) {
          _successfulTrezorLogin(context, state.kdfUser!);
        }
      },
      child: BlocSelector<TrezorInitBloc, TrezorInitState, TextError?>(
        selector: (state) {
          return state.error;
        },
        builder: (context, error) {
          if (error != null) {
            return TrezorDialogError(error);
          }

          return _buildContent();
        },
      ),
    );
  }

  void _successfulTrezorLogin(BuildContext context, KdfUser kdfUser) {
    context.read<AuthBloc>().add(
          AuthModeChanged(mode: AuthorizeMode.logIn, currentUser: kdfUser),
        );
    context.read<CoinsBloc>().add(CoinsSessionStarted(kdfUser));
    context.read<AnalyticsBloc>().logEvent(
          walletsManagerEventsFactory.createEvent(
              widget.eventType, WalletsManagerEventMethod.hardware),
        );

    routingState.selectedMenu = MainMenuValue.wallet;
    widget.close();
  }

  Widget _buildContent() {
    return BlocSelector<TrezorInitBloc, TrezorInitState, InitTrezorStatusData?>(
      selector: (state) {
        return state.status;
      },
      builder: (context, initStatus) {
        switch (initStatus?.trezorStatus) {
          case null:
            return HwDialogInit(close: widget.close);

          case InitTrezorStatus.inProgress:
            return TrezorDialogInProgress(
              initStatus?.details.progressDetails,
              onClose: widget.close,
            );

          case InitTrezorStatus.userActionRequired:
            final TrezorUserAction? actionDetails =
                initStatus?.details.actionDetails;
            if (actionDetails == TrezorUserAction.enterTrezorPin) {
              return TrezorDialogPinPad(
                onComplete: (String pin) {
                  context.read<TrezorInitBloc>().add(TrezorInitSendPin(pin));
                },
                onClose: () async {
                  context.read<TrezorInitBloc>().add(const TrezorInitReset());
                },
              );
            } else if (actionDetails ==
                TrezorUserAction.enterTrezorPassphrase) {
              return TrezorDialogSelectWallet(
                onComplete: (String passphrase) {
                  context
                      .read<TrezorInitBloc>()
                      .add(TrezorInitSendPassphrase(passphrase));
                },
              );
            }

            return TrezorDialogMessage(
              '${LocaleKeys.userActionRequired.tr()}:'
              ' ${initStatus?.details.actionDetails?.name ?? LocaleKeys.unknown.tr().toLowerCase()}',
            );

          case InitTrezorStatus.error:
            return TrezorDialogError(initStatus?.details.errorDetails);

          case InitTrezorStatus.ok:
            return TrezorDialogSuccess(onClose: widget.close);

          default:
            return TrezorDialogMessage(initStatus!.trezorStatus.name);
        }
      },
    );
  }
}
