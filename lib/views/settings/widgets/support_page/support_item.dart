import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/common/screen.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_wallet/shared/ui/ui_gradient_icon.dart';
import 'package:komodo_wallet/shared/widgets/html_parser.dart';

class SupportItem extends StatefulWidget {
  const SupportItem({Key? key, required this.data, this.isLast = false})
      : super(key: key);
  final Map<String, String> data;
  final bool isLast;

  @override
  State<SupportItem> createState() => _SupportItemState();
}

class _SupportItemState extends State<SupportItem> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: InkWell(
            child: Row(
              mainAxisAlignment: isMobile
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.data['title']!,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                if (isMobile)
                  const SizedBox(
                    width: 30,
                  ),
                UiGradientIcon(
                    icon: expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down)
              ],
            ),
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Visibility(
            visible: expanded,
            child: HtmlParser(
              widget.data['content']!,
              linkStyle: TextStyle(
                  color: theme.custom.headerFloatBoxColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14),
              textStyle:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            )),
        const UiDivider(),
      ],
    );
  }
}
