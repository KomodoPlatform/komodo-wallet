import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/src/utils/formatters/fee_info_formatters.dart';

typedef FeeInfoChanged = void Function(FeeInfo? fee);

/// Constants for fee calculations
const _gweiInEth = 1000000000; // 10^9

/// A widget for inputting custom fee information.
///
/// **Note:** Fee estimation features are currently disabled as the API endpoints
/// are not yet available. This widget provides manual fee input capabilities
/// for when automatic fee estimation is not available.
class FeeInfoInput extends StatelessWidget {
  const FeeInfoInput({
    required this.asset,
    required this.selectedFee,
    required this.isCustomFee,
    required this.onFeeSelected,
    super.key,
  });

  final Asset asset;
  final FeeInfo? selectedFee;
  final bool isCustomFee;
  final FeeInfoChanged onFeeSelected;

  @override
  Widget build(BuildContext context) {
    final protocol = asset.protocol;

    // A typical approach: check the protocol, show relevant fee UI
    if (protocol is Erc20Protocol) {
      return _buildErc20GasInputs(context);
    } else if (protocol is UtxoProtocol) {
      return _buildUtxoFeeInputs(context, protocol);
    } else if (protocol is QtumProtocol) {
      return _buildQrc20GasInputs(context);
    } else if (protocol is TendermintProtocol) {
      return _buildCosmosGasInputs(context);
    } else {
      // No custom fee input for other protocols
      return _buildUnsupportedProtocolMessage(context);
    }
  }

