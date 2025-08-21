import 'package:decimal/decimal.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

/// Constants for fee calculations
const _gweiInEth = 1000000000; // 10^9

extension FeeInfoFormatting on FeeInfo {
  /// Format a number with given precision and remove trailing zeros
  static String _formatNumber(Decimal number, {int precision = 8}) {
    if (precision < 0) throw ArgumentError('Precision must be non-negative');
    return number.toStringAsFixed(precision).replaceAll(RegExp(r'\.?0+$'), '');
  }

  /// Returns a formatted string of the total fee with the coin symbol
  /// e.g. "0.001 ETH"
  String formatTotal({int precision = 8}) {
    final total = totalFee;
    return '${_formatNumber(total, precision: precision)} $coin';
  }

  /// Returns a human-readable description of the fee
  String get description {
    return maybeMap(
      ethGas:
          (fee) =>
              'Gas: ${fee.gas} @ ${_formatNumber(fee.gasPrice * Decimal.fromInt(_gweiInEth), precision: 2)} Gwei',
      ethGasEip1559:
          (fee) =>
              'Gas: ${fee.gas} @ ${_formatNumber(fee.maxFeePerGas * Decimal.fromInt(_gweiInEth), precision: 2)} Gwei (EIP1559)',
      orElse: formatTotal,
    );
  }

  /// Returns true if the fee seems unusually high
  bool get isHighFee {
    return maybeMap(
      ethGas:
          (fee) =>
              fee.gasPrice * Decimal.fromInt(_gweiInEth) > Decimal.fromInt(100),
      ethGasEip1559:
          (fee) =>
              fee.maxFeePerGas * Decimal.fromInt(_gweiInEth) > Decimal.fromInt(100),
      utxoFixed: (fee) => fee.amount > Decimal.fromInt(50000),
      utxoPerKbyte: (fee) => fee.amount > Decimal.fromInt(50000),
      orElse: () => false,
    );
  }
}

/// Dedicated formatting extension for *only* the ethGas variant
extension EthGasFormatting on FeeInfoEthGas {
  /// Get the gas price in Gwei units
  Decimal get priceInGwei => gasPrice * Decimal.fromInt(_gweiInEth);

  /// Format gas price in Gwei with appropriate precision
  String formatGasPrice({int precision = 2}) {
    return FeeInfoFormatting._formatNumber(priceInGwei, precision: precision);
  }

  /// Estimate transaction time based on gas price
  String get estimatedTime {
    final gwei = priceInGwei;
    if (gwei > Decimal.fromInt(100)) return '< 15 seconds';
    if (gwei > Decimal.fromInt(50)) return '< 30 seconds';
    if (gwei > Decimal.fromInt(20)) return '< 2 minutes';
    return '> 5 minutes';
  }

  /// Detailed fee breakdown
  String get detailedBreakdown {
    return 'Gas Limit: $gas units\n'
        'Gas Price: ${formatGasPrice()} Gwei\n'
        'Total: ${formatTotal()}';
  }
}

/// Dedicated formatting extension for *only* the ethGasEip1559 variant
extension EthGasEip1559Formatting on FeeInfoEthGasEip1559 {
  /// Get the max fee per gas in Gwei units
  Decimal get maxFeePerGasInGwei => maxFeePerGas * Decimal.fromInt(_gweiInEth);

  /// Get the max priority fee per gas in Gwei units
  Decimal get maxPriorityFeePerGasInGwei => maxPriorityFeePerGas * Decimal.fromInt(_gweiInEth);

  /// Format max fee per gas in Gwei with appropriate precision
  String formatMaxFeePerGas({int precision = 2}) {
    return FeeInfoFormatting._formatNumber(maxFeePerGasInGwei, precision: precision);
  }

  /// Format max priority fee per gas in Gwei with appropriate precision
  String formatMaxPriorityFeePerGas({int precision = 2}) {
    return FeeInfoFormatting._formatNumber(maxPriorityFeePerGasInGwei, precision: precision);
  }

  /// Estimate transaction time based on max fee per gas
  String get estimatedTime {
    final gwei = maxFeePerGasInGwei;
    if (gwei > Decimal.fromInt(100)) return '< 15 seconds';
    if (gwei > Decimal.fromInt(50)) return '< 30 seconds';
    if (gwei > Decimal.fromInt(20)) return '< 2 minutes';
    return '> 5 minutes';
  }

  /// Detailed fee breakdown
  String get detailedBreakdown {
    return 'Gas Limit: $gas units\n'
        'Max Fee Per Gas: ${formatMaxFeePerGas()} Gwei\n'
        'Max Priority Fee: ${formatMaxPriorityFeePerGas()} Gwei\n'
        'Total: ${formatTotal()}';
  }
}
