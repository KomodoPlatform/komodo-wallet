import 'package:flutter/material.dart';
import 'package:web_dex/shared/utils/formatters.dart';

class AddressText extends StatelessWidget {
  const AddressText({
    required this.address,
    this.isTruncated = true,
  });

  final String address;
  final bool isTruncated;

  @override
  Widget build(BuildContext context) {
    final String display =
        isTruncated ? truncateMiddleSymbols(address, 5, 4) : address;
    return Text(
      display,
      style: const TextStyle(fontSize: 14),
    );
  }
}
