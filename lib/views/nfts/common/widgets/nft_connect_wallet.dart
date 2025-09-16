import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/widgets/connect_wallet/connect_wallet_button.dart';
import 'package:web_dex/views/nfts/common/widgets/nft_no_login.dart';
import 'package:web_dex/views/wallets_manager/wallets_manager_events_factory.dart';

class NftConnectWallet extends StatelessWidget {
  const NftConnectWallet();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 210),
            child: NftNoLogin(text: LocaleKeys.nftMainLoggedOut.tr())),
        if (isMobile)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: ConnectWalletButton(
              eventType: WalletsManagerEventType.nft,
              buttonSize: Size(double.infinity, 40),
              withIcon: false,
            ),
          ),
      ],
    );
  }
}
