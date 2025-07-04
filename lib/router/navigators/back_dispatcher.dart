import 'package:flutter/material.dart';
import 'package:komodo_wallet/router/navigators/app_router_delegate.dart';

class AirDexBackButtonDispatcher extends RootBackButtonDispatcher {
  AirDexBackButtonDispatcher(this._routerDelegate) : super();

  final AppRouterDelegate _routerDelegate;

  @override
  Future<bool> didPopRoute() {
    return _routerDelegate.popRoute();
  }
}
