import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';

Future<PubkeyInfo?> showAddressSearch(
  BuildContext context, {
  required List<PubkeyInfo> addresses,
  required String assetNameLabel,
  bool Function(PubkeyInfo)? verified,
  void Function(PubkeyInfo)? onCopied,
  String searchHint = 'Search addresses',
  DropdownMenuItem<PubkeyInfo> Function(PubkeyInfo address, {bool? isVerified})?
  customItemBuilder,
}) {
  final theme = Theme.of(context);

  final items =
      addresses.map((address) {
        final isVerified = verified?.call(address) ?? false;

        return customItemBuilder?.call(address, isVerified: isVerified) ??
            DropdownMenuItem<PubkeyInfo>(
              value: address,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:
                            isVerified
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 18,
                          color:
                              isVerified
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                address.formatted,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (isVerified)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            // TODO: Properly localize this (including param)
                            '${address.balance.spendable} $assetNameLabel available',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onCopied != null)
                      IconButton(
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        style: IconButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(8),
                        ),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: address.address),
                          );
                          onCopied.call(address);
                        },
                        tooltip: 'Copy address',
                      ),
                  ],
                ),
              ),
            );
      }).toList();

  return showSearchableSelect<PubkeyInfo>(
    context: context,
    items: items,
    searchHint: searchHint,
  );
}

Widget showAddressSelectDropdown({
  required List<PubkeyInfo> addresses,
  required String assetName,
  required BuildContext context,
  PubkeyInfo? selectedAddress,
  String hint = 'Select Address',
  bool Function(PubkeyInfo)? verified,
  void Function(PubkeyInfo)? onCopied,
  ValueChanged<PubkeyInfo?>? onAddressSelected,
  InputDecoration? decoration,
  Widget Function(BuildContext, PubkeyInfo?)? customSelectedItemBuilder,
  Widget Function(PubkeyInfo, bool)? customItemBuilder,
}) {
  final theme = Theme.of(context);

  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: SearchableSelect<PubkeyInfo>(
      items:
          addresses.map((address) {
            final isVerified = verified?.call(address) ?? false;

            return DropdownMenuItem<PubkeyInfo>(
              value: address,
              child:
                  customItemBuilder?.call(address, isVerified) ??
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color:
                                isVerified
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 18,
                              color:
                                  isVerified
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    address.formatted,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  if (isVerified)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.verified,
                                        size: 16,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${address.balance.spendable} $assetName available',
                                style: theme.listTileTheme.subtitleTextStyle
                                    ?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (onCopied != null)
                          IconButton(
                            icon: const Icon(Icons.copy_outlined, size: 18),
                            style: IconButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(8),
                            ),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: address.address),
                              );
                              onCopied.call(address);
                            },
                            tooltip: 'Copy address',
                          ),
                      ],
                    ),
                  ),
            );
          }).toList(),
      value: selectedAddress,
      hint: hint,
      onChanged: onAddressSelected,
      decoration:
          decoration ??
          InputDecoration(
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            prefixIcon: Icon(
              Icons.account_balance_wallet_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
      selectedItemBuilder: (context, selected) {
        if (selected == null) return null;
        if (customSelectedItemBuilder != null) {
          return customSelectedItemBuilder(context, selected);
        }

        final isVerified = verified?.call(selected) ?? false;
        return Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    selected.formatted,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (isVerified) ...[
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '(${selected.balance.spendable} $assetName)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}
