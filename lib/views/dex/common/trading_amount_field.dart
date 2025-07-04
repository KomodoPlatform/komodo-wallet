import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/shared/utils/formatters.dart';

class TradingAmountField extends StatelessWidget {
  const TradingAmountField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.onChanged,
    this.height = 20,
    this.contentPadding = const EdgeInsets.all(0),
  });

  final TextEditingController controller;
  final bool enabled;
  final Function(String)? onChanged;
  final double height;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextFormField(
        key: const Key('amount-input'),
        controller: controller,
        enabled: enabled,
        textInputAction: TextInputAction.done,
        textAlign: TextAlign.end,
        inputFormatters: currencyInputFormatters,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: dexPageColors.activeText,
              decoration: TextDecoration.none,
            ),
        decoration: InputDecoration(
          hintText: '0.00',
          contentPadding: contentPadding,
          fillColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
