import 'package:flutter/material.dart';
import 'package:web_dex/router/navigators/page_menu/page_menu_router_delegate.dart';

class PageMenuRouter extends StatefulWidget {
  @override
  State<PageMenuRouter> createState() => _PageMenuRouterState();
}

class _PageMenuRouterState extends State<PageMenuRouter> {
  final PageMenuRouterDelegate _routerDelegate = PageMenuRouterDelegate();

  @override
  Widget build(BuildContext context) {
    return Router(
      routerDelegate: _routerDelegate,
    );
  }
}
