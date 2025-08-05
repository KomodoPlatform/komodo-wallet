import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/bloc/staking/staking_creation/staking_creation_bloc.dart';
import 'package:web_dex/bloc/staking/staking_creation/staking_creation_event.dart';
import 'package:web_dex/bloc/staking/staking_rewards/staking_rewards_bloc.dart';
import 'package:web_dex/bloc/staking/staking_rewards/staking_rewards_event.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/views/staking/widgets/staking_asset_selector.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/views/staking/widgets/staking_creation_form.dart';
import 'package:web_dex/views/staking/widgets/staking_delegations_list.dart';
import 'package:web_dex/views/staking/widgets/staking_overview.dart';
import 'package:web_dex/views/staking/widgets/staking_rewards_view.dart';

/// Main staking page that provides access to staking functionality.
///
/// This page serves as the entry point for all staking operations including:
/// - Creating new stakes/delegations
/// - Viewing and claiming rewards
/// - Managing existing delegations
///
/// The page uses a tabbed interface similar to the wallet page.
class StakingPage extends StatefulWidget {
  const StakingPage({super.key, this.initialAssetId});

  /// Optional initial asset to pre-select for staking.
  final AssetId? initialAssetId;

  @override
  State<StakingPage> createState() => _StakingPageState();
}

class _StakingPageState extends State<StakingPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  AssetId? _selectedAssetId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedAssetId = widget.initialAssetId;

    // Check if there's a selected asset in routing state
    final selectedAssetConfigId = routingState.stakingState.selectedAssetId;
    if (selectedAssetConfigId.isNotEmpty && _selectedAssetId == null) {
      // Try to find the asset from the config ID
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAssetFromConfigId(selectedAssetConfigId);
      });
    }

    // Initialize with asset if provided
    if (_selectedAssetId != null) {
      _initializeWithAsset(_selectedAssetId!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAssetFromConfigId(String configId) {
    try {
      final coinsBloc = context.read<CoinsBloc>();
      final coin = coinsBloc.state.coins.values.firstWhere(
        (coin) => coin.id.symbol.assetConfigId == configId,
      );

      setState(() {
        _selectedAssetId = coin.id;
      });

      _initializeWithAsset(coin.id);
    } catch (e) {
      // Asset not found, clear the routing state
      routingState.stakingState.selectedAssetId = '';
    }
  }

  void _initializeWithAsset(AssetId assetId) {
    // Initialize blocs with the selected asset
    final stakingCreationBloc = context.read<StakingCreationBloc>();
    final stakingRewardsBloc = context.read<StakingRewardsBloc>();

    stakingCreationBloc.add(StakingCreationStarted(assetId: assetId));
    stakingRewardsBloc.add(StakingRewardsStarted(assetId: assetId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Staking Overview - Fixed at top
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 24,
              isMobile ? 16 : 32,
              isMobile ? 16 : 24,
              0,
            ),
            child: StakingOverview(
              key: const Key('staking-overview'),
              selectedAssetId: _selectedAssetId,
              onStakePressed: () => _tabController.animateTo(0),
              onRewardsPressed: () => _tabController.animateTo(1),
              onDelegationsPressed: () => _tabController.animateTo(2),
              onAssetChanged: (assetId) {
                setState(() {
                  _selectedAssetId = assetId;
                });
                _initializeWithAsset(assetId);
              },
            ),
          ),
          const SizedBox(height: 24),

          // Tab Bar - Fixed below overview
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Stake'),
                Tab(text: 'Rewards'),
                Tab(text: 'Delegations'),
              ],
            ),
          ),

          // Tab Content - Scrollable
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ColoredBox(color: Colors.red),
                _buildStakeTab(),

                ColoredBox(color: Colors.blue),

                // _buildRewardsTab(),
                ColoredBox(color: Colors.green),

                // _buildDelegationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStakeTab() {
    return _selectedAssetId != null
        // ? ColoredBox(color: Colors.red)
        ? StakingCreationForm(assetId: _selectedAssetId!)
        : _buildAssetSelector();
  }

  Widget _buildRewardsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: _selectedAssetId != null
          ? StakingRewardsView(assetId: _selectedAssetId!)
          : _buildAssetSelector(),
    );
  }

  Widget _buildDelegationsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: _selectedAssetId != null
          ? _buildDelegationsView()
          : _buildAssetSelector(),
    );
  }

  Widget _buildAssetSelector() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 64,
            color: theme.currentGlobal.colorScheme.primary,
          ),
          const Gap(16),
          Text(
            'Select Asset to Stake',
            style: theme.currentGlobal.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          UiPrimaryButton(text: 'Select Asset', onPressed: _showAssetSelector),
        ],
      ),
    );
  }

  Widget _buildDelegationsView() {
    if (_selectedAssetId == null) {
      return _buildAssetSelector();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Delegations',
          style: theme.currentGlobal.textTheme.headlineSmall,
        ),
        const Gap(16),
        Text(
          'Asset: ${_selectedAssetId!.symbol.assetConfigId}',
          style: theme.currentGlobal.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(24),
        StakingDelegationsList(assetId: _selectedAssetId!),
      ],
    );
  }

  void _showAssetSelector() async {
    final selectedAsset = await StakingAssetSelector.show(
      context,
      title: 'Select Asset to Stake',
    );

    if (selectedAsset != null) {
      setState(() {
        _selectedAssetId = selectedAsset;
      });

      // Update routing state with selected asset
      routingState.stakingState.selectedAssetId =
          selectedAsset.symbol.assetConfigId;

      // Initialize blocs with the selected asset
      _initializeWithAsset(selectedAsset);
    }
  }
}
