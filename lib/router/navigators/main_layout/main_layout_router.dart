import 'package:flutter/material.dart';
import 'package:web_dex/router/navigators/main_layout/main_layout_router_delegate.dart';

class MainLayoutRouter extends StatefulWidget {
  const MainLayoutRouter({super.key});

  @override
  State<MainLayoutRouter> createState() => _MainLayoutRouterState();
}

class _MainLayoutRouterState extends State<MainLayoutRouter> {
  final MainLayoutRouterDelegate _routerDelegate = MainLayoutRouterDelegate();

  @override
  Widget build(BuildContext context) {
    return Router(routerDelegate: _routerDelegate);
  }
}
