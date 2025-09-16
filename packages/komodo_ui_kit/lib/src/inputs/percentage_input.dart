import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class PercentageInput extends StatefulWidget {
  const PercentageInput({
    Key? key,
    required this.label,
    this.initialValue,
    this.errorText,
    this.onChanged,
    this.validator,
    this.maxIntegerDigits = 3,
    this.maxFractionDigits = 2,
  }) : super(key: key);

  final Widget label;
  final String? initialValue;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final int maxIntegerDigits;
  final int maxFractionDigits;

  @override
  State<PercentageInput> createState() => _PercentageInputState();
}

class _PercentageInputState extends State<PercentageInput> {
  late TextEditingController _controller;
  String? _lastEmittedValue;
  bool _shouldUpdateText = true;

  @override
  void initState() {
    super.initState();
    _lastEmittedValue = widget.initialValue ?? '';
    _controller = TextEditingController(text: _lastEmittedValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PercentageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && _shouldUpdateText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final newValue = widget.initialValue ?? '';
          if (newValue != _lastEmittedValue) {
            _lastEmittedValue = newValue;
            _controller.text = newValue;
          }
        }
      });
    }
  }

  void _handlePercentageChanged(String? value) {
    if (value != _lastEmittedValue) {
      _lastEmittedValue = value;
      _shouldUpdateText = false;
      widget.onChanged?.call(value ?? '');
      _shouldUpdateText = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [widget.label],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: UiTextFormField(
                  controller: _controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(
                        r'^\d{0,' +
                            widget.maxIntegerDigits.toString() +
                            r'}(\.\d{0,' +
                            widget.maxFractionDigits.toString() +
                            r'})?$',
                      ),
                      replacementString: _lastEmittedValue ?? '',
                    ),
                    _DecimalInputFormatter(),
                  ],
                  onChanged: _handlePercentageChanged,
                  validator: widget.validator,
                  errorText: widget.errorText,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  '%',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A [TextInputFormatter] that formats the input as a decimal number.
/// It allows only digits and a single dot.
/// It also removes leading zeros from the integer part.
class _DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String cleanedText = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');
    List<String> parts = cleanedText.split('.');
    String integerPart = parts[0].replaceFirst(RegExp(r'^0+'), '');

    if (integerPart.isEmpty) {
      integerPart = '0';
    }

    String formattedText = integerPart;
    if (parts.length > 1) {
      formattedText += '.${parts[1]}';
    }

    int cursorOffset = newValue.selection.baseOffset -
        (newValue.text.length - formattedText.length);
    cursorOffset = cursorOffset.clamp(0, formattedText.length);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }
}
