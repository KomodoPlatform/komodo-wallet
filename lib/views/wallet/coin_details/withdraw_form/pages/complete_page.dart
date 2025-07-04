import 'package:flutter/material.dart';
import 'package:komodo_wallet/common/app_assets.dart';
import 'package:komodo_wallet/views/wallet/coin_details/withdraw_form/widgets/send_complete_form/send_complete_form.dart';
import 'package:komodo_wallet/views/wallet/coin_details/withdraw_form/widgets/send_complete_form/send_complete_form_footer.dart';

class CompletePage extends StatelessWidget {
  const CompletePage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        DexSvgImage(path: Assets.assetTick),
        SizedBox(height: 20),
        SendCompleteForm(),
        SizedBox(height: 20),
        SendCompleteFormFooter(),
        SizedBox(height: 20),
      ],
    );
  }
}
