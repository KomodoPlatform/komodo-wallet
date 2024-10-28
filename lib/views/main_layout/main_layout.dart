import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc_state.dart';
import 'package:web_dex/blocs/startup_bloc.dart';
import 'package:web_dex/blocs/update_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/router/navigators/main_layout/main_layout_router.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/services/alpha_version_alert_service/alpha_version_alert_service.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/utils/window/window.dart';
import 'package:web_dex/views/common/header/app_header.dart';
import 'package:web_dex/views/common/main_menu/main_menu_bar_mobile.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

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
        appBar: buildAppHeader(),
        body: SafeArea(child: _buildAppBody()),
        bottomNavigationBar: !isDesktop ? MainMenuBarMobile() : null,
      ),
    );
  }

  Widget _buildAppBody() {
    return StreamBuilder<bool>(
        initialData: startUpBloc.running,
        stream: startUpBloc.outRunning,
        builder: (context, snapshot) {
          log('_LayoutWrapperState.build([context]) StreamBuilder: $snapshot');
          if (!snapshot.hasData) {
            return const Center(child: UiSpinner());
          }

          return MainLayoutRouter();
        });
  }
}
