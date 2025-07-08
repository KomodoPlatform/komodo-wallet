import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/trezor_init_bloc/trezor_init_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/model/hw_wallet/trezor_status_error.dart';
import 'package:web_dex/shared/ui/ui_primary_button.dart';
import 'package:web_dex/views/common/hw_wallet_dialog/constants.dart';

class TrezorDialogError extends StatelessWidget {
  const TrezorDialogError(this.error, {Key? key}) : super(key: key);

  final dynamic error;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: SvgPicture.asset('$assetsPath/ui_icons/error.svg'),
        ),
        Text(_errorMessage, style: trezorDialogSubtitle),
        const SizedBox(height: 24),
        UiPrimaryButton(
          text: LocaleKeys.retryButtonText.tr(),
          onPressed: () =>
              context.read<TrezorInitBloc>().add(const TrezorInitReset()),
        ),
      ],
    );
  }

  String _parseErrorMessage(TrezorStatusError? error) {
    if (error != null && error.error.contains('Error claiming an interface')) {
      return LocaleKeys.trezorErrorBusy.tr();
    }

    switch (error?.errorData) {
      case TrezorStatusErrorData.invalidPin:
        return LocaleKeys.trezorErrorInvalidPin.tr();
      default:
        return error?.error ?? LocaleKeys.somethingWrong.tr();
    }
  }

  String get _errorMessage {
    if (error is TrezorStatusError) {
      return _parseErrorMessage(error);
    }
    if (error is BaseError) {
      return error.message;
    }

    return error.toString();
  }
}
