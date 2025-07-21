import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/blocs/wallets_repository.dart';
import 'package:web_dex/dispatchers/popup_dispatcher.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/common/screen.dart';

Future<String?> walletRenameDialog(
  BuildContext context, {
  required String initialName,
}) async {
  late PopupDispatcher popupManager;
  bool isOpen = false;
  final TextEditingController controller =
      TextEditingController(text: initialName);
  final walletsRepository = RepositoryProvider.of<WalletsRepository>(context);
  String? error;

  void close() {
    popupManager.close();
    isOpen = false;
  }

  popupManager = PopupDispatcher(
    context: context,
    popupContent: StatefulBuilder(
      builder: (context, setState) {
        return Container(
          constraints: isMobile ? null : const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LocaleKeys.renameWalletDescription.tr(),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              UiTextFormField(
                controller: controller,
                autofocus: true,
                autocorrect: false,
                inputFormatters: [LengthLimitingTextInputFormatter(40)],
                errorText: error,
                onChanged: (String? text) {
                  setState(() {
                    error = walletsRepository.validateWalletName(text ?? '');
                  });
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: UiUnderlineTextButton(
                      text: LocaleKeys.cancel.tr(),
                      onPressed: close,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: UiPrimaryButton(
                      text: LocaleKeys.renameWalletConfirm.tr(),
                      onPressed: error != null
                          ? null
                          : () {
                              close();
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );

  isOpen = true;
  popupManager.show();

  while (isOpen) {
    await Future<dynamic>.delayed(const Duration(milliseconds: 100));
  }

  final result = controller.text.trim();
  if (result.isEmpty || walletsRepository.validateWalletName(result) != null) {
    return null;
  }
  return result;
}
