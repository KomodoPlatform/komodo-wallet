import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/model/coin.dart';

/// A widget that displays an asset selection dialog specifically for staking.
/// This component filters assets to only show Tendermint/Cosmos chains that
/// support staking functionality.
class StakingAssetSelector extends StatelessWidget {
  const StakingAssetSelector({
    super.key,
    required this.onAssetSelected,
    this.title = 'Select Asset to Stake',
    this.searchHint = 'Search staking assets...',
  });

  final Function(AssetId) onAssetSelected;
  final String title;
  final String searchHint;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoinsBloc, CoinsState>(
      builder: (context, state) {
        final stakingAssets = _getStakingEligibleAssets(state);

        if (stakingAssets.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildAssetSelectionDialog(context, stakingAssets);
      },
    );
  }

  /// Filters assets to only include those that support staking.
  /// Currently, this includes Tendermint and TendermintToken chain types.
  List<AssetId> _getStakingEligibleAssets(CoinsState state) {
    final eligibleAssets = <AssetId>[];

    // Get all available coins and filter for staking-eligible ones
    for (final coin in state.coins.values) {
      // Check if the coin supports staking using comprehensive checks
      if (_isStakingEligible(coin)) {
        eligibleAssets.add(coin.id);
      }
    }

    return eligibleAssets;
  }

  /// Determines if a coin is eligible for staking based on its properties.
  /// Assets with TendermintChainId are eligible for staking.
  /// This method now has access to the full Coin data for more comprehensive checks.
  bool _isStakingEligible(Coin coin) {
    final assetId = coin.id;

    // Skip wallet-only coins as they typically don't support staking
    if (coin.walletOnly) {
      return false;
    }

    // Check if the chainId is a TendermintChainId which indicates Cosmos ecosystem
    if (assetId.chainId is TendermintChainId) {
      return true;
    }

    // Also check subClass for tendermint types
    return assetId.subClass == CoinSubClass.tendermint ||
        assetId.subClass == CoinSubClass.tendermintToken;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Staking Assets Available',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Activate Cosmos ecosystem coins to enable staking',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAssetSelectionDialog(
    BuildContext context,
    List<AssetId> assets,
  ) {
    return SizedBox(
      width: 400,
      height: 500,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: assets.length,
              itemBuilder: (context, index) {
                final asset = assets[index];
                return _AssetSelectionTile(
                  assetId: asset,
                  onTap: () {
                    onAssetSelected(asset);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the staking asset selection dialog
  static Future<AssetId?> show(
    BuildContext context, {
    String title = 'Select Asset to Stake',
  }) {
    return showDialog<AssetId>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: StakingAssetSelector(
          title: title,
          onAssetSelected: (asset) => Navigator.of(context).pop(asset),
        ),
      ),
    );
  }
}

/// A tile widget for displaying an individual asset in the selection list
class _AssetSelectionTile extends StatelessWidget {
  const _AssetSelectionTile({required this.assetId, required this.onTap});

  final AssetId assetId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: AssetLogo.ofId(assetId),
      title: Text(
        assetId.symbol.assetConfigId,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(assetId.name, style: Theme.of(context).textTheme.bodySmall),
          // Show chain information for Tendermint-based assets
          if (assetId.chainId is TendermintChainId) ...[
            const SizedBox(height: 2),
            Text(
              'Chain: ${(assetId.chainId as TendermintChainId).chainRegistryName}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
