import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/src/core/inputs/fee_info_input.dart';
import 'package:komodo_ui/src/defi/transaction/withdrawal_priority.dart';
import 'package:komodo_ui/src/defi/withdraw/fee_estimation_disabled.dart';

/// Example component demonstrating how to handle disabled fee estimation
/// in a withdrawal form.
///
/// This example shows how to:
/// - Display the disabled fee estimation state
/// - Provide custom fee input options
/// - Handle the transition between disabled and enabled states
class WithdrawalFormExample extends StatefulWidget {
  const WithdrawalFormExample({required this.asset, super.key});

  final Asset asset;

  @override
  State<WithdrawalFormExample> createState() => _WithdrawalFormExampleState();
}

class _WithdrawalFormExampleState extends State<WithdrawalFormExample> {
  WithdrawalFeeOptions? _feeOptions;
  FeeInfo? _selectedFee;
  bool _isCustomFee = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeeOptions();
  }

  /// Simulates loading fee options from the API
  Future<void> _loadFeeOptions() async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    // In a real app, this would call the fee estimation API
    // For now, we simulate that fee estimation is disabled
    setState(() {
      _feeOptions = null; // null indicates disabled/not available
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdrawal Form')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Asset information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Withdraw ${widget.asset.id.id}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Asset: ${widget.asset.id.id}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fee estimation section
            if (_isLoading) ...[
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
            ] else if (_feeOptions == null) ...[
              // Fee estimation is disabled
              FeeEstimationDisabled(
                onCustomFeeSelected: () {
                  setState(() {
                    _isCustomFee = true;
                  });
                },
              ),
            ] else ...[
              // Fee estimation is available
              FeeInfoWithPriority(
                feeOptions: _feeOptions,
                selectedFee: _selectedFee,
                onFeeChanged: (fee) {
                  setState(() {
                    _selectedFee = fee;
                    _isCustomFee = fee == null;
                  });
                },
              ),
            ],

            const SizedBox(height: 16),

            // Custom fee input (when enabled)
            if (_isCustomFee) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Custom Fee Settings',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      FeeInfoInput(
                        asset: widget.asset,
                        selectedFee: _selectedFee,
                        isCustomFee: _isCustomFee,
                        onFeeSelected: (fee) {
                          setState(() {
                            _selectedFee = fee;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _feeOptions == null && !_isCustomFee
                            ? () {
                              setState(() {
                                _isCustomFee = true;
                              });
                            }
                            : null,
                    child: const Text('Set Custom Fee'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canProceed() ? _proceedWithWithdrawal : null,
                    child: const Text('Proceed'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status information
            if (_selectedFee != null) ...[
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fee Summary',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Fee: ${_selectedFee!.totalFee} ${widget.asset.id.id}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_isCustomFee) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Using custom fee settings',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    // Can proceed if we have a fee (either from estimation or custom)
    return _selectedFee != null;
  }

  void _proceedWithWithdrawal() {
    // In a real app, this would initiate the withdrawal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Proceeding with withdrawal using ${_isCustomFee ? 'custom' : 'estimated'} fee',
        ),
      ),
    );
  }
}
