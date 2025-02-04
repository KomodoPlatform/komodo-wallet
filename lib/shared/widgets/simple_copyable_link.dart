import 'package:flutter/material.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/widgets/copyable_link.dart';

class SimpleCopyableLink extends StatelessWidget {
  const SimpleCopyableLink({
    super.key,
    required this.text,
    required this.link,
    required this.valueToCopy,
  });
  final String text;
  final String valueToCopy;
  final String? link;

  @override
  Widget build(BuildContext context) {
    final link = this.link;
    return CopyableLink(
      text: text,
      valueToCopy: valueToCopy,
      onLinkTap: link == null ? null : () => launchURLString(link),
    );
  }
}
