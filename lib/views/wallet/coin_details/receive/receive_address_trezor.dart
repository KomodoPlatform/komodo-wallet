import 'package:app_theme/app_theme.dart';
import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/views/wallet/coin_details/receive/request_address_button.dart';

class ReceiveAddressTrezor extends StatelessWidget {
  const ReceiveAddressTrezor(
      {required this.asset,
      required this.pubkeys,
      required this.onChanged,
      required this.selectedAddress,
      super.key});

  final Asset asset;
  final AssetPubkeys pubkeys;
  final void Function(PubkeyInfo?) onChanged;
  final PubkeyInfo? selectedAddress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedAddress == null)
          Text(
            LocaleKeys.trezorNoAddresses.tr(),
            style: theme.currentGlobal.textTheme.bodySmall,
          )
        else
          Row(
            children: [
              Flexible(
                child: SourceAddressField(
                  asset: asset,
                  pubkeys: pubkeys,
                  selectedAddress: selectedAddress,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 4),
              _buildCopyButton(context)
            ],
          ),
        _buildRequestButton(),
      ],
    );
  }

  Widget _buildRequestButton() {
    return RequestAddressButton(asset, onSuccess: onChanged);
  }

  Widget _buildCopyButton(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          copyToClipBoard(context, selectedAddress!.address);
        },
        borderRadius: BorderRadius.circular(20),
        child: UiTooltip(
          message: LocaleKeys.copyAddressToClipboard
              .tr(args: [asset.id.symbol.configSymbol]),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.copy,
              size: 16,
              color: theme.currentGlobal.textTheme.bodySmall?.color,
            ),
          ),
        ),
      ),
    );
  }
}
