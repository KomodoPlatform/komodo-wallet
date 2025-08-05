import 'package:flutter/material.dart';
import 'package:web_dex/router/state/menu_state_interface.dart';

/// State management for staking page routing
///
/// This class manages the state of the staking section including
/// selected asset for staking operations.
class StakingState extends ChangeNotifier implements IResettableOnLogout {
  /// Creates a new StakingState instance
  StakingState() : _selectedAssetId = '';

  /// The currently selected asset ID for staking
  String _selectedAssetId;

  /// Gets the currently selected asset ID
  String get selectedAssetId => _selectedAssetId;

  /// Sets the selected asset ID for staking
  set selectedAssetId(String assetId) {
    if (_selectedAssetId == assetId) {
      return;
    }
    _selectedAssetId = assetId;
    notifyListeners();
  }

  /// Resets the staking state to default values
  @override
  void reset() {
    selectedAssetId = '';
  }

  /// Resets state on logout
  @override
  void resetOnLogOut() {
    selectedAssetId = '';
  }
}
