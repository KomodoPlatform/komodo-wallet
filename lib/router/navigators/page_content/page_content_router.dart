import 'package:flutter/material.dart';
import 'package:web_dex/router/navigators/page_content/page_content_router_delegate.dart';

class PageContentRouter extends StatefulWidget {
  @override
  State<PageContentRouter> createState() => _PageContentRouterState();
}

class _PageContentRouterState extends State<PageContentRouter> {
  final PageContentRouterDelegate _routerDelegate = PageContentRouterDelegate();

  @override
  Widget build(BuildContext context) {
    return Router(
      routerDelegate: _routerDelegate,
    );
  }
}
