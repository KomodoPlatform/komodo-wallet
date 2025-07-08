import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/wallets_manager_models.dart';
import 'package:web_dex/shared/ui/ui_primary_button.dart';

class WalletsManagerControls extends StatelessWidget {
  const WalletsManagerControls({
    Key? key,
    required this.onTap,
  }) : super(key: key);
  final Function(WalletsManagerAction) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildCreateButton(context),
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: _buildImportButton(context),
        ),
      ],
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return UiPrimaryButton(
      key: const Key('create-wallet-button'),
      height: 50,
      backgroundColor: Theme.of(context).colorScheme.onSurface,
      child: Row(
        children: [
          Icon(
            Icons.add,
            color: Theme.of(context).textTheme.labelLarge?.color,
            size: 15,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Text(
              LocaleKeys.walletsManagerCreateWalletButton.tr(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
      onPressed: () => onTap(WalletsManagerAction.create),
    );
  }

  Widget _buildImportButton(BuildContext context) => UiPrimaryButton(
        key: const Key('import-wallet-button'),
        height: 50,
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        onPressed: () => onTap(WalletsManagerAction.import),
        child: Row(
          children: [
            Icon(
              Icons.download,
              color: Theme.of(context).textTheme.labelLarge?.color,
              size: 15,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Text(
                LocaleKeys.walletsManagerImportWalletButton.tr(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      );
}
