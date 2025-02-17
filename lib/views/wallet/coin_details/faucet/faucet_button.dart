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

    return address.isActiveForSwap
        ? Padding(
            padding: EdgeInsets.only(left: isMobile ? 4 : 8),
            child: UiPrimaryButton(
              key: const Key('coin-details-faucet-button'),
              height: isMobile ? 24.0 : 32.0,
              backgroundColor: themeData.colorScheme.tertiary,
              onPressed: onPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.local_drink_rounded, color: Colors.blue, size: isMobile ? 14 : 16),
                  ),
                  Text(
                    LocaleKeys.faucet.tr(),
                    style: TextStyle(fontSize: isMobile ? 10 : 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();
  }
}
