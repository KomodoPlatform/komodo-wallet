import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/views/wallet/coin_details/receive/qr_code_address.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class TrezorNewAddressConfirmation extends StatelessWidget {
  const TrezorNewAddressConfirmation({super.key, required this.address});
  final String address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          LocaleKeys.confirmOnTrezor.tr(),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        QRCodeAddress(currentAddress: address, size: 160),
        const SizedBox(height: 24),
        UiTextFormField(
          readOnly: true,
          initialValue: address,
          inputContentPadding: const EdgeInsets.fromLTRB(12, 22, 0, 22),
          suffixIcon: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 20, maxHeight: 20),
            child: IconButton(
              padding: const EdgeInsets.all(0.0),
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onPressed: () => copyToClipBoard(context, address),
              icon: const Icon(Icons.copy),
            ),
          ),
        ),
      ],
    );
  }
}
