import 'package:flutter/material.dart';
import 'package:komodo_wallet/views/wallet/coin_details/faucet/faucet_view.dart';

class FaucetPage extends StatefulWidget {
  const FaucetPage({
    Key? key,
    required this.coinAbbr,
    required this.onBackButtonPressed,
    required this.coinAddress,
  }) : super(key: key);

  final String coinAbbr;
  final String coinAddress;
  final VoidCallback onBackButtonPressed;

  @override
  _FaucetPageState createState() => _FaucetPageState();
}

class _FaucetPageState extends State<FaucetPage> {
  @override
  Widget build(BuildContext context) {
    return FaucetView(
      coinAbbr: widget.coinAbbr,
      coinAddress: widget.coinAddress,
      onClose: widget.onBackButtonPressed,
    );
  }
}
