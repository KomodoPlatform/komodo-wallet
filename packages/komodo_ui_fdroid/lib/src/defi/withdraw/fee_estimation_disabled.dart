import 'package:flutter/material.dart';

/// A widget for displaying the disabled fee estimation state.
///
/// This widget is used when fee estimation features are disabled due to
/// unavailable API endpoints. It provides clear messaging to users about
/// the current state and guides them to use custom fee settings.
class FeeEstimationDisabled extends StatelessWidget {
  const FeeEstimationDisabled({
    this.onCustomFeeSelected,
    this.showCustomFeeButton = true,
    super.key,
  });

  /// Callback when custom fee button is pressed
  final VoidCallback? onCustomFeeSelected;

  /// Whether to show the custom fee button
  final bool showCustomFeeButton;

  @override
  Widget build(BuildContext context) {
    return Card(
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
            if (showCustomFeeButton && onCustomFeeSelected != null) ...[
              const SizedBox(height: 12),
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
    );
  }
}
