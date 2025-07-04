import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/model/hw_wallet/trezor_progress_status.dart';
import 'package:komodo_wallet/shared/ui/ui_light_button.dart';
import 'package:komodo_wallet/views/common/hw_wallet_dialog/constants.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class TrezorDialogInProgress extends StatelessWidget {
  const TrezorDialogInProgress(this.progressStatus,
      {Key? key, required this.onClose})
      : super(key: key);

  final TrezorProgressStatus? progressStatus;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const UiSpinner(
          width: 58,
          height: 58,
          strokeWidth: 4,
        ),
        const SizedBox(height: 48),
        Builder(builder: (context) {
          if (progressStatus ==
              TrezorProgressStatus.waitingForTrezorToConnect) {
            return _buildConnectTrezor();
          }
          if (progressStatus ==
              TrezorProgressStatus.followHwDeviceInstructions) {
            return _buildFollowInstructionsOnTrezor();
          }

          return Text(
            progressStatus?.name ?? LocaleKeys.inProgress.tr(),
            style: trezorDialogTitle,
          );
        })
      ],
    );
  }

  Widget _buildConnectTrezor() {
    return Column(
      children: [
        Text(LocaleKeys.trezorInProgressTitle.tr(), style: trezorDialogTitle),
        const SizedBox(height: 12),
        Text(
          LocaleKeys.trezorInProgressHint.tr(),
          style: trezorDialogDescription,
        ),
        const SizedBox(height: 24),
        UiLightButton(
          text: LocaleKeys.cancel.tr(),
          onPressed: () => onClose(),
        ),
      ],
    );
  }

  Widget _buildFollowInstructionsOnTrezor() {
    return Column(
      children: [
        Text(LocaleKeys.confirmOnTrezor.tr(), style: trezorDialogTitle),
        const SizedBox(height: 12),
        Text(
          LocaleKeys.followTrezorInstructions.tr(),
          style: trezorDialogDescription,
        ),
      ],
    );
  }
}
