import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/shared/utils/formatters.dart';
import 'package:web_dex/shared/utils/utils.dart';

/// A widget that displays an asset amount with its fiat value in parentheses.
///
/// Example output: "0.5 BTC ($15,234.50)"
///
/// The fiat value is only shown if pricing data is available from the SDK.
class AssetAmountWithFiat extends StatelessWidget {
  const AssetAmountWithFiat({
    required this.assetId,
    required this.amount,
    super.key,
    this.style,
    this.isSelectable = true,
    this.isAutoScrollEnabled = true,
    this.showCoinSymbol = true,
  });

  /// The asset ID to fetch pricing for
  final AssetId assetId;

  /// The crypto amount to display
  final Decimal amount;

  /// Text style for the main amount
  final TextStyle? style;

  /// Whether the text should be selectable
  final bool isSelectable;

  /// Whether to enable auto-scrolling for long text
  final bool isAutoScrollEnabled;

  /// Whether to append the coin symbol to the amount
  final bool showCoinSymbol;

  @override
  Widget build(BuildContext context) {
    final sdk = context.sdk;
    final price = sdk.marketData.priceIfKnown(assetId);

    String displayText = amount.toString();
    if (showCoinSymbol) {
      displayText = '$displayText ${assetId.id}';
    }

    // If no price available, just show the amount
    var formattedFiat = '';
    if (price != null) {
      final fiatValue = (price * amount).toDouble();
      formattedFiat = ' (${formatUsdValue(fiatValue)})';
    }

    final fullText = '$displayText$formattedFiat';

    if (isAutoScrollEnabled) {
      return AutoScrollText(
        text: fullText,
        style: style,
        isSelectable: isSelectable,
        textAlign: TextAlign.right,
      );
    }

    return isSelectable
        ? SelectableText(fullText, style: style, textAlign: TextAlign.right)
        : Text(fullText, style: style, textAlign: TextAlign.right);
  }
}
