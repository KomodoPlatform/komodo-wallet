import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_bloc.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/hd_account/hd_account.dart';
import 'package:web_dex/views/wallet/coin_details/coin_details_info/address_select.dart';
import 'package:web_dex/views/wallet/coin_details/constants.dart';

class FillFormTrezorSenderAddress extends StatelessWidget {
  const FillFormTrezorSenderAddress({
    super.key,
    required this.coin,
    required this.addresses,
    required this.selectedAddress,
  });

  final Coin coin;
  final List<HdAddress> addresses;
  final String selectedAddress;

  @override
  Widget build(BuildContext context) {
    return AddressSelect(
      coin: coin,
      addresses: addresses,
      selectedAddress: selectedAddress,
      onChanged: (String address) {
        context
            .read<WithdrawFormBloc>()
            .add(WithdrawFormRecipientChanged(address));
      },
      maxWidth: withdrawWidth,
      maxHeight: 300,
    );
  }
}