  /// Builds a message for unsupported protocols
  Widget _buildUnsupportedProtocolMessage(BuildContext context) {
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
                    'Custom fee not supported',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Custom fee input is not available for this asset type. '
              'Fee estimation features are currently disabled as the API endpoints are not yet available.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the gas price/limit fields for Erc20-based assets (e.g. ETH).
  Widget _buildErc20GasInputs(BuildContext context) {
    // Check if we have an EIP1559 fee or legacy fee
    final isEip1559 =
        selectedFee?.maybeMap(
          ethGasEip1559: (_) => true,
          orElse: () => false,
        ) ??
        false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gas Settings', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),

        // EIP1559 vs Legacy toggle
        Row(
          children: [
            Expanded(
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Legacy'),
                    icon: Icon(Icons.history),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('EIP1559'),
                    icon: Icon(Icons.trending_up),
                  ),
                ],
                selected: {isEip1559},
                onSelectionChanged: (Set<bool> newSelection) {
                  final useEip1559 = newSelection.contains(true);
                  if (useEip1559 != isEip1559) {
                    // Convert between legacy and EIP1559
                    final currentFee = selectedFee;
                    if (useEip1559) {
                      // Convert legacy to EIP1559
                      final legacyFee = currentFee?.maybeMap(
                        ethGas: (eth) => eth,
                        orElse: () => null,
                      );
                      if (legacyFee != null) {
                        onFeeSelected(
                          FeeInfo.ethGasEip1559(
                            coin: asset.id.id,
                            maxFeePerGas: legacyFee.gasPrice,
                            maxPriorityFeePerGas:
                                legacyFee.gasPrice * Decimal.parse('0.1'),
                            gas: legacyFee.gas,
                          ),
                        );
                      }
                    } else {
                      // Convert EIP1559 to legacy
                      final eip1559Fee = currentFee?.maybeMap(
                        ethGasEip1559: (eip) => eip,
                        orElse: () => null,
                      );
                      if (eip1559Fee != null) {
                        onFeeSelected(
                          FeeInfo.ethGas(
                            coin: asset.id.id,
                            gasPrice: eip1559Fee.maxFeePerGas,
                            gas: eip1559Fee.gas,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (isEip1559) ...[
          // EIP1559 inputs
          _buildEip1559Inputs(context),
        ] else ...[
          // Legacy inputs
          _buildLegacyEthInputs(context),
        ],
      ],
    );
  }

  /// Builds EIP1559 gas inputs (max fee per gas, max priority fee per gas, gas limit)
  Widget _buildEip1559Inputs(BuildContext context) {
    final currentFee = selectedFee?.maybeMap(
      ethGasEip1559: (eip) => eip,
      orElse: () => null,
    );

    return Column(
      children: [
        Row(
          children: [
            // Max Fee Per Gas (in Gwei)
            Expanded(
              child: TextFormField(
                enabled: isCustomFee,
                initialValue:
                    currentFee?.maxFeePerGas != null
                        ? (currentFee!.maxFeePerGas *
                                Decimal.fromInt(_gweiInEth))
                            .toString()
                        : null,
                decoration: const InputDecoration(
                  labelText: 'Max Fee Per Gas (Gwei)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final gweiInput = Decimal.tryParse(value);
                  if (gweiInput != null) {
                    // Convert Gwei to ETH
                    final ethPrice = gweiInput / Decimal.fromInt(_gweiInEth);
                    final ethPriceDecimal = Decimal.parse(ethPrice.toString());

                    // Get existing values
                    final oldGasLimit = selectedFee?.maybeMap(
                      ethGasEip1559: (eip) => eip.gas,
                      orElse: () => 21000,
                    );
                    final oldPriorityFee = selectedFee?.maybeMap(
                      ethGasEip1559: (eip) => eip.maxPriorityFeePerGas,
                      orElse: () => ethPriceDecimal * Decimal.parse('0.1'),
                    );

                    onFeeSelected(
                      FeeInfo.ethGasEip1559(
                        coin: asset.id.id,
                        maxFeePerGas: ethPriceDecimal,
                        maxPriorityFeePerGas:
                            oldPriorityFee ??
                            (ethPriceDecimal * Decimal.parse('0.1')),
                        gas: oldGasLimit ?? 21000,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),

            // Max Priority Fee Per Gas (in Gwei)
            Expanded(
              child: TextFormField(
                enabled: isCustomFee,
                initialValue:
                    currentFee?.maxPriorityFeePerGas != null
                        ? (currentFee!.maxPriorityFeePerGas *
                                Decimal.fromInt(_gweiInEth))
                            .toString()
                        : null,
                decoration: const InputDecoration(
                  labelText: 'Max Priority Fee (Gwei)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final gweiInput = Decimal.tryParse(value);
                  if (gweiInput != null) {
                    // Convert Gwei to ETH
                    final ethPrice = gweiInput / Decimal.fromInt(_gweiInEth);
                    final ethPriceDecimal = Decimal.parse(ethPrice.toString());

                    // Get existing values
                    final oldGasLimit = selectedFee?.maybeMap(
                      ethGasEip1559: (eip) => eip.gas,
                      orElse: () => 21000,
                    );
                    final oldMaxFee = selectedFee?.maybeMap(
                      ethGasEip1559: (eip) => eip.maxFeePerGas,
                      orElse: () => Decimal.parse('0.000000003'),
                    );

                    onFeeSelected(
                      FeeInfo.ethGasEip1559(
                        coin: asset.id.id,
                        maxFeePerGas: oldMaxFee ?? Decimal.parse('0.000000003'),
                        maxPriorityFeePerGas: ethPriceDecimal,
                        gas: oldGasLimit ?? 21000,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Gas Limit
        TextFormField(
          enabled: isCustomFee,
          initialValue: currentFee?.gas.toString(),
          decoration: const InputDecoration(labelText: 'Gas Limit'),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final gasLimit = int.tryParse(value);
            if (gasLimit != null) {
              // Keep existing fee values
              final oldMaxFee = selectedFee?.maybeMap(
                ethGasEip1559: (eip) => eip.maxFeePerGas,
                orElse: () => Decimal.parse('0.000000003'),
              );
              final oldPriorityFee = selectedFee?.maybeMap(
                ethGasEip1559: (eip) => eip.maxPriorityFeePerGas,
                orElse: () => Decimal.parse('0.000000001'),
              );

              onFeeSelected(
                FeeInfo.ethGasEip1559(
                  coin: asset.id.id,
                  maxFeePerGas: oldMaxFee ?? Decimal.parse('0.000000003'),
                  maxPriorityFeePerGas:
                      oldPriorityFee ?? Decimal.parse('0.000000001'),
                  gas: gasLimit,
                ),
              );
            }
          },
        ),

        // Show estimated time if we have a valid fee
        if (currentFee != null) ...[
          const SizedBox(height: 8),
          Text(
            'Estimated Time: ${_getEip1559EstimatedTime(currentFee)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_isEip1559HighFee(currentFee))
            Text(
              'Warning: High gas price',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ],
    );
  }

  /// Builds legacy ETH gas inputs (gas price, gas limit)
  Widget _buildLegacyEthInputs(BuildContext context) {
    // Get current ETH gas fee if set, or create a default one
    final currentFee = selectedFee?.maybeMap(
      ethGas: (eth) => eth,
      orElse: () => null,
    );

    return Column(
      children: [
        Row(
          children: [
            // 1) Gas Price (in Gwei)
            Expanded(
              child: TextFormField(
                enabled: isCustomFee,
                initialValue: currentFee?.formatGasPrice(),
                decoration: const InputDecoration(
                  labelText: 'Gas Price (Gwei)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final gweiInput = Decimal.tryParse(value);
                  if (gweiInput != null) {
                    // Convert Gwei to ETH
                    final ethPrice = gweiInput / Decimal.fromInt(_gweiInEth);
                    final ethPriceDecimal = Decimal.parse(ethPrice.toString());

                    // Get the old gas limit from the current fee (if ethGas)
                    final oldGasLimit = selectedFee?.maybeMap(
                      ethGas: (eth) => eth.gas,
                      orElse: () => 21000,
                    );

                    onFeeSelected(
                      FeeInfo.ethGas(
                        coin: asset.id.id,
                        gasPrice: ethPriceDecimal,
                        gas: oldGasLimit ?? 21000,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 16),

            // 2) Gas Limit
            Expanded(
              child: TextFormField(
                enabled: isCustomFee,
                initialValue: currentFee?.gas.toString(),
                decoration: const InputDecoration(labelText: 'Gas Limit'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final gasLimit = int.tryParse(value);
                  if (gasLimit != null) {
                    // Keep existing gas price or use default
                    final oldGasPrice = selectedFee?.maybeMap(
                      ethGas: (eth) => eth.gasPrice,
                      orElse: () => Decimal.parse('0.000000003'),
                    );

                    onFeeSelected(
                      FeeInfo.ethGas(
                        coin: asset.id.id,
                        gasPrice: oldGasPrice ?? Decimal.parse('0.000000003'),
                        gas: gasLimit,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),

        // Show estimated time if we have a valid fee
        if (currentFee != null) ...[
          const SizedBox(height: 8),
          Text(
            'Estimated Time: ${currentFee.estimatedTime}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (currentFee.isHighFee)
            Text(
              'Warning: High gas price',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ],
    );
  }

  /// Helper method to get estimated time for EIP1559 fees
  String _getEip1559EstimatedTime(FeeInfoEthGasEip1559 fee) {
    final gwei = fee.maxFeePerGas * Decimal.fromInt(_gweiInEth);
    if (gwei > Decimal.fromInt(100)) return '< 15 seconds';
    if (gwei > Decimal.fromInt(50)) return '< 30 seconds';
    if (gwei > Decimal.fromInt(20)) return '< 2 minutes';
    return '> 5 minutes';
  }

  /// Helper method to check if EIP1559 fee is high
  bool _isEip1559HighFee(FeeInfoEthGasEip1559 fee) {
    return fee.maxFeePerGas * Decimal.fromInt(_gweiInEth) >
        Decimal.fromInt(100);
  }

  /// Builds the gas limit/price inputs for QRC20-based assets
  Widget _buildQrc20GasInputs(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gas Settings', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            // Gas Price input
            Expanded(
              child: TextFormField(
                enabled: isCustomFee,
                decoration: const InputDecoration(labelText: 'Gas Price'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final gasPrice = Decimal.tryParse(value);
                  if (gasPrice != null) {
                    // Preserve gas limit if already set
                    final oldGasLimit = selectedFee?.maybeMap(
                      qrc20Gas: (qrc) => qrc.gasLimit,
                      orElse: () => 250000, // default
                    );

                    onFeeSelected(
                      FeeInfo.qrc20Gas(
                        coin: asset.id.id,
                        gasPrice: gasPrice,
                        gasLimit: oldGasLimit ?? 250000,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 16),

            // Gas Limit input
            Expanded(
              child: TextFormField(
                enabled: isCustomFee,
                decoration: const InputDecoration(labelText: 'Gas Limit'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final gasLimit = int.tryParse(value);
                  if (gasLimit != null) {
                    // Preserve gas price if already set
                    final oldGasPrice = selectedFee?.maybeMap(
                      qrc20Gas: (qrc) => qrc.gasPrice,
                      orElse: () => Decimal.parse('0.00000040'), // default
                    );

                    onFeeSelected(
                      FeeInfo.qrc20Gas(
                        coin: asset.id.id,
                        gasPrice: oldGasPrice ?? Decimal.parse('0.00000040'),
                        gasLimit: gasLimit,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds gas limit/price inputs for Cosmos-based assets
  Widget _buildCosmosGasInputs(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gas Settings', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            // Gas Price input
            Expanded(
              child: TextFormField(
                enabled: isCustomFee,
                decoration: const InputDecoration(labelText: 'Gas Price'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final gasPrice = Decimal.tryParse(value);
                  if (gasPrice != null) {
                    // Preserve gas limit if already set
                    final oldGasLimit = selectedFee?.maybeMap(
                      cosmosGas: (cosmos) => cosmos.gasLimit,
                      orElse: () => 200000, // default
                    );

                    onFeeSelected(
                      FeeInfo.cosmosGas(
                        coin: asset.id.id,
                        gasPrice: gasPrice,
                        gasLimit: oldGasLimit ?? 200000,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 16),

            // Gas Limit input
            Expanded(
              child: TextFormField(
                enabled: isCustomFee,
                decoration: const InputDecoration(labelText: 'Gas Limit'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final gasLimit = int.tryParse(value);
                  if (gasLimit != null) {
                    // Preserve gas price if already set
                    final oldGasPrice = selectedFee?.maybeMap(
                      cosmosGas: (cosmos) => cosmos.gasPrice,
                      orElse: () => Decimal.parse('0.025'), // default
                    );

                    onFeeSelected(
                      FeeInfo.cosmosGas(
                        coin: asset.id.id,
                        gasPrice: oldGasPrice ?? Decimal.parse('0.025'),
                        gasLimit: gasLimit,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds manual inputs for UTXO fee entry with a toggle button
  Widget _buildUtxoFeeInputs(BuildContext context, UtxoProtocol protocol) {
    final defaultFee = protocol.txFee ?? 10000;

    // Extract current fee amount or use default
    final currentFeeAmount =
        selectedFee?.maybeMap(
          utxoFixed: (f) => f.amount,
          utxoPerKbyte: (p) => p.amount,
          orElse: () => Decimal.parse(defaultFee.toString()),
        ) ??
        Decimal.parse(defaultFee.toString());

    // Determine if we're using fixed fee or per KB fee
    final isPerKbyteFee =
        selectedFee?.maybeMap(utxoPerKbyte: (_) => true, orElse: () => false) ??
        false;

    return TextFormField(
      enabled: isCustomFee,
      initialValue: currentFeeAmount.toString(),
      decoration: InputDecoration(
        labelText: 'Fee Amount',
        hintText: defaultFee.toString(),
        // Toggle button in prefix
        prefixIconConstraints: const BoxConstraints(
          maxWidth: 36,
          maxHeight: 36,
        ),
        prefixIcon:
            isCustomFee
                ? IconButton.filledTonal(
                  iconSize: 20,
                  tooltip:
                      isPerKbyteFee
                          ? 'Switch to fixed fee'
                          : 'Switch to fee per kilobyte',
                  icon: Icon(isPerKbyteFee ? Icons.scale : Icons.attach_money),
                  onPressed: () {
                    final amount = currentFeeAmount;
                    if (!isPerKbyteFee) {
                      // Switch to per KB fee
                      onFeeSelected(
                        FeeInfo.utxoPerKbyte(coin: asset.id.id, amount: amount),
                      );
                    } else {
                      // Switch to fixed fee
                      onFeeSelected(
                        FeeInfo.utxoFixed(coin: asset.id.id, amount: amount),
                      );
                    }
                  },
                )
                : null,
        // Show appropriate suffix based on fee type
        suffixText: isPerKbyteFee ? '${asset.id.id}/KB' : asset.id.id,
        helperText:
            isPerKbyteFee
                ? 'Fee per kilobyte of transaction size'
                : 'Total transaction fee',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) {
        final amount = Decimal.tryParse(value);
        if (amount != null) {
          // Create appropriate fee type based on current selection
          if (isPerKbyteFee) {
            onFeeSelected(
              FeeInfo.utxoPerKbyte(coin: asset.id.id, amount: amount),
            );
          } else {
            onFeeSelected(FeeInfo.utxoFixed(coin: asset.id.id, amount: amount));
          }
        }
      },
    );
  }
}
