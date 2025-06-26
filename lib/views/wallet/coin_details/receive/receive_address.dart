import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/widgets/copyable_address_dialog.dart';
import 'package:web_dex/views/wallet/coin_details/constants.dart';

class ReceiveAddress extends StatelessWidget {
  const ReceiveAddress({
    required this.asset,
    required this.onChanged,
    required this.selectedAddress,
    required this.pubkeys,
    this.backgroundColor,
    super.key,
  });

  final Asset asset;
  final AssetPubkeys pubkeys;
  final PubkeyInfo? selectedAddress;
  final Color? backgroundColor;
  final void Function(PubkeyInfo?) onChanged;

  @override
  Widget build(BuildContext context) {
    if (selectedAddress == null) {
      return Text(LocaleKeys.addressNotFound.tr());
    }
    return isMobile
        ? CopyableAddressDialog(
            address: selectedAddress,
            asset: asset,
            pubkeys: pubkeys,
            backgroundColor: Theme.of(context).colorScheme.surface,
            onAddressChanged: onChanged,
          )
        : ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: receiveWidth),
            child: CopyableAddressDialog(
              address: selectedAddress,
              asset: asset,
              pubkeys: pubkeys,
              backgroundColor: Theme.of(context).colorScheme.surface,
              onAddressChanged: onChanged,
            ),
          );
  }
}
