import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/dispatchers/popup_dispatcher.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class InformationPopup extends PopupDispatcher {
  InformationPopup({
    required BuildContext context,
    this.text = '',
    super.barrierDismissible = true,
  }) : super(context: context);
  String text;

  @override
  Widget get popupContent => Container(
        constraints: isMobile ? null : const BoxConstraints(maxWidth: 360),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                    child: UiUnderlineTextButton(
                        text: LocaleKeys.close.tr().toLowerCase(),
                        onPressed: () {
                          close();
                        })),
              ],
            )
          ],
        ),
      );
}
