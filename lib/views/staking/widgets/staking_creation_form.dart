import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:web_dex/bloc/staking/staking_creation/staking_creation_bloc.dart';
import 'package:web_dex/bloc/staking/staking_creation/staking_creation_event.dart';
import 'package:web_dex/bloc/staking/staking_creation/staking_creation_state.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/shared/utils/asset_formatter.dart';

/// Form widget for creating new staking delegations.
///
/// This widget provides a user interface for:
/// - Selecting validators
/// - Entering stake amounts
/// - Validating staking parameters
/// - Submitting staking transactions
class StakingCreationForm extends StatefulWidget {
  const StakingCreationForm({super.key, required this.assetId});

  final AssetId assetId;

  @override
  State<StakingCreationForm> createState() => _StakingCreationFormState();
}

class _StakingCreationFormState extends State<StakingCreationForm> {
  final _amountController = TextEditingController();
  String? _selectedValidatorAddress;
  StakingStrategy _selectedStrategy = StakingStrategy.balanced;
  Decimal? _availableBalance;

  @override
  void initState() {
    super.initState();
    // Note: Validators are automatically loaded when the bloc is initialized with StakingCreationStarted
    // in the parent StakingPage, so we don't need to manually request them here.
    _loadAvailableBalance();
  }

  Future<void> _loadAvailableBalance() async {
    try {
      // Load available balance from coins bloc
      final coinsBloc = context.read<CoinsBloc>();
      final coin = coinsBloc.state.coins.values.firstWhere(
        (coin) => coin.id == widget.assetId,
        orElse: () => throw Exception('Asset not found'),
      );

      // Get balance from SDK using the extension method
      final sdk = context.read<KomodoDefiSdk>();
      final balanceInfo = coin.lastKnownBalance(sdk);

      setState(() {
        _availableBalance = balanceInfo?.spendable ?? Decimal.zero;
      });
    } catch (e) {
      // Fallback to zero if balance can't be loaded
      setState(() {
        _availableBalance = Decimal.zero;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged(Decimal? amount) {
    if (amount != null) {
      context.read<StakingCreationBloc>().add(
        StakingCreationAmountChanged(amount: amount),
      );
    }
  }

  void _onStrategyChanged(StakingStrategy strategy) {
    setState(() {
      _selectedStrategy = strategy;
      // Reset validator selection when changing strategy
      _selectedValidatorAddress = null;
    });
    // TODO: Add strategy support to the bloc
  }

  void _onValidatorSelected(String validatorAddress) {
    setState(() {
      _selectedValidatorAddress = validatorAddress;
    });
    context.read<StakingCreationBloc>().add(
      StakingCreationValidatorSelected(validatorAddress: validatorAddress),
    );
  }

  void _onSubmit() {
    context.read<StakingCreationBloc>().add(const StakingCreationSubmitted());
  }

  /// Convert ValidatorInfo to EnhancedValidatorInfo for komodo_ui widgets
  EnhancedValidatorInfo _convertToEnhancedValidator(ValidatorInfo validator) {
    // Get rid of theis enhanced BS. Rather amend the original validator types.
    return EnhancedValidatorInfo(
      description: validator.description.details,

      address: validator.operatorAddress,
      name: validator.description.moniker,
      commission: validator.commission.commissionRates.rateDecimal,
      votingPower: Decimal.zero, // Would need total staked to calculate
      uptime: Decimal.parse('0.99'), // Not available in ValidatorInfo
      isJailed: validator.jailed,
      isActive: validator.status == 3, // Status 3 is bonded/active
      // delegationCount: 0, // Not available in ValidatorInfo
      totalDelegated: Decimal.zero, // Would need to query
      // minDelegation:
      //     Decimal.tryParse(validator.minSelfDelegation) ?? Decimal.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StakingCreationBloc, StakingCreationState>(
      listener: (context, state) {
        if (state.status == StakingCreationStatus.success &&
            state.transactionHash != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Staking transaction submitted successfully!',
              ),
              backgroundColor: theme.currentGlobal.colorScheme.primary,
            ),
          );
        } else if (state.status == StakingCreationStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'An unknown error occurred'),
              backgroundColor: theme.currentGlobal.colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == StakingCreationStatus.success &&
            state.transactionHash != null) {
          return _buildSuccessView(state.transactionHash!);
        } else if (state.status == StakingCreationStatus.failure) {
          return _buildErrorView(
            state.errorMessage ?? 'An unknown error occurred',
          );
        }

        return _buildForm(state);
      },
    );
  }

