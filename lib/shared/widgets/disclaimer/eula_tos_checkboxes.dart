import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/dispatchers/popup_dispatcher.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

import 'package:web_dex/shared/widgets/disclaimer/disclaimer.dart';
import 'package:web_dex/shared/widgets/disclaimer/eula.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class EulaTosCheckboxes extends StatefulWidget {
  const EulaTosCheckboxes(
      {Key? key, this.isChecked = false, required this.onCheck})
      : super(key: key);

  final bool isChecked;
  final void Function(bool) onCheck;

  @override
  State<EulaTosCheckboxes> createState() => _EulaTosCheckboxesState();
}

class _EulaTosCheckboxesState extends State<EulaTosCheckboxes> {
  bool _checkBox = false;
  PopupDispatcher? _eulaPopupManager;
  PopupDispatcher? _disclaimerPopupManager;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiCheckbox(
          checkboxKey: const Key('checkbox-eula-tos'),
          value: _checkBox,
          onChanged: (bool? value) {
            setState(() {
              _checkBox = value ?? false;
            });
            _onCheck();
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: "${LocaleKeys.disclaimerAcceptDescription.tr()} ",
              children: [
                TextSpan(
                  text: LocaleKeys.disclaimerAcceptEulaCheckbox.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = _showEula,
                ),
                const TextSpan(text: ", "),
                TextSpan(
                  text: LocaleKeys.disclaimerAcceptTermsAndConditionsCheckbox
                      .tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = _showDisclaimer,
                ),
              ],
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    _checkBox = widget.isChecked;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _disclaimerPopupManager = PopupDispatcher(
        context: context,
        popupContent: Disclaimer(
          onClose: () {
            _disclaimerPopupManager?.close();
          },
        ),
      );
      _eulaPopupManager = PopupDispatcher(
        context: context,
        popupContent: Eula(
          onClose: () {
            _eulaPopupManager?.close();
          },
        ),
      );
    });
    super.initState();
  }

  void _onCheck() {
    widget.onCheck(_checkBox);
  }

  void _showDisclaimer() {
    _disclaimerPopupManager?.show();
  }

  void _showEula() {
    _eulaPopupManager?.show();
  }
}
