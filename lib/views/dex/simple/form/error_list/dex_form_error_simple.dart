import 'package:flutter/material.dart';
import 'package:web_dex/model/dex_form_error.dart';

class DexFormErrorSimple extends StatelessWidget {
  const DexFormErrorSimple({Key? key, required this.error}) : super(key: key);
  final DexFormError error;

  @override
  Widget build(BuildContext context) {
    assert(error.type == DexFormErrorType.simple);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.warning_amber, size: 14, color: Colors.orange),
        const SizedBox(width: 4),
        Flexible(
          child: SelectableText(
            error.message,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
