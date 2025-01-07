import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/widgets/copied_text.dart';
import 'package:web_dex/views/wallet/coin_details/constants.dart';
import 'package:web_dex/views/wallet/coin_details/receive/receive_address_trezor.dart';

class ReceiveAddress extends StatelessWidget {
  const ReceiveAddress({
    Key? key,
    required this.coin,
    required this.onChanged,
    required this.selectedAddress,
    this.backgroundColor,
  }) : super(key: key);

  final Coin coin;
  final Function(String) onChanged;
  final String? selectedAddress;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final currentWallet = context.watch<AuthBloc>().state.currentUser?.wallet;
    if (currentWallet?.config.type == WalletType.trezor) {
      return ReceiveAddressTrezor(
        coin: coin,
        selectedAddress: selectedAddress,
        onChanged: onChanged,
      );
    }

    if (coin.address == null) {
      return Text(LocaleKeys.addressNotFound.tr());
    }
    return isMobile
        ? CopiedText(
            copiedValue: coin.address!,
            isTruncated: true,
            backgroundColor: backgroundColor,
          )
        : ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: receiveWidth),
            child: CopiedText(
              copiedValue: coin.address!,
              isTruncated: true,
              backgroundColor: backgroundColor,
            ),
          );
  }
}
