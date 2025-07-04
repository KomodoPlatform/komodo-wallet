import 'package:flutter/material.dart';
import 'package:komodo_wallet/app_config/app_config.dart';
import 'package:komodo_wallet/model/main_menu_value.dart';
import 'package:komodo_wallet/router/routes.dart';
import 'package:komodo_wallet/router/state/routing_state.dart';
import 'package:komodo_wallet/views/bridge/bridge_page.dart';
import 'package:komodo_wallet/views/dex/dex_page.dart';
import 'package:komodo_wallet/views/fiat/fiat_page.dart';
import 'package:komodo_wallet/views/market_maker_bot/market_maker_bot_page.dart';
import 'package:komodo_wallet/views/nfts/nft_page.dart';
import 'package:komodo_wallet/views/settings/settings_page.dart';
import 'package:komodo_wallet/views/settings/widgets/support_page/support_page.dart';
import 'package:komodo_wallet/views/wallet/wallet_page/wallet_page.dart';

class PageContentRouterDelegate extends RouterDelegate<AppRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoutePath> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    switch (routingState.selectedMenu) {
      case MainMenuValue.fiat:
        return const FiatPage();
      case MainMenuValue.dex:
        return const DexPage();
      case MainMenuValue.bridge:
        return const BridgePage();
      case MainMenuValue.marketMakerBot:
        return const MarketMakerBotPage();
      case MainMenuValue.nft:
        return NftPage(
          key: const Key('nft-page'),
          pageState: routingState.nftsState.pageState,
          uuid: routingState.nftsState.uuid,
        );
      case MainMenuValue.settings:
        return SettingsPage(
            selectedMenu: routingState.settingsState.selectedMenu);
      case MainMenuValue.support:
        return SupportPage();
      case MainMenuValue.wallet:
      default:
        return WalletPage(
          coinAbbr: routingState.walletState.selectedCoin,
          action: routingState.walletState.coinsManagerAction,
        );
    }
  }

  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) async {}
}
