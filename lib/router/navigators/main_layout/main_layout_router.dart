import 'package:flutter/material.dart';
import 'package:komodo_wallet/router/navigators/main_layout/main_layout_router_delegate.dart';

class MainLayoutRouter extends StatefulWidget {
  @override
  State<MainLayoutRouter> createState() => _MainLayoutRouterState();
}

class _MainLayoutRouterState extends State<MainLayoutRouter> {
  final MainLayoutRouterDelegate _routerDelegate = MainLayoutRouterDelegate();

  @override
  Widget build(BuildContext context) {
    return Router(
      routerDelegate: _routerDelegate,
    );
  }
}
