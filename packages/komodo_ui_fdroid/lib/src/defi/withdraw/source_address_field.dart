import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';

class SourceAddressField extends StatelessWidget {
  const SourceAddressField({
    required this.asset,
    required this.pubkeys,
    required this.selectedAddress,
    required this.onChanged,
    this.networkError,
    this.onRetry,
    this.isLoading = false,
    this.showBalanceIndicator = true,
    this.title,
    super.key,
  });

  final Asset asset;
  final AssetPubkeys? pubkeys;
  final PubkeyInfo? selectedAddress;
  final ValueChanged<PubkeyInfo?>? onChanged;
  final String? networkError;
  final VoidCallback? onRetry;
  final bool isLoading;
  final bool showBalanceIndicator;
  final Widget? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Display loading state
    if (isLoading) {
      return _LoadingState(asset: asset);
    }

    // Display error state
    if (pubkeys == null || pubkeys!.keys.isEmpty) {
      return _ErrorState(
        message: networkError ?? 'No addresses available',
        onRetry: onRetry,
      );
    }

    // Display the address selector
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            title ??
                Text(
                  'Source Address',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
            if (pubkeys!.keys.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${pubkeys!.keys.length} addresses available',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        AddressSelectInput(
          addresses: pubkeys!.keys,
          selectedAddress: selectedAddress,
          onAddressSelected: onChanged,
          assetName: asset.id.name,
          hint: 'Choose source address',
          onCopied: (address) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('Address copied to clipboard'),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                width: 280,
                backgroundColor: theme.colorScheme.primary,
              ),
            );
          },
          verified: _isAddressVerified,
        ),
        if (selectedAddress != null && showBalanceIndicator) ...[
          const SizedBox(height: 12),
          _BalanceIndicator(
            balance: selectedAddress!.balance,
            assetName: asset.id.name,
            status: _getAddressStatus(selectedAddress!),
          ),
        ],
      ],
    );
  }

  bool _isAddressVerified(PubkeyInfo address) {
    return _getAddressStatus(address) == AddressStatus.available;
  }

  AddressStatus _getAddressStatus(PubkeyInfo address) {
    if (address.balance.spendable <= Decimal.zero &&
        address.balance.unspendable <= Decimal.zero) {
      return AddressStatus.empty;
    }
    if (address.balance.spendable > Decimal.zero) {
      return AddressStatus.available;
    }
    return AddressStatus.locked;
  }
}

enum AddressStatus { available, locked, empty }

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 32,
              width: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text('Loading addresses...', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Fetching your ${asset.id.name} addresses',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: theme.colorScheme.onErrorContainer,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "We couldn't load your wallet addresses. "
              'Please check your connection and try again.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer.withValues(
                  alpha: 0.8,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.onErrorContainer,
                    foregroundColor: theme.colorScheme.errorContainer,
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BalanceIndicator extends StatelessWidget {
  const _BalanceIndicator({
    required this.balance,
    required this.assetName,
    required this.status,
  });

  final Balance balance;
  final String assetName;
  final AddressStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case AddressStatus.available:
        statusColor = theme.colorScheme.primary;
        statusIcon = Icons.check_circle;
        statusText = 'Available';
      case AddressStatus.locked:
        statusColor = theme.colorScheme.tertiary;
        statusIcon = Icons.lock;
        statusText = 'Funds Locked';
      case AddressStatus.empty:
        statusColor = theme.colorScheme.error;
        statusIcon = Icons.warning;
        statusText = 'No Funds Available';
    }

    return Card(
      elevation: 0,
      color: statusColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (status == AddressStatus.available)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Ready to Send',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Available:', style: theme.textTheme.bodyMedium),
                Text(
                  '${balance.spendable} $assetName',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (balance.unspendable > Decimal.zero) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Locked:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    '${balance.unspendable} $assetName',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
            if (balance.spendable > Decimal.zero &&
                status == AddressStatus.available) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Maximum sendable amount: ${balance.spendable} $assetName',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
