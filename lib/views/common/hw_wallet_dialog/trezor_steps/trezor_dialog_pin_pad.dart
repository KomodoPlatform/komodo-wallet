import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/ui/ui_light_button.dart';
import 'package:web_dex/views/common/hw_wallet_dialog/constants.dart';
import 'package:web_dex/shared/screenshot/screenshot_sensitivity.dart';

const List<List<int>> _keys = [
  [7, 8, 9],
  [4, 5, 6],
  [1, 2, 3],
];

class TrezorDialogPinPad extends StatefulWidget {
  const TrezorDialogPinPad({
    Key? key,
    required this.onComplete,
    required this.onClose,
  }) : super(key: key);

  final Function(String) onComplete;
  final VoidCallback onClose;

  @override
  State<TrezorDialogPinPad> createState() => _TrezorDialogPinPadState();
}

class _TrezorDialogPinPadState extends State<TrezorDialogPinPad> {
  final TextEditingController _pinController = TextEditingController(text: '');
  final _focus = FocusNode();
  @override
  void initState() {
    _pinController.addListener(_onPinChange);
    super.initState();
  }

  @override
  void dispose() {
    _pinController.removeListener(_onPinChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenshotSensitive(child: KeyboardListener(
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      focusNode: _focus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(LocaleKeys.trezorEnterPinTitle.tr(), style: trezorDialogTitle),
          const SizedBox(height: 4),
          Text(
            LocaleKeys.trezorEnterPinHint.tr(),
            style: trezorDialogDescription,
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 30),
            child: _buildObscuredPin(),
          ),
          const SizedBox(height: 12),
          _buildKeys(),
          _buildButtons(),
        ],
      ),
    ));
  }

  Widget _buildObscuredPin() {
    final Color? backspaceColor = _pinController.text.isEmpty
        ? Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)
        : Theme.of(context).textTheme.bodyMedium?.color;

    return UiTextFormField(
      controller: _pinController,
      readOnly: true,
      obscureText: true,
      style: const TextStyle(fontSize: 36),
      inputContentPadding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 12,
      ),
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: IconButton(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          icon: Icon(Icons.backspace, color: backspaceColor),
          onPressed: _pinController.text.isEmpty ? null : _deleteLast,
        ),
      ),
    );
  }

  Widget _buildKeys() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: _keys.map(_buildKeysRow).toList(),
    );
  }

  Widget _buildKeysRow(List<int> keysRow) {
    final List<Widget> children = [];
    for (int value in keysRow) {
      children.add(Expanded(child: _Key(onTap: () => _onKeyTap(value))));
      final bool isLast = keysRow.indexOf(value) == keysRow.length - 1;
      if (!isLast) {
        children.add(const SizedBox(width: 16));
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: children,
      ),
    );
  }

  void _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey.keyLabel == 'Backspace') {
      _deleteLast();
      return;
    }
    if (event.logicalKey.keyLabel == 'Enter' &&
        _pinController.text.isNotEmpty) {
      widget.onComplete(_pinController.text);
    }
    final int? character = int.tryParse(event.character ?? '');
    if (character == null) return;
    _onKeyTap(character);
  }

  void _deleteLast() {
    final String pinValue = _pinController.text;
    if (pinValue.isEmpty) return;

    _pinController.value = TextEditingValue(
      text: pinValue.substring(0, pinValue.length - 1),
    );
  }

  Widget _buildButtons() {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Flexible(
            child: UiLightButton(
              onPressed: widget.onClose,
              text: LocaleKeys.cancel.tr(),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: UiPrimaryButton(
              onPressed: _pinController.text.isEmpty
                  ? null
                  : () => widget.onComplete(_pinController.text),
              text: LocaleKeys.continueText.tr(),
            ),
          ),
        ],
      ),
    );
  }

  void _onKeyTap(int value) {
    if (_pinController.text.length >= 50) return;

    _pinController.value = TextEditingValue(
      text: _pinController.text + value.toString(),
    );
  }

  void _onPinChange() {
    setState(() {});
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Material(
        color: theme.custom.keyPadColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: theme.custom.keyPadTextColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
