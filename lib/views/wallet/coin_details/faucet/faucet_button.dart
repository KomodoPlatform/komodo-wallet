import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/ui/ui_primary_button.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

class FaucetButton extends StatelessWidget {
  const FaucetButton({
    Key? key,
    required this.onPressed,
    required this.address,
    this.enabled = true,
  }) : super(key: key);

  final bool enabled;
  final VoidCallback onPressed;
  final PubkeyInfo address;

  @override
Widget build(BuildContext context) {
  final ThemeData themeData = Theme.of(context);
  debugPrint("FaucetButton is being built! isActiveForSwap: ${address.isActiveForSwap}");

  return address.isActiveForSwap
      ? Padding(
          padding: EdgeInsets.only(left: isMobile ? 4 : 8),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 6 : 8,
              horizontal: isMobile ? 8 : 12.0,
            ),
            decoration: BoxDecoration(
              color: themeData.colorScheme.tertiary,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: UiPrimaryButton(
              key: const Key('coin-details-faucet-button'),
              height: isMobile ? 12.0 : 18.0,
              backgroundColor: themeData.colorScheme.tertiary,
              onPressed: onPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.local_drink_rounded, color: Colors.blue, size: isMobile ? 14 : 16),
                  ),
                  Text(
                    LocaleKeys.faucet.tr(),
                    style: TextStyle(fontSize: isMobile ? 9 : 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        )
      : const SizedBox.shrink();
}

}
