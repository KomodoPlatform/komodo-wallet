import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:logging/logging.dart';

/// Repository for handling staking operations through the SDK.
///
/// This repository acts as a bridge between the staking BLoCs and the
/// KomodoDefiSdk's StakingManager, providing a clean abstraction layer
/// for all staking-related operations.
///
/// The repository follows the single responsibility principle by only
/// handling staking data operations and delegating business logic to
/// the appropriate BLoCs.
class StakingRepository {
  /// Creates a new StakingRepository instance.
  ///
  /// Requires a [KomodoDefiSdk] instance to access the staking functionality.
  StakingRepository({required KomodoDefiSdk sdk}) : _sdk = sdk;

  final KomodoDefiSdk _sdk;
  final _log = Logger('StakingRepository');

  /// Gets the staking manager from the SDK.
  ///
  /// Throws [StateError] if the SDK is not initialized.
  StakingManager get _stakingManager => _sdk.staking;

  /// Gets validator information for the specified asset.
  ///
  /// Returns a list of [ValidatorInfo] for the specified asset.
  /// This is used for validator selection and overview screens.
  ///
  /// Throws [Exception] if the operation fails.
  Future<List<ValidatorInfo>> getValidators(AssetId assetId) async {
    try {
      _log.info('Getting validators for asset: $assetId');
      return await _stakingManager.queryValidators(
        assetId,
        const StakingInfoDetails(type: 'Cosmos'),
      );
    } catch (e, stackTrace) {
      _log.severe('Failed to get validators for $assetId', e, stackTrace);
      rethrow;
    }
  }

  /// Gets delegation information for the specified asset.
  ///
  /// Returns a list of [DelegationInfo] with current delegations and rewards.
  /// This provides information about current staking positions.
  ///
  /// Throws [Exception] if the operation fails.
  Future<List<DelegationInfo>> getDelegations(AssetId assetId) async {
    try {
      _log.info('Getting delegations for asset: $assetId');
      return await _stakingManager.queryDelegations(
        assetId,
        infoDetails: const StakingInfoDetails(type: 'Cosmos'),
      );
    } catch (e, stackTrace) {
      _log.severe('Failed to get delegations for $assetId', e, stackTrace);
      rethrow;
    }
  }

  /// Stakes the specified amount with a specific validator.
  ///
  /// Performs delegation to the specified validator address.
  ///
  /// Returns transaction hash of the delegation operation.
  ///
  /// Throws [Exception] if the staking operation fails.
  Future<String> delegateToValidator({
    required AssetId assetId,
    required Decimal amount,
    required String validatorAddress,
  }) async {
    try {
      _log.info('Delegating $amount $assetId to validator: $validatorAddress');

      final details = StakingDetails(
        type: 'Cosmos',
        validatorAddress: validatorAddress,
        amount: amount.toString(),
      );

      final result = await _stakingManager.delegate(assetId, details);
      return result.txHash;
    } catch (e, stackTrace) {
      _log.severe(
        'Failed to delegate $amount $assetId to $validatorAddress',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Unstakes the specified amount from a validator.
  ///
  /// Performs undelegation from the specified validator address.
  ///
  /// Returns transaction hash of the undelegation operation.
  ///
  /// Throws [Exception] if the unstaking operation fails.
  Future<String> undelegateFromValidator({
    required AssetId assetId,
    required Decimal amount,
    required String validatorAddress,
  }) async {
    try {
      _log.info(
        'Undelegating $amount $assetId from validator: $validatorAddress',
      );

      final details = StakingDetails(
        type: 'Cosmos',
        validatorAddress: validatorAddress,
        amount: amount.toString(),
      );

      final result = await _stakingManager.undelegate(assetId, details);
      return result.txHash;
    } catch (e, stackTrace) {
      _log.severe(
        'Failed to undelegate $amount $assetId from $validatorAddress',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Claims rewards from a specific validator.
  ///
  /// Returns transaction hash of the claim operation.
  ///
  /// Throws [Exception] if the claim operation fails.
  Future<String> claimRewardsFromValidator({
    required AssetId assetId,
    required String validatorAddress,
  }) async {
    try {
      _log.info(
        'Claiming rewards from validator $validatorAddress for $assetId',
      );
      final details = ClaimingDetails(
        type: 'Cosmos',
        validatorAddress: validatorAddress,
      );
      final result = await _stakingManager.claimRewards(assetId, details);
      return result.txHash;
    } catch (e, stackTrace) {
      _log.severe(
        'Failed to claim rewards from validator $validatorAddress for $assetId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Gets recommended validators based on basic criteria.
  ///
  /// This is a simplified implementation that filters validators
  /// based on basic criteria like commission and activity status.
  ///
  /// Returns a list of [ValidatorInfo] sorted by recommendation score.
  ///
  /// Throws [Exception] if the operation fails.
  Future<List<ValidatorInfo>> getRecommendedValidators({
    required AssetId assetId,
    Decimal? maxCommission,
  }) async {
    try {
      _log.info('Getting recommended validators for $assetId');
      final validators = await getValidators(assetId);

      // Simple filtering by active status and jailed status
      var filtered = validators
          .where((v) => v.status == 3 && !v.jailed)
          .toList();

      if (maxCommission != null) {
        filtered = filtered.where((v) {
          final commissionRate = v.commission.currentRate;
          return commissionRate <= maxCommission;
        }).toList();
      }

      // Sort by commission rate (ascending)
      filtered.sort((a, b) {
        final aRate = a.commission.currentRate;
        final bRate = b.commission.currentRate;
        return aRate.compareTo(bRate);
      });

      return filtered;
    } catch (e, stackTrace) {
      _log.severe(
        'Failed to get recommended validators for $assetId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Validates a staking operation before execution.
  ///
  /// Returns a map indicating validation status and any error messages.
  /// This should be called before performing staking operations to provide
  /// user feedback and prevent failed transactions.
  Future<Map<String, dynamic>> validateStaking({
    required AssetId assetId,
    required Decimal amount,
    String? validatorAddress,
  }) async {
    try {
      _log.info(
        'Validating staking $amount $assetId to validator: $validatorAddress',
      );

      // Basic validation
      final validators = await getValidators(assetId);

      if (validatorAddress != null) {
        final validator = validators.firstWhere(
          (v) => v.operatorAddress == validatorAddress,
          orElse: () => throw Exception('Validator not found'),
        );

        if (validator.jailed) {
          return {'isValid': false, 'error': 'Validator is jailed'};
        }

        if (validator.status != 3) {
          return {'isValid': false, 'error': 'Validator is not active'};
        }
      }

      return {'isValid': true};
    } catch (e, stackTrace) {
      _log.severe('Failed to validate staking for $assetId', e, stackTrace);
      return {'isValid': false, 'error': e.toString()};
    }
  }

  /// Gets QTUM-specific staking information.
  ///
  /// Returns staking information for QTUM-type assets.
  /// This is useful for assets that support QTUM-style staking.
  Future<StakingInfosDetails?> getQtumStakingInfo(AssetId assetId) async {
    try {
      _log.info('Getting QTUM staking info for $assetId');
      // This method may not be available in all SDK versions
      // For now, return null to indicate QTUM staking is not supported
      return null;
    } catch (e, stackTrace) {
      _log.warning(
        'Failed to get QTUM staking info for $assetId',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// Disposes of any resources held by the repository.
  ///
  /// Should be called when the repository is no longer needed
  /// to prevent memory leaks.
  void dispose() {
    _log.info('Disposing StakingRepository');
  }
}
