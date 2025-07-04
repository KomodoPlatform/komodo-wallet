import 'package:flutter/material.dart';
import 'package:komodo_wallet/app_config/app_config.dart';
import 'package:komodo_wallet/common/screen.dart';
import 'package:komodo_wallet/router/navigators/page_content/page_content_router.dart';
import 'package:komodo_wallet/router/navigators/page_menu/page_menu_router.dart';
import 'package:komodo_wallet/router/routes.dart';
import 'package:komodo_wallet/router/state/routing_state.dart';
import 'package:komodo_wallet/views/common/main_menu/main_menu_desktop.dart';

class MainLayoutRouterDelegate extends RouterDelegate<AppRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoutePath> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: maxScreenWidth,
        ),
        child: Builder(builder: (context) {
          switch (screenType) {
            case ScreenType.mobile:
              return _MobileLayout();
            case ScreenType.tablet:
              return _TabletLayout();
            case ScreenType.desktop:
              return _DesktopLayout();
          }
        }),
      ),
    );
  }

  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) async {}
}

class _DesktopLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 2,
          child: MainMenuDesktop(),
        ),
        Flexible(
          flex: 9,
          child: Container(
            padding: isWideScreen
                ? const EdgeInsets.fromLTRB(
                    3, mainLayoutPadding, 0, mainLayoutPadding)
                : const EdgeInsets.fromLTRB(
                    3,
                    mainLayoutPadding,
                    mainLayoutPadding,
                    mainLayoutPadding,
                  ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: PageContentRouter()),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TabletLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: PageContentRouter()),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Flexible(
          child: routingState.isPageContentShown
              ? PageContentRouter()
              : PageMenuRouter(),
        ),
      ],
    );
  }
}
