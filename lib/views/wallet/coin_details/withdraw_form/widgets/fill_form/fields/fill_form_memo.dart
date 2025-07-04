import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class WithdrawMemoField extends StatelessWidget {
  final String? memo;
  final ValueChanged<String>? onChanged;

  const WithdrawMemoField({
    required this.memo,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return UiTextFormField(
      key: const Key('withdraw-form-memo-field'),
      initialValue: memo,
      maxLines: 2,
      onChanged: onChanged == null ? null : (v) => onChanged!(v ?? ''),
      autocorrect: false,
      textInputAction: TextInputAction.next,
      enableInteractiveSelection: true,
      inputFormatters: [LengthLimitingTextInputFormatter(256)],
      maxLength: 256,
      counterText: '',
      hintText: LocaleKeys.memoOptional.tr(),
      hintTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    );
  }
}
