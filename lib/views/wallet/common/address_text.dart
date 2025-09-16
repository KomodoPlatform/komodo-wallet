import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/shared/utils/formatters.dart';

class AddressText extends StatelessWidget {
  const AddressText({
    required this.address,
    this.isTruncated = false,
  });

  final String address;
  final bool isTruncated;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    if (isTruncated) {
      return Text(
        truncateMiddleSymbols(address, 5, 4),
        style: style,
      );
    }

    return AutoScrollText(
      text: address,
      style: style,
    );
  }
}
