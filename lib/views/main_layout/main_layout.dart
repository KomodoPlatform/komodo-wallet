import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/blocs/current_wallet_bloc.dart';
import 'package:web_dex/blocs/update_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/router/navigators/main_layout/main_layout_router.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/services/alpha_version_alert_service/alpha_version_alert_service.dart';
import 'package:web_dex/shared/utils/window/window.dart';
import 'package:web_dex/views/common/header/app_header.dart';
import 'package:web_dex/views/common/main_menu/main_menu_bar_mobile.dart';

class MainLayout extends StatefulWidget {
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
      updateBloc.init();

      if (kDebugMode && !await _hasAgreedNoTrading()) {
        _showDebugModeDialog().ignore();
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
        // This is necessary until current wallet bloc can be phased out
        // completely. AuthBloc adds metadata to the current user & wallet
        // after the sign-in/register events, so current wallet bloc has to be
        // updated to have the metadata reflect where it needs to
        context.read<CurrentWalletBloc>().wallet = state.currentUser?.wallet;
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
      ),
    );
  }
}
