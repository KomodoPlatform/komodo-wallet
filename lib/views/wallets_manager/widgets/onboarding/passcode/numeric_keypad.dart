import 'package:flutter/material.dart';

/// A numeric keypad widget for passcode entry.
///
/// Displays a 3x4 grid of number buttons (1-9, 0) with a delete button.
/// Used for entering 6-digit passcodes during wallet setup.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    required this.onNumberTap,
    required this.onDeleteTap,
    super.key,
  });

  /// Callback when a number button (0-9) is tapped
  final ValueChanged<int> onNumberTap;

  /// Callback when the delete button is tapped
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF222229).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow([1, 2, 3]),
          const SizedBox(height: 16),
          _buildRow([4, 5, 6]),
          const SizedBox(height: 16),
          _buildRow([7, 8, 9]),
          const SizedBox(height: 16),
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildRow(List<int> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) => _buildNumberButton(number)).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Empty space on the left
        const SizedBox(width: 72, height: 72),
        // Zero button
        _buildNumberButton(0),
        // Delete button
        _buildDeleteButton(),
      ],
    );
  }

  Widget _buildNumberButton(int number) {
    return InkWell(
      onTap: () => onNumberTap(number),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2B2D40),
        ),
        child: Center(
          child: Text(
            number.toString(),
            style: const TextStyle(
              color: Color(0xFFE9EAEE),
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return InkWell(
      onTap: onDeleteTap,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF2B2D40),
        ),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            color: Color(0xFFADAFC4),
            size: 28,
          ),
        ),
      ),
    );
  }
}
