import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/shared/utils/utils.dart';

class HtmlParser extends StatefulWidget {
  const HtmlParser(this.html, {super.key, this.textStyle, this.linkStyle});

  final String html;
  final TextStyle? textStyle;
  final TextStyle? linkStyle;

  @override
  State<HtmlParser> createState() => _HtmlParserState();
}

class _HtmlParserState extends State<HtmlParser> {
  final List<TapGestureRecognizer> recognizers = [];
  late TextStyle textStyle;
  late TextStyle linkStyle;

  @override
  void dispose() {
    for (TapGestureRecognizer recognizer in recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    textStyle = widget.textStyle ?? const TextStyle();
    linkStyle = widget.linkStyle ?? const TextStyle();
    final List<String> chunks = _splitLinks(widget.html);
    final List<InlineSpan> children = [];

    for (String chunk in chunks) {
      final RegExpMatch? linkMatch =
          // ignore: unnecessary_string_escapes
          RegExp('<a[^>]+href=\'(.*?)\'[^>]*>(.*)?<\/a>').firstMatch(chunk);
      if (linkMatch == null) {
        children.add(TextSpan(text: chunk, style: textStyle));
      } else {
        children.add(_buildClickable(linkMatch));
      }
    }

    return SelectableText.rich(TextSpan(children: children));
  }

  List<String> _splitLinks(String text) {
    final List<String> list = [];
    final Iterable<RegExpMatch> allMatches = RegExp(
      r'(^|.*?)(<a[^>]*>.*?<\/a>|$)',
    ).allMatches(text);

    for (RegExpMatch match in allMatches) {
      if (match[1] != '') list.add(match[1]!);
      if (match[2] != '') list.add(match[2]!);
    }

    return list;
  }

  InlineSpan _buildClickable(RegExpMatch match) {
    recognizers.add(
      TapGestureRecognizer()..onTap = () => launchURLString(match[1]!),
    );

    return TextSpan(
      text: match[2],
      style: textStyle.merge(linkStyle),
      recognizer: recognizers.last,
    );
  }
}
