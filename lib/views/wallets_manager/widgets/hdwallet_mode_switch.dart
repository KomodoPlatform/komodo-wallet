import 'package:flutter/material.dart';

class HDWalletModeSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const HDWalletModeSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Row(
        children: [
          Text('HD Wallet Mode'),
          SizedBox(width: 8),
          Tooltip(
            message: 'HD wallets require a valid BIP39 seed phrase. \n'
                'NB! Your addresses and balances will be different '
                'in HD mode.',
            child: Icon(Icons.info, size: 16),
          ),
        ],
      ),
      subtitle: const Text('Enable HD multi-address mode'),
      value: value,
      onChanged: onChanged,
    );
  }
}
