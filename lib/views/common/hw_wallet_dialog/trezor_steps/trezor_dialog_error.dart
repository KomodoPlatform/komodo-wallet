import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:komodo_ui/komodo_ui.dart' show ErrorDisplay;
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/ui/ui_primary_button.dart';

class TrezorDialogError extends StatelessWidget {
  const TrezorDialogError(this.error, {Key? key}) : super(key: key);

  final String error;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: SvgPicture.asset('$assetsPath/ui_icons/error.svg'),
        ),
        ErrorDisplay(
          message: LocaleKeys.trezorErrorBusy.tr(),
          detailedMessage: error,
          showIcon: false,
        ),
        const SizedBox(height: 24),
        UiPrimaryButton(
          text: LocaleKeys.retryButtonText.tr(),
          onPressed: () => context.read<AuthBloc>().add(AuthTrezorCancelled()),
        ),
      ],
    );
  }
}
