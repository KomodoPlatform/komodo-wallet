import 'package:flutter/material.dart';

class NftTxnLoading extends StatelessWidget {
  const NftTxnLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 150),
        child: CircularProgressIndicator(),
      ),
    );
  }
}
