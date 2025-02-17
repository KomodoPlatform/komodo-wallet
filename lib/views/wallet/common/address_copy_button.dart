import 'package:flutter/material.dart';
import 'package:web_dex/shared/utils/utils.dart';

class AddressCopyButton extends StatelessWidget {
  final String address;

  const AddressCopyButton({Key? key, required this.address}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      splashRadius: 18,
      icon: const Icon(Icons.copy, size: 16),
      color: Theme.of(context).textTheme.bodyMedium!.color,
      onPressed: () {
        copyToClipBoard(context, address);
      },
    );
  }
}
