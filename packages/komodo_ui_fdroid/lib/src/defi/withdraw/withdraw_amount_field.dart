import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

/// A text input field for entering the withdrawal amount
class WithdrawAmountField extends StatefulWidget {
  /// Creates a [WithdrawAmountField].
  const WithdrawAmountField({
    required this.asset,
    required this.amount,
    required this.isMaxAmount,
    required this.onChanged,
    required this.onMaxToggled,
    this.amountError,
    this.hasInsufficientBalance = false,
    this.availableBalance,
    super.key,
  });

  /// The asset for which the withdrawal amount is being entered.
  final Asset asset;

  /// The current amount entered in the field.
  final String amount;

  /// Whether the maximum amount is selected.
  final bool isMaxAmount;

  /// Callback for when the amount changes.
  final ValueChanged<String> onChanged;

  /// Callback for when the maximum amount is toggled.
  final ValueChanged<bool> onMaxToggled;

  /// Error message for the amount field.
  final String? amountError;

  /// Whether the user has insufficient balance.
  final bool hasInsufficientBalance;

  /// The available balance for the asset.
  final String? availableBalance;

  @override
  State<WithdrawAmountField> createState() => _WithdrawAmountFieldState();
}

class _WithdrawAmountFieldState extends State<WithdrawAmountField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.amount);
  }

  @override
  void didUpdateWidget(WithdrawAmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amount != oldWidget.amount &&
        _controller.text != widget.amount) {
      // Save current cursor position
      final selection = _controller.selection;

      // Update text
      _controller.text = widget.amount;

      // Restore cursor position, but handle potential out-of-bounds
      if (widget.amount.length >= selection.baseOffset) {
        _controller.selection = selection;
      } else {
        // If new text is shorter, move cursor to end
        _controller.selection = TextSelection.collapsed(
          offset: widget.amount.length,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Amount',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.availableBalance != null)
              Text(
                'Available: ${widget.availableBalance} ${widget.asset.id.id}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          enabled: !widget.isMaxAmount,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            errorText: widget.amountError,
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.asset.id.id,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            prefixIcon:
                widget.hasInsufficientBalance
                    ? Tooltip(
                      message: 'Insufficient balance',
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.error,
                      ),
                    )
                    : null,
            helperText:
                widget.hasInsufficientBalance
                    ? 'Insufficient balance'
                    : 'Enter the amount to send',
            helperStyle:
                widget.hasInsufficientBalance
                    ? TextStyle(color: theme.colorScheme.error)
                    : null,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: widget.onChanged,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: widget.isMaxAmount,
                  onChanged: (value) => widget.onMaxToggled(value ?? false),
                ),
                const Text('Send maximum available'),
              ],
            ),
            if (!widget.isMaxAmount)
              TextButton(
                onPressed: () {
                  widget.onMaxToggled(true);
                },
                child: const Text('MAX'),
              ),
          ],
        ),
      ],
    );
  }
}
