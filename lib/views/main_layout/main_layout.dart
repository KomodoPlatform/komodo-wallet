import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_dex/bloc/trading_status/trading_status_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/blocs/update_bloc.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/router/navigators/main_layout/main_layout_router.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/services/alpha_version_alert_service/alpha_version_alert_service.dart';
import 'package:web_dex/services/feedback/feedback_service.dart';
import 'package:web_dex/bloc/coins_manager/coins_manager_bloc.dart';
import 'package:web_dex/router/state/wallet_state.dart';
import 'package:web_dex/model/main_menu_value.dart';
import 'package:web_dex/views/common/header/app_header.dart';
import 'package:web_dex/views/common/main_menu/main_menu_bar_mobile.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  void initState() {
    final tradingStatusBloc = context.read<TradingStatusBloc>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AlphaVersionWarningService().run();
      await updateBloc.init();

      if (!mounted) return;
      final tradingEnabled = tradingStatusBloc.state is TradingEnabled;
      if (tradingEnabled &&
          kShowTradingWarning &&
          !await _hasAgreedNoTrading()) {
        _showNoTradingWarning().ignore();
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthBlocState>(
      listener: (context, state) {
        if (state.mode == AuthorizeMode.noLogin) {
          routingState.resetOnLogOut();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {

          return Scaffold(
            key: scaffoldKey,
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            appBar: isMobile
                ? null
                : const PreferredSize(
                    preferredSize: Size.fromHeight(appBarHeight),
                    child: AppHeader(),
                  ),
            body: SafeArea(child: MainLayoutRouter()),
            bottomNavigationBar: isMobile ? MainMenuBarMobile() : null,
            floatingActionButton: MainLayoutFab(isMobile: isMobile),
          );
        },
      ),
    );
  }

  // Method to show an alert dialog with an option to agree if the app is in
  // debug mode stating that trading features may not be used for actual trading
  // and that only test assets/networks may be used.
  Future<void> _showNoTradingWarning() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(LocaleKeys.showNoTradingWarning.tr()),
          content: Text(LocaleKeys.showNoTradingWarningMessage.tr()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveAgreedState().ignore();
              },
              child: Text(LocaleKeys.showNoTradingWarningButton.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAgreedState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('wallet_only_agreed', DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> _hasAgreedNoTrading() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('wallet_only_agreed') != null;
  }
}

class MainLayoutFab extends StatelessWidget {
  const MainLayoutFab({super.key, required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final bool showAddAssetsFab = isMobile &&
        routingState.selectedMenu == MainMenuValue.wallet &&
        routingState.walletState.selectedCoin.isEmpty &&
        routingState.walletState.action.isEmpty &&
        authState.mode == AuthorizeMode.logIn;

    final Widget? feedbackFab = context.isFeedbackAvailable
        ? FloatingActionButton(
            onPressed: () => context.showFeedback(),
            tooltip: 'Report a bug or feedback',
            mini: isMobile,
            child: const Icon(Icons.bug_report),
          )
        : null;

    final Widget? addAssetsFab = showAddAssetsFab
        ? Tooltip(
            message: LocaleKeys.addAssets.tr(),
            child: SizedBox.square(
              dimension: isMobile ? 56.0 : 48.0,
              child: UiGradientButton(
                onPressed: () {
                  context.read<CoinsManagerBloc>().add(
                      const CoinsManagerCoinsListReset(CoinsManagerAction.add));
                  routingState.walletState.action =
                      coinsManagerRouteAction.addAssets;
                },
                child: const Icon(
                  Icons.add,
                  size: 28,
                ),
              ),
            ),
          )
        : null;

    if (feedbackFab != null && addAssetsFab != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          feedbackFab,
          const SizedBox(height: 16),
          addAssetsFab,
        ],
      );
    }

    return addAssetsFab ?? feedbackFab ?? const SizedBox.shrink();
  }
}
