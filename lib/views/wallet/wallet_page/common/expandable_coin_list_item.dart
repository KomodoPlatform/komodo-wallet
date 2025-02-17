// lib/src/defi/asset/coin_list_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/model/coin.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/widgets/coin_balance.dart';
import 'package:web_dex/shared/widgets/coin_fiat_balance.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item_size.dart';
import 'package:web_dex/views/wallet/common/wallet_helper.dart';

class ExpandableCoinListItem extends StatefulWidget {
  final Coin coin;
  final AssetPubkeys? pubkeys;
  final bool isSelected;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const ExpandableCoinListItem({
    super.key,
    required this.coin,
    required this.pubkeys,
    required this.isSelected,
    this.onTap,
    this.backgroundColor,
  });

  @override
  State<ExpandableCoinListItem> createState() => _ExpandableCoinListItemState();
}

class _ExpandableCoinListItemState extends State<ExpandableCoinListItem> {
  // Store the expansion state in the widget's state
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Attempt to restore state from PageStorage using a unique key
    _isExpanded = PageStorage.of(context).readState(
          context,
          identifier: '${widget.coin.abbr}_expanded',
        ) as bool? ??
        false;
  }

  void _handleExpansionChanged(bool expanded) {
    setState(() {
      _isExpanded = expanded;
      // Save state to PageStorage using a unique key
      PageStorage.of(context).writeState(
        context,
        _isExpanded,
        identifier: '${widget.coin.abbr}_expanded',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasAddresses = widget.pubkeys?.keys.isNotEmpty ?? false;
    final sortedAddresses = hasAddresses
        ? (List.of(widget.pubkeys!.keys)
          ..sort((a, b) => b.balance.spendable.compareTo(a.balance.spendable)))
        : null;

    return CollapsibleCard(
      key: PageStorageKey('coin_${widget.coin.abbr}'),
      borderRadius: BorderRadius.circular(12),
      headerPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      onTap: widget.onTap,
      childrenMargin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      childrenDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      initiallyExpanded: _isExpanded,
      onExpansionChanged: _handleExpansionChanged,
      expansionControlPosition: ExpansionControlPosition.leading,
      emptyChildrenBehavior: EmptyChildrenBehavior.disable,
      isDense: true,
      title: _buildTitle(context),
      maintainState: true,
      childrenDivider: const Divider(height: 1, indent: 16, endIndent: 16),
      trailing: CoinMoreActionsButton(coin: widget.coin),
      children: sortedAddresses
          ?.map(
            (pubkey) => _AddressRow(
              pubkey: pubkey,
              coin: widget.coin,
              isSwapAddress: pubkey == sortedAddresses.first,
              onTap: widget.onTap,
              onCopy: () => copyToClipBoard(context, pubkey.address),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 180),
            child: CoinItem(coin: widget.coin, size: CoinItemSize.large),
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: CoinBalance(coin: widget.coin),
            ),
          ),
          TrendPercentageText(
            investmentReturnPercentage: getTotal24Change([widget.coin]) ?? 0,
            iconSize: 16,
            spacing: 4,
            textStyle: theme.textTheme.bodyMedium,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final PubkeyInfo pubkey;
  final Coin coin;
  final bool isSwapAddress;
  final VoidCallback? onTap;
  final VoidCallback? onCopy;

  const _AddressRow({
    required this.pubkey,
    required this.coin,
    required this.isSwapAddress,
    required this.onTap,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        child: const Icon(Icons.person_outline),
      ),
      title: Row(
        children: [
          Text(
            pubkey.addressShort,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: IconButton(
              iconSize: 16,
              icon: const Icon(Icons.copy),
              onPressed: onCopy,
              visualDensity: VisualDensity.compact,
              // constraints: const BoxConstraints(
              //   minWidth: 32,
              //   minHeight: 32,
              // ),
            ),
          ),
          if (isSwapAddress && !kIsWalletOnly) ...[
            const SizedBox(width: 8),
            const Chip(
              label: Text(
                'Swap',
                // style: theme.textTheme.labelSmall,
              ),
              // backgroundColor: theme.colorScheme.primaryContainer,
            ),
          ],
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${doubleToString(pubkey.balance.spendable.toDouble())} ${coin.abbr}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          CoinFiatBalance(
            coin.copyWith(
              balance: pubkey.balance.spendable.toDouble(),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// This will be able to be removed in the near future when activation state
// is removed from the GUI because it is handled internall by the SDK.
class CoinMoreActionsButton extends StatelessWidget {
  const CoinMoreActionsButton({required this.coin});

  final Coin coin;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CoinMoreActions>(
      icon: const Icon(Icons.more_vert),
      onSelected: (action) {
        switch (action) {
          case CoinMoreActions.disable:
            context.read<CoinsBloc>().add(CoinsDeactivated([coin.abbr]));
            break;
        }
      },
      itemBuilder: (context) {
        return [
          const PopupMenuItem(
            value: CoinMoreActions.disable,
            child: Text('Disable'),
          ),
        ];
      },
    );
  }
}

enum CoinMoreActions {
  disable,
}
