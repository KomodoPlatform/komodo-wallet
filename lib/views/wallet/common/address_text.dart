import 'package:flutter/material.dart';
import 'package:komodo_wallet/shared/utils/formatters.dart';

class AddressText extends StatelessWidget {
  const AddressText({
    required this.address,
  });

  final String address;

  @override
  Widget build(BuildContext context) {
    return Text(
      truncateMiddleSymbols(address, 5, 4),
      style: const TextStyle(fontSize: 14),
    );
  }
}
