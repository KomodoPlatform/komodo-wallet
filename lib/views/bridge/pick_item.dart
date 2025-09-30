import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class PickItem extends StatelessWidget {
  const PickItem({
    Key? key,
    required this.title,
    this.onTap,
    this.expanded = false,
  }) : super(key: key);
  final String title;
  final Function()? onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        hoverColor: theme.custom.noColor,
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                child: AutoScrollText(text: title),
              ),
            ),
            const SizedBox(width: 6),
            Icon(expanded ? Icons.expand_less : Icons.expand_more,
                color: Theme.of(context).textTheme.bodyLarge?.color)
          ],
        ),
      ),
    );
  }
}