  Widget _buildSuccessView(String transactionHash) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: theme.currentGlobal.colorScheme.primary,
          ),
          const Gap(16),
          Text(
            'Staking Transaction Submitted',
            style: theme.currentGlobal.textTheme.headlineSmall,
          ),
          const Gap(8),
          Text(
            'Transaction Hash: $transactionHash',
            style: theme.currentGlobal.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          UiPrimaryButton(
            text: 'Create Another',
            onPressed: () {
              context.read<StakingCreationBloc>().add(
                const StakingCreationReset(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error,
            size: 64,
            color: theme.currentGlobal.colorScheme.error,
          ),
          const Gap(16),
          Text(
            'Staking Failed',
            style: theme.currentGlobal.textTheme.headlineSmall,
          ),
          const Gap(8),
          Text(
            errorMessage,
            style: theme.currentGlobal.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          UiPrimaryButton(
            text: 'Try Again',
            onPressed: () {
              context.read<StakingCreationBloc>().add(
                const StakingCreationReset(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForm(StakingCreationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const Gap(24),
        _buildAmountSection(state),
        const Gap(24),
        _buildStrategySection(state),
        const Gap(24),
        _buildValidatorSection(state),
        const Gap(24),
        _buildValidationSection(state),
        const Gap(24),
        _buildSubmitSection(state),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.currentGlobal.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          bottom: BorderSide(
            color: theme.currentGlobal.colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.add_circle_outline,
            color: theme.currentGlobal.colorScheme.primary,
            size: 24,
          ),
          const Gap(12),
          Text(
            'Create New Stake',
            style: theme.currentGlobal.textTheme.headlineSmall?.copyWith(
              color: theme.currentGlobal.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection(StakingCreationState state) {
    if (_availableBalance == null) {
      return const Center(child: UiSpinner());
    }

    // Get the coin to access asset info
    final coinsBloc = context.read<CoinsBloc>();
    final coin = coinsBloc.state.coins.values.firstWhere(
      (coin) => coin.id == widget.assetId,
      orElse: () => throw Exception('Asset not found'),
    );

    // Convert to SDK Asset for the widget
    final sdk = context.read<KomodoDefiSdk>();
    final asset = coin.toSdkAsset(sdk);

    return StakeAmountInput(
      asset: asset,
      availableBalance: _availableBalance!,
      onAmountChanged: _onAmountChanged,
      initialAmount: state.amount,
    );
  }

  Widget _buildStrategySection(StakingCreationState state) {
    return StakingStrategySelector(
      selectedStrategy: _selectedStrategy,
      onStrategyChanged: _onStrategyChanged,
    );
  }

  Widget _buildValidatorSection(StakingCreationState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.currentGlobal.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedStrategy == StakingStrategy.custom
                    ? 'Select Validator'
                    : 'Recommended Validators',
                style: theme.currentGlobal.textTheme.titleMedium?.copyWith(
                  color: theme.currentGlobal.colorScheme.onSurface,
                ),
              ),
              if (state.validators.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: state.isLoadingValidators
                      ? null
                      : () {
                          context.read<StakingCreationBloc>().add(
                            const StakingCreationValidatorsRequested(),
                          );
                        },
                  tooltip: 'Refresh validators',
                ),
            ],
          ),
          const Gap(16),
          if (state.isLoadingValidators) ...[
            const Center(child: UiSpinner()),
          ] else if (state.validators.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.currentGlobal.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: theme.currentGlobal.colorScheme.error,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      'No validators available. Please check your connection or try refreshing.',
                      style: theme.currentGlobal.textTheme.bodyMedium?.copyWith(
                        color: theme.currentGlobal.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              _selectedStrategy == StakingStrategy.custom
                  ? 'Select a validator to delegate to:'
                  : 'Based on ${_selectedStrategy.name} strategy:',
              style: theme.currentGlobal.textTheme.bodySmall?.copyWith(
                color: theme.currentGlobal.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(12),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: _selectedStrategy == StakingStrategy.custom
                    ? state.validators.length
                    : (state.validators.length > 5
                          ? 5
                          : state.validators.length),
                itemBuilder: (context, index) {
                  final validator = state.validators[index];
                  final isSelected =
                      _selectedValidatorAddress == validator.operatorAddress;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ValidatorListItem(
                      validator: _convertToEnhancedValidator(validator),
                      isSelected: isSelected,
                      onTap: () =>
                          _onValidatorSelected(validator.operatorAddress),
                      showScore: _selectedStrategy != StakingStrategy.custom,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValidationSection(StakingCreationState state) {
    if (state.validationResult == null) return const SizedBox.shrink();

    // Safely handle validation result which might be a Map
    final isValid = state.validationResult is Map
        ? (state.validationResult as Map)['isValid'] as bool? ?? false
        : true; // Default to valid if not a map
    final message = state.validationResult is Map
        ? (state.validationResult as Map)['message'] as String? ?? ''
        : state.validationResult.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isValid
            ? theme.currentGlobal.colorScheme.primaryContainer
            : theme.currentGlobal.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Validation: ${isValid ? 'Valid' : 'Invalid'}',
            style: theme.currentGlobal.textTheme.titleSmall,
          ),
          if (message.isNotEmpty) ...[
            const Gap(8),
            Text(message, style: theme.currentGlobal.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitSection(StakingCreationState state) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: UiPrimaryButton(
            onPressed:
                state.status != StakingCreationStatus.submitting &&
                    (state.canSubmit)
                ? _onSubmit
                : null,
            text: state.status == StakingCreationStatus.submitting
                ? 'Submitting...'
                : 'Confirm Stake',
          ),
        ),
        const Gap(16),
        UiSecondaryButton(
          onPressed: () {
            context.read<StakingCreationBloc>().add(
              const StakingCreationReset(),
            );
          },
          text: 'Reset Form',
        ),
      ],
    );
  }
}
