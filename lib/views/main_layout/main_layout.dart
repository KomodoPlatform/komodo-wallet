import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:komodo_wallet/app_config/app_config.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:komodo_wallet/bloc/trading_status/trading_status_bloc.dart';
import 'package:komodo_wallet/bloc/auth_bloc/auth_bloc.dart';
import 'package:komodo_wallet/blocs/update_bloc.dart';
import 'package:komodo_wallet/common/screen.dart';
import 'package:komodo_wallet/model/authorize_mode.dart';
import 'package:komodo_wallet/router/navigators/main_layout/main_layout_router.dart';
import 'package:komodo_wallet/router/state/routing_state.dart';
import 'package:komodo_wallet/services/alpha_version_alert_service/alpha_version_alert_service.dart';
import 'package:komodo_wallet/services/feedback/feedback_service.dart';
import 'package:komodo_wallet/shared/utils/window/window.dart';
import 'package:komodo_wallet/views/common/header/app_header.dart';
import 'package:komodo_wallet/views/common/main_menu/main_menu_bar_mobile.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  void initState() {
    // TODO: localize
    showMessageBeforeUnload('Are you sure you want to leave?');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AlphaVersionWarningService().run();
      await updateBloc.init();

      final tradingEnabled =
          context.read<TradingStatusBloc>().state is TradingEnabled;
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
      child: Scaffold(
        key: scaffoldKey,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        appBar: isMobile
            ? null
            : const PreferredSize(
                preferredSize: Size.fromHeight(appBarHeight),
                child: AppHeader(),
              ),
        body: SafeArea(child: MainLayoutRouter()),
        bottomNavigationBar: !isDesktop ? MainMenuBarMobile() : null,
        floatingActionButton: context.isFeedbackAvailable
            ? FloatingActionButton(
                onPressed: () => context.showFeedback(),
                tooltip: 'Report a bug or feedback',
                mini: isMobile,
                child: const Icon(Icons.bug_report),
              )
            : null,
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
