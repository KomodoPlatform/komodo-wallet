import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/model/main_menu_value.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/views/common/header/actions/header_actions.dart';

class AppHeader extends StatefulWidget {
  const AppHeader({Key? key}) : super(key: key);

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  @override
  Widget build(BuildContext context) {
    return Container(
        color: theme.currentGlobal.colorScheme.surface,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: maxScreenWidth,
            ),
            child: AppBar(
              centerTitle: false,
              titleSpacing: 0,
              title: _buildTitle(),
              elevation: 0,
              actions: getHeaderActions(context),
              backgroundColor: Colors.transparent,
            ),
          ),
        ));
  }

  Widget _buildTitle() {
    return Container(
      padding: isWideScreen
          ? const EdgeInsets.fromLTRB(12, 14, 0, 0)
          : const EdgeInsets.fromLTRB(mainLayoutPadding + 12, 14, 0, 0),
      child: InkWell(
        hoverColor: theme.custom.noColor,
        splashColor: theme.custom.noColor,
        highlightColor: theme.custom.noColor,
        onTap: () {
          routingState.selectedMenu = MainMenuValue.wallet;
        },
        child: SvgPicture.asset(
          '$assetsPath/logo/logo$themeAssetPostfix.svg',
        ),
      ),
    );
  }
}
