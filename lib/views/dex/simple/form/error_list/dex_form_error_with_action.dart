import 'package:flutter/material.dart';
import 'package:web_dex/model/dex_form_error.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class DexFormErrorWithAction extends StatefulWidget {
  const DexFormErrorWithAction({
    Key? key,
    required this.error,
    required this.action,
  }) : super(key: key);

  final DexFormError error;
  final DexFormErrorAction action;

  @override
  State<DexFormErrorWithAction> createState() => _DexFormErrorWithActionState();
}

class _DexFormErrorWithActionState extends State<DexFormErrorWithAction> {
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.warning_amber, size: 14, color: Colors.orange),
        const SizedBox(width: 4),
        Flexible(
          child: SelectableText(
            widget.error.message,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        _isLoading
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: UiSpinner(height: 12, width: 12, strokeWidth: 1),
              )
            : UiSimpleButton(
                child: Text(
                  widget.action.text,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  await widget.action.callback();
                  setState(() {
                    _isLoading = false;
                  });
                },
              ),
      ],
    );
  }
}

class DexFormErrorAction {
  DexFormErrorAction({required this.text, required this.callback});

  final String text;
  final Future<void> Function() callback;
}
