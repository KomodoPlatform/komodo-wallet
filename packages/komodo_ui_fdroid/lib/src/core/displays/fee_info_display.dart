import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/src/utils/formatters/fee_info_formatters.dart';

/// A widget for displaying FeeInfo details in a consistent format.
///
/// This widget handles all fee types (ETH gas, QRC20 gas, Cosmos gas, UTXO)
/// and displays their relevant details in a clear, formatted way.
///
/// **Note:** Fee estimation features are currently disabled as the API endpoints
/// are not yet available. This widget will display fee information when provided
/// manually or when fee estimation becomes available.
class FeeInfoDisplay extends StatelessWidget {
  const FeeInfoDisplay({
    required this.feeInfo,
    this.showDetailedBreakdown = true,
    super.key,
  });

  /// The fee information to display
  final FeeInfo feeInfo;

  /// Whether to show the detailed fee breakdown
  /// If false, only shows the total fee
  final bool showDetailedBreakdown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDetailedBreakdown) ...[
          Text('Fee Details:', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),

          // Show different details based on fee type
          ...switch (feeInfo) {
            final FeeInfoEthGas fee => [
              Text('Gas:', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                '${fee.gas} units',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text('Gas Price:', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                '${fee.formatGasPrice()} Gwei',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              if (fee.isHighFee)
                Text(
                  'Warning: High gas price',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              Text(
                'Estimated Time: ${fee.estimatedTime}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],

            final FeeInfoEthGasEip1559 fee => [
              Text('Gas:', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                '${fee.gas} units',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                'Max Fee Per Gas:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${_formatGwei(fee.maxFeePerGas)} Gwei',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                'Max Priority Fee:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${_formatGwei(fee.maxPriorityFeePerGas)} Gwei',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              if (_isEip1559HighFee(fee))
                Text(
                  'Warning: High gas price',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              Text(
                'Estimated Time: ${_getEip1559EstimatedTime(fee)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],

            final FeeInfoQrc20Gas fee => [
              Text('Gas Limit:', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                '${fee.gasLimit}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text('Gas Price:', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                fee.formatTotal(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],

            final FeeInfoCosmosGas fee => [
              Text('Gas Limit:', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                '${fee.gasLimit}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text('Gas Price:', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                fee.formatTotal(precision: 2),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],

            final FeeInfoUtxoFixed fee => [
              Text('Fixed Fee:', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                fee.formatTotal(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],

            final FeeInfoUtxoPerKbyte fee => [
              Text(
                'Fee per KB:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                fee.formatTotal(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],

            final FeeInfoTendermint fee => [
              Text('Gas Limit:', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                '${fee.gasLimit}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text('Amount:', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                fee.formatTotal(precision: 8),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          },

          const SizedBox(height: 4),
        ],

        // Always show total fee
        Text(
          'Total Fee: ${feeInfo.formatTotal()}',
          style: Theme.of(context).textTheme.titleSmall,
        ),

        // Show warning for high fees
        if (feeInfo.isHighFee)
          Text(
            'Warning: This fee seems unusually high',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
      ],
    );
  }

  /// Helper method to format ETH amount in Gwei
  String _formatGwei(Decimal ethAmount) {
    const gweiInEth = 1000000000; // 10^9
    final gwei = ethAmount * Decimal.fromInt(gweiInEth);
    return gwei.toStringAsFixed(2);
  }

  /// Helper method to get estimated time for EIP1559 fees
  String _getEip1559EstimatedTime(FeeInfoEthGasEip1559 fee) {
    const gweiInEth = 1000000000; // 10^9
    final gwei = fee.maxFeePerGas * Decimal.fromInt(gweiInEth);
    if (gwei > Decimal.fromInt(100)) return '< 15 seconds';
    if (gwei > Decimal.fromInt(50)) return '< 30 seconds';
    if (gwei > Decimal.fromInt(20)) return '< 2 minutes';
    return '> 5 minutes';
  }

  /// Helper method to check if EIP1559 fee is high
  bool _isEip1559HighFee(FeeInfoEthGasEip1559 fee) {
    const gweiInEth = 1000000000; // 10^9
    return fee.maxFeePerGas * Decimal.fromInt(gweiInEth) > Decimal.fromInt(100);
  }
}
