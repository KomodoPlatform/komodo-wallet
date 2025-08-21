import 'package:flutter/material.dart';
import 'package:komodo_ui/komodo_ui.dart';

/// A specialized card for displaying crypto asset information with expandable wallet addresses.
///
/// This component builds upon [CollapsibleCard] to provide a consistent way to display
/// crypto asset information including balance, price changes, and associated wallet addresses.
///
/// ```dart
/// CryptoAssetCard(
///   assetName: 'Solana',
///   assetCode: 'SOL',
///   balance: '19.92',
///   balanceInUSD: '\$3012.50',
///   changePercentage: '10.00',
///   protocol: 'BEP-20',
///   addresses: [
///     WalletAddress(
///       label: 'Wallet 1',
///       address: '0x4cd...fv84',
///       balance: '5.92',
///     ),
///   ],
/// )
/// ```
class CryptoAssetCard extends StatelessWidget {
  const CryptoAssetCard({
    required this.assetName,
    required this.assetCode,
    required this.balance,
    required this.balanceInUSD,
    required this.changePercentage,
    super.key,
    this.protocol,
    this.assetIcon,
    this.addresses = const [],
    this.onCopyAddress,
    this.onTap,
  });
  final String assetName;
  final String assetCode;
  final String balance;
  final String balanceInUSD;
  final String changePercentage;
  final String? protocol;
  final Widget? assetIcon;
  final List<WalletAddressEntry> addresses;
  final VoidCallback? onCopyAddress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CollapsibleCard(
      backgroundColor: theme.cardTheme.color,
      expandedBackgroundColor: theme.cardTheme.color,
      // borderRadius: theme.cardTheme.shape?.borderRadius,
      onExpansionChanged: (_) => onTap?.call(),
      leading:
          assetIcon ??
          CircleAvatar(
            backgroundColor: theme.colorScheme.surface,
            child: Text(assetCode[0], style: theme.textTheme.titleMedium),
          ),
      title: Row(
        children: [
          Text(assetName, style: theme.textTheme.titleMedium),
          if (protocol != null) ...[
            const SizedBox(width: 8),
            _ProtocolBadge(protocol: protocol!),
          ],
        ],
      ),
      subtitle: Text(
        '$balance $assetCode ($balanceInUSD)',
        style: theme.textTheme.bodyMedium,
      ),
      trailing: _PriceChangeIndicator(changePercentage: changePercentage),
      divider: const Divider(height: 1),
      children:
          addresses
              .map(
                (address) => _AddressRow(
                  address: address,
                  assetCode: assetCode,
                  onCopy: onCopyAddress,
                ),
              )
              .toList(),
    );
  }
}

class _ProtocolBadge extends StatelessWidget {
  const _ProtocolBadge({required this.protocol});
  final String protocol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(protocol, style: theme.textTheme.labelSmall),
    );
  }
}

class _PriceChangeIndicator extends StatelessWidget {
  const _PriceChangeIndicator({required this.changePercentage});
  final String changePercentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = !changePercentage.startsWith('-');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isPositive
                ? theme.colorScheme.primary
                : theme.colorScheme.error)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${isPositive ? '+' : ''}$changePercentage%',
        style: theme.textTheme.labelMedium?.copyWith(
          color:
              isPositive ? theme.colorScheme.primary : theme.colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.address,
    required this.assetCode,
    this.onCopy,
  });

  final WalletAddressEntry address;
  final String assetCode;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.surface,
            child: Text(address.label[0], style: theme.textTheme.labelMedium),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(address.address, style: theme.textTheme.bodyMedium),
                Text(
                  '${address.balance} $assetCode',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, color: theme.iconTheme.color, size: 20),
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}

/// Represents a wallet address with its associated information.
typedef WalletAddressEntry = ({String label, String address, String balance});
