import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/shared/utils/formatters.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class CustomNumericTextFormField extends StatelessWidget {
  const CustomNumericTextFormField({
    Key? key,
    required this.controller,
    required this.validator,
    required this.hintText,
    required this.filteringRegExp,
    this.style,
    this.hintTextStyle,
    this.errorMaxLines,
    this.onChanged,
    this.focusNode,
    this.onFocus,
    this.suffixIcon,
    this.validationMode = InputValidationMode.eager,
  }) : super(key: key);

  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String hintText;
  final TextStyle? style;
  final TextStyle? hintTextStyle;
  final String filteringRegExp;
  final int? errorMaxLines;
  final InputValidationMode validationMode;
  final void Function(String?)? onChanged;

  final FocusNode? focusNode;
  final void Function(FocusNode)? onFocus;

  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return UiTextFormField(
      controller: controller,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(filteringRegExp)),
        DecimalTextInputFormatter(decimalRange: decimalRange),
      ],
      textInputAction: TextInputAction.done,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: style ?? themeData.textTheme.bodyMedium,
      validationMode: validationMode,
      validator: validator,
      onChanged: onChanged,
      focusNode: focusNode,
      hintTextStyle: hintTextStyle,
      hintText: hintText,
      errorMaxLines: errorMaxLines,
      suffixIcon: suffixIcon,
    );
  }
}
