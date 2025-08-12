import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';

Future<AssetId?> showCoinSearch(
  BuildContext context, {
  required List<AssetId> coins,
  DropdownMenuItem<AssetId> Function(AssetId coinId)? customCoinItemBuilder,
}) {
  final theme = Theme.of(context);
  final items =
      coins.map((assetId) {
        return customCoinItemBuilder?.call(assetId) ??
            DropdownMenuItem<AssetId>(
              value: assetId,
              child: Row(
                children: [
                  AssetIcon(assetId),
                  const SizedBox(width: 12),
                  Text(assetId.name, style: theme.listTileTheme.titleTextStyle),
                ],
              ),
            );
      }).toList();

  return showSearchableSelect<AssetId>(
    context: context,
    items: items,
    searchHint: 'Search coins', //TODO: Localize
  );
}
