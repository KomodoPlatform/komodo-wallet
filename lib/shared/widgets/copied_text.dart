import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/widgets/truncate_middle_text.dart';

class CopiedText extends StatelessWidget {
  const CopiedText({
    Key? key,
    required this.copiedValue,
    this.text,
    this.maxLines,
    this.backgroundColor,
    this.isTruncated = false,
    this.isCopiedValueShown = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
    this.fontSize = 14,
    this.fontColor,
    this.fontWeight = FontWeight.w500,
    this.iconSize = 22,
    this.height,
  }) : super(key: key);

  final String copiedValue;
  final String? text;
  final bool isTruncated;
  final bool isCopiedValueShown;
  final int? maxLines;
  final Color? backgroundColor;
  final EdgeInsets padding;
  final double? fontSize;
  final double iconSize;
  final Color? fontColor;
  final FontWeight? fontWeight;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final softWrap = (maxLines ?? 0) > 1;
    final String? showingText = text;
    final Color? background =
        backgroundColor ?? Theme.of(context).inputDecorationTheme.fillColor;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          copyToClipBoard(context, copiedValue);
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isCopiedValueShown) ...[
                Container(
                  key: const Key('coin-details-address-field'),
                  child: isTruncated
                      ? Flexible(
                          child: TruncatedMiddleText(
                            copiedValue,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: fontWeight,
                              color: fontColor,
                              height: height,
                            ),
                          ),
                        )
                      : Flexible(
                          child: AutoScrollText(
                            text: copiedValue,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: fontWeight,
                              color: fontColor,
                              height: height,
                            ),
                          ),
                        ),
                ),
                const SizedBox(
                  width: 16,
                ),
              ],
              Icon(
                Icons.copy_rounded,
                color: Theme.of(context).textTheme.labelLarge?.color,
                size: iconSize,
              ),
              if (showingText != null) ...[
                const SizedBox(
                  width: 10,
                ),
                Text(showingText),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class CopiedTextV2 extends StatelessWidget {
  const CopiedTextV2({
    Key? key,
    required this.copiedValue,
    this.text,
    this.maxLines,
    this.isTruncated = false,
    this.isCopiedValueShown = true,
    this.fontSize = 12,
    this.iconSize = 12,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  final String copiedValue;
  final String? text;
  final bool isTruncated;
  final bool isCopiedValueShown;
  final int? maxLines;

  final double fontSize;
  final double iconSize;

  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final softWrap = (maxLines ?? 0) > 1;
    final String? showingText = text;

    return InkWell(
      onTap: () {
        copyToClipBoard(context, copiedValue);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCopiedValueShown) ...[
              Container(
                key: const Key('coin-details-address-field'),
                child: isTruncated
                    ? Flexible(
                        child: TruncatedMiddleText(
                          copiedValue,
                          level: 4,
                          style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w700,
                              color: textColor ?? const Color(0xFFADAFC4)),
                        ),
                      )
                    : AutoScrollText(
                        text: copiedValue,
                        style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                            color: textColor ?? const Color(0xFFADAFC4)),
                      ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              Icons.copy_rounded,
              color: textColor ?? const Color(0xFFADAFC4),
              size: iconSize,
            ),
            if (showingText != null) ...[
              const SizedBox(width: 10),
              Text(showingText),
            ]
          ],
        ),
      ),
    );
  }
}
