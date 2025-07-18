import 'package:flutter/material.dart';
import 'package:web_dex/shared/utils/formatters.dart';

class AddressText extends StatelessWidget {
  const AddressText({
    required this.address,
    this.isTruncated = true,
    this.maxLines,
  });

  final String address;
  final bool isTruncated;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final String display =
        isTruncated ? truncateMiddleSymbols(address, 5, 4) : address;
    final bool softWrap = maxLines == null || maxLines! > 1;
    return Text(
      display,
      maxLines: maxLines,
      softWrap: softWrap,
      style: const TextStyle(fontSize: 14),
    );
  }
}
