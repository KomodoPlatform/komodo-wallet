import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:web_dex/views/dex/common/front_plate.dart';

class WithdrawFormRecipientItem extends StatelessWidget {
  const WithdrawFormRecipientItem({
    super.key,
    required this.address,
    required this.onChanged,
    this.onQrScanned,
    this.validation,
    this.isValidating = false,
    this.errorText,
    this.asset,
  });

  final String address;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onQrScanned;
  final AddressValidation? validation;
  final bool isValidating;
  final String? Function()? errorText;
  final Asset? asset;

  @override
  Widget build(BuildContext context) {
    return FrontPlate(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecipientAddressField(
              address: address,
              onChanged: onChanged,
              onQrScanned: onQrScanned,
              validation: validation,
              isValidating: isValidating,
              errorText: errorText,
              asset: asset,
            ),
          ],
        ),
      ),
    );
  }
}