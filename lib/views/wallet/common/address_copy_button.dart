import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/shared/utils/utils.dart';

class AddressCopyButton extends StatelessWidget {
  final String address;
  final String coinAbbr;

  const AddressCopyButton(
      {super.key, required this.address, this.coinAbbr = ''});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      splashRadius: 18,
      icon: const Icon(Icons.copy, size: 16),
      color: Theme.of(context).textTheme.bodyMedium!.color,
      onPressed: () {
        copyToClipBoard(
            context,
            address,
            coinAbbr.isNotEmpty
                ? LocaleKeys.copiedAddressToClipboard.tr(args: [coinAbbr])
                : null);
      },
    );
  }
}
