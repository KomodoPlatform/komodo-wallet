import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/shared/utils/formatters.dart';

class CustomFiatInputField extends StatelessWidget {
  const CustomFiatInputField({
    required this.controller,
    required this.hintText,
    required this.onTextChanged,
    required this.assetButton,
    super.key,
    this.label,
    this.readOnly = false,
    this.inputError,
  });

  final TextEditingController controller;
  final String hintText;
  final Widget? label;
  final void Function(String?) onTextChanged;
  final bool readOnly;
  final Widget assetButton;
  final String? inputError;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurfaceVariant;

    final inputStyle = Theme.of(context).textTheme.headlineLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w300,
          color: textColor,
          letterSpacing: 1.1,
        );

    final InputDecoration inputDecoration = InputDecoration(
      label: label,
      labelStyle: inputStyle,
      fillColor: Theme.of(context).colorScheme.onSurface,
      floatingLabelStyle:
          Theme.of(context).inputDecorationTheme.floatingLabelStyle,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      hintText: hintText,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(4),
          topLeft: Radius.circular(4),
          bottomRight: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      errorText: inputError,
      errorMaxLines: 1,
      helperText: '',
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerRight,
      children: [
        TextField(
          autofocus: true,
          controller: controller,
          style: inputStyle,
          decoration: inputDecoration,
          readOnly: readOnly,
          onChanged: onTextChanged,
          inputFormatters: [
            FilteringTextInputFormatter.allow(numberRegExp),
            DecimalTextInputFormatter(decimalRange: 2),
          ],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        Positioned(
          right: 16,
          bottom: 26,
          top: 2,
          child: assetButton,
        ),
      ],
    );
  }
}
