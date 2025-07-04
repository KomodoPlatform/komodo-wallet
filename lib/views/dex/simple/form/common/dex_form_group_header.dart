import 'package:flutter/material.dart';
import 'package:komodo_wallet/views/dex/simple/form/common/dex_form_title.dart';

class DexFormGroupHeader extends StatelessWidget {
  const DexFormGroupHeader(
      {this.title, this.actions, this.background, Key? key})
      : super(key: key);

  final String? title;
  final List<Widget>? actions;
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (background != null)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: background!,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 16),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (title != null) DexFormTitle(title!),
                if (actions != null)
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
