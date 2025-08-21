import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/src/core/helpers/address_select_helper.dart';
import 'package:komodo_ui/src/utils/formatters/address_formatting.dart';

class AddressSelectInput extends StatelessWidget {
  // TODO: Add error message to the input widget as is the norm for inputs.
  const AddressSelectInput({
    required this.addresses,
    required this.onAddressSelected,
    required this.assetName,
    this.selectedAddress,
    this.hint = 'Select Address',
    this.verified,
    this.onCopied,
    super.key,
  });

  final List<PubkeyInfo> addresses;
  final ValueChanged<PubkeyInfo?>? onAddressSelected;
  final PubkeyInfo? selectedAddress;
  final String assetName;
  final String hint;
  final bool Function(PubkeyInfo)? verified;
  final void Function(PubkeyInfo)? onCopied;

  Future<void> _showSearch(BuildContext context) async {
    final result = await showAddressSearch(
      context,
      addresses: addresses,
      assetNameLabel: assetName,
      verified: verified,
      onCopied: onCopied,
      searchHint: hint,
    );

    if (result != null) {
      onAddressSelected?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onAddressSelected == null;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: InkWell(
        onTap: isDisabled ? null : () => _showSearch(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 20,
                color: theme.inputDecorationTheme.prefixIconColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child:
                    selectedAddress != null
                        ? Row(
                          children: [
                            Text(
                              selectedAddress!.formatted,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (verified?.call(selectedAddress!) ?? false) ...[
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              '(${selectedAddress!.balance.spendable} $assetName)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        )
                        : Text(
                          hint,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                // color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
