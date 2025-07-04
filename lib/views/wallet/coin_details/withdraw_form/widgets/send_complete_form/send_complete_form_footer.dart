import 'package:flutter/material.dart';
import 'package:komodo_wallet/common/screen.dart';
import 'package:komodo_wallet/views/wallet/coin_details/constants.dart';
import 'package:komodo_wallet/views/wallet/coin_details/withdraw_form/widgets/send_complete_form/send_complete_form_buttons.dart';

class SendCompleteFormFooter extends StatelessWidget {
  const SendCompleteFormFooter();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isMobile ? double.infinity : withdrawWidth,
      child: const SendCompleteFormButtons(
        key: Key('complete-buttons'),
      ),
    );
  }
}
