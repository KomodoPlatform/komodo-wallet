import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/utils/formatters.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/views/dex/dex_helpers.dart';

class CoinTradeAmountFormField extends StatefulWidget {
  const CoinTradeAmountFormField({
    super.key,
    this.isEnabled = true,
    this.coin,
    this.initialValue = '',
    this.onChanged,
    this.errorText,
  });

  final bool isEnabled;
  final Coin? coin;
  final String initialValue;
  final Function(String)? onChanged;
  final String? errorText;

  @override
  State<CoinTradeAmountFormField> createState() =>
      _CoinTradeAmountFormFieldState();
}

class _CoinTradeAmountFormFieldState extends State<CoinTradeAmountFormField> {
  final TextEditingController _controller = TextEditingController();
  late VoidCallback _inputChangedListener;

  @override
  void initState() {
    _inputChangedListener = () => widget.onChanged?.call(_controller.text);

    final value = double.tryParse(widget.initialValue) ?? 0.0;
    _controller.text = value.toStringAsFixed(widget.coin?.decimals ?? 8);
    _controller.addListener(_inputChangedListener);

    super.initState();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_inputChangedListener)
      ..dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CoinTradeAmountFormField oldWidget) {
    super.didUpdateWidget(oldWidget);

    final textValue = double.tryParse(_controller.text);
    final initialValue = double.tryParse(widget.initialValue);

    final initialValueChanged = oldWidget.initialValue != widget.initialValue;
    final textSameAsValue = textValue == initialValue;

    if (initialValueChanged && !textSameAsValue) {
      _controller.removeListener(_inputChangedListener);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final value = double.tryParse(widget.initialValue) ?? 0.0;
          _controller.text = value.toStringAsFixed(widget.coin?.decimals ?? 8);
          _controller.addListener(_inputChangedListener);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = _controller.text.isNotEmpty
        ? Rational.parse(_controller.text)
        : Rational.zero;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 250),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 18, top: 1),
            child: TradeAmountTextFormField(
              key: const Key('maker-sell-amount'),
              enabled: widget.isEnabled,
              controller: _controller,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: TradeAmountFiatPriceText(
              key: const Key('maker-sell-amount-fiat'),
              coin: widget.coin,
              amount: amount,
            ),
          ),
          if (widget.errorText != null)
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: AutoScrollText(
                text: widget.errorText!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class TradeAmountFiatPriceText extends StatelessWidget {
  const TradeAmountFiatPriceText({super.key, this.coin, this.amount});

  final Rational? amount;
  final Coin? coin;

  @override
  Widget build(BuildContext context) {
    return Text(
      coin == null
          ? r'≈$0'
          : getFormattedFiatAmount(
              context, coin!.abbr, amount ?? Rational.zero),
      style: Theme.of(context).textTheme.bodySmall,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class TradeAmountTextFormField extends StatelessWidget {
  const TradeAmountTextFormField({
    required this.controller,
    super.key,
    this.enabled = true,
  });

  final bool enabled;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: SizedBox(
            height: 20,
            child: TextFormField(
              key: const Key('market-maker-bot-amount-input'),
              enabled: enabled,
              controller: controller,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.end,
              inputFormatters: currencyInputFormatters,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: dexPageColors.activeText,
                    decoration: TextDecoration.none,
                  ),
              decoration: const InputDecoration(
                hintText: '0.00',
                contentPadding: EdgeInsets.zero,
                fillColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
              ),
            ),
          ),
        ),
        Text(
          '*',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontFeatures: [const FontFeature.superscripts()],
          ),
        ),
      ],
    );
  }
}
