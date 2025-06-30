import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/widgets/copyable_address_dialog.dart';
import 'package:web_dex/views/wallet/coin_details/constants.dart';
import 'package:web_dex/views/wallet/coin_details/receive/receive_address_trezor.dart';

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
    final currentWallet = context.watch<AuthBloc>().state.currentUser?.wallet;
    if (currentWallet?.config.type == WalletType.trezor) {
      return ReceiveAddressTrezor(
        asset: asset,
        selectedAddress: selectedAddress,
        pubkeys: pubkeys,
        onChanged: onChanged,
      );
    }

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
