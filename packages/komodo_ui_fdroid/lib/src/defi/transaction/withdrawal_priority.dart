import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/src/core/displays/fee_info_display.dart';
import 'package:komodo_ui/src/utils/formatters/fee_info_formatters.dart';

/// A widget for selecting withdrawal fee priority levels.
///
/// This widget displays fee options for different priority levels (low, medium, high)
/// and allows users to select their preferred option. It supports all fee types
/// including the new EIP1559 fee structure for Ethereum-based transactions.
///
/// **Note:** Fee estimation features are currently disabled as the API endpoints
/// are not yet available. When disabled, this widget will show a disabled state
/// with appropriate messaging.
class WithdrawalPrioritySelector extends StatelessWidget {
  const WithdrawalPrioritySelector({
    required this.feeOptions,
    required this.selectedPriority,
    required this.onPriorityChanged,
    this.showCustomFeeOption = true,
    this.onCustomFeeSelected,
    super.key,
  });

  /// The available fee options for different priority levels
  final WithdrawalFeeOptions? feeOptions;

  /// The currently selected priority level
  final WithdrawalFeeLevel? selectedPriority;

  /// Callback when priority level changes
  final ValueChanged<WithdrawalFeeLevel> onPriorityChanged;

  /// Whether to show a custom fee option
  final bool showCustomFeeOption;

  /// Callback when custom fee is selected
  final VoidCallback? onCustomFeeSelected;

  @override
  Widget build(BuildContext context) {
    if (feeOptions == null) {
      return _buildDisabledState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Priority',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildPriorityOptions(context),
        if (showCustomFeeOption) ...[
          const SizedBox(height: 8),
          _buildCustomFeeOption(context),
        ],
      ],
    );
  }

  Widget _buildDisabledState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Priority',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fee estimation temporarily unavailable',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Fee estimation features are currently disabled as the API endpoints are not yet available. '
                  'You can still proceed with withdrawals using custom fee settings.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (showCustomFeeOption) ...[
                  ElevatedButton.icon(
                    onPressed: onCustomFeeSelected,
                    icon: const Icon(Icons.settings),
                    label: const Text('Set Custom Fee'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Priority',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading fee options...'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityOptions(BuildContext context) {
    return Column(
      children: [
        _PriorityOption(
          title: 'Slow',
          subtitle: 'Lowest cost, slowest confirmation',
          fee: feeOptions!.low,
          isSelected: selectedPriority == WithdrawalFeeLevel.low,
          onSelect: () => onPriorityChanged(WithdrawalFeeLevel.low),
        ),
        const SizedBox(height: 8),
        _PriorityOption(
          title: 'Standard',
          subtitle: 'Balanced cost and confirmation time',
          fee: feeOptions!.medium,
          isSelected: selectedPriority == WithdrawalFeeLevel.medium,
          onSelect: () => onPriorityChanged(WithdrawalFeeLevel.medium),
        ),
        const SizedBox(height: 8),
        _PriorityOption(
          title: 'Fast',
          subtitle: 'Highest cost, fastest confirmation',
          fee: feeOptions!.high,
          isSelected: selectedPriority == WithdrawalFeeLevel.high,
          onSelect: () => onPriorityChanged(WithdrawalFeeLevel.high),
        ),
      ],
    );
  }

  Widget _buildCustomFeeOption(BuildContext context) {
    return Card(
      color:
          selectedPriority == null
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
      child: InkWell(
        onTap: onCustomFeeSelected,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: selectedPriority == null,
                onChanged: (_) => onCustomFeeSelected?.call(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Custom Fee',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Set your own fee parameters',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single priority option widget
class _PriorityOption extends StatelessWidget {
  const _PriorityOption({
    required this.title,
    required this.subtitle,
    required this.fee,
    required this.isSelected,
    required this.onSelect,
  });

  final String title;
  final String subtitle;
  final WithdrawalFeeOption fee;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: isSelected,
                onChanged: (_) => onSelect(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          fee.feeInfo.formatTotal(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (fee.estimatedTime != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Estimated time: ${fee.estimatedTime}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                    if (fee.feeInfo.isHighFee) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Warning: High fee',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget for displaying fee information with priority selection
///
/// **Note:** Fee estimation features are currently disabled as the API endpoints
/// are not yet available. When disabled, this widget will show appropriate messaging
/// and guide users to use custom fee settings.
class FeeInfoWithPriority extends StatelessWidget {
  const FeeInfoWithPriority({
    required this.feeOptions,
    required this.selectedFee,
    required this.onFeeChanged,
    this.showPrioritySelector = true,
    super.key,
  });

  final WithdrawalFeeOptions? feeOptions;
  final FeeInfo? selectedFee;
  final ValueChanged<FeeInfo?> onFeeChanged;
  final bool showPrioritySelector;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPrioritySelector) ...[
          WithdrawalPrioritySelector(
            feeOptions: feeOptions,
            selectedPriority: _getSelectedPriority(),
            onPriorityChanged: (priority) {
              if (feeOptions != null) {
                final feeOption = feeOptions!.getByPriority(priority);
                onFeeChanged(feeOption.feeInfo);
              }
            },
            onCustomFeeSelected: () {
              // Clear the selected fee to indicate custom fee mode
              onFeeChanged(null);
            },
          ),
          const SizedBox(height: 16),
        ],
        if (selectedFee != null) ...[
          Text('Selected Fee', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          FeeInfoDisplay(feeInfo: selectedFee!),
        ],
      ],
    );
  }

  WithdrawalFeeLevel? _getSelectedPriority() {
    if (feeOptions == null || selectedFee == null) return null;

    // Find which priority level matches the selected fee
    if (_feeMatches(selectedFee!, feeOptions!.low.feeInfo)) {
      return WithdrawalFeeLevel.low;
    } else if (_feeMatches(selectedFee!, feeOptions!.medium.feeInfo)) {
      return WithdrawalFeeLevel.medium;
    } else if (_feeMatches(selectedFee!, feeOptions!.high.feeInfo)) {
      return WithdrawalFeeLevel.high;
    }

    return null; // Custom fee
  }

  bool _feeMatches(FeeInfo fee1, FeeInfo fee2) {
    // Simple comparison - in a real implementation, you might want more sophisticated matching
    return fee1.runtimeType == fee2.runtimeType &&
        fee1.totalFee == fee2.totalFee &&
        fee1.coin == fee2.coin;
  }
}
