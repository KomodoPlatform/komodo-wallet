import 'package:decimal/decimal.dart';

/// Formats an asset amount with the specified decimal places and optional symbol.
///
/// [amount] - The amount to format
/// [decimals] - Number of decimal places to display
/// [symbol] - Optional symbol to append to the formatted amount
String formatAssetAmount(Decimal amount, int decimals, {String? symbol}) {
  final formatted = amount.toStringAsFixed(decimals);
  // Remove trailing zeros after decimal point
  final trimmed = formatted
      .replaceAll(RegExp(r'0*$'), '')
      .replaceAll(RegExp(r'\.$'), '');

  if (symbol != null) {
    return '$trimmed $symbol';
  }
  return trimmed;
}

/// Formats a percentage from a decimal value (0.0 to 1.0)
String formatPercentage(Decimal decimal, {int decimals = 2}) {
  final percentage = decimal * Decimal.fromInt(100);
  return '${percentage.toStringAsFixed(decimals)}%';
}

/// Truncates an address to show only the first and last parts
String truncateAddress(
  String address, {
  int startChars = 10,
  int endChars = 10,
}) {
  if (address.length <= startChars + endChars + 3) return address;
  return '${address.substring(0, startChars)}...${address.substring(address.length - endChars)}';
}
