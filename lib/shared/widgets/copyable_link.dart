import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/shared/utils/utils.dart';

class CopyableLink extends StatefulWidget {
  const CopyableLink({
    super.key,
    required this.text,
    required this.valueToCopy,
    required this.onLinkTap,
  });

  final String text;
  final String valueToCopy;
  final VoidCallback? onLinkTap;

  @override
  State<CopyableLink> createState() => _CopyableLinkState();
}

class _CopyableLinkState extends State<CopyableLink> {
  bool isHovered = false;
  bool isPressed = false;
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<ColorSchemeExtension>()!;
    final textTheme = Theme.of(context).extension<TextThemeExtension>()!;
    final bgIconColor = isPressed
        ? colorScheme.surfCont
        : isHovered
            ? colorScheme.s40
            : colorScheme.surfContHighest;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: widget.onLinkTap,
          child: Text(
            widget.text,
            style: textTheme.bodySBold.copyWith(
              color: widget.onLinkTap == null
                  ? colorScheme.secondary
                  : colorScheme.primary,
            ),
            softWrap: false,
          ),
        ),
        const SizedBox(width: 2),
        InkWell(
          onTap: () => copyToClipBoard(context, widget.valueToCopy),
          onHover: (value) {
            setState(() => isHovered = value);
          },
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) => setState(() => isPressed = false),
          child: Container(
            decoration: BoxDecoration(
              color: bgIconColor,
              borderRadius: BorderRadius.circular(20.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Icon(
              Icons.copy_rounded,
              size: 16,
              color: colorScheme.secondary,
            ),
          ),
        )
      ],
    );
  }
}
