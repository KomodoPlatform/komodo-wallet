import 'package:flutter/material.dart';
import 'package:web_dex/router/state/menu_state_interface.dart';

class FiatState extends ChangeNotifier implements IResettableOnLogout {
  FiatState()
      : _action = FiatAction.none,
        _uuid = '';

  FiatAction _action;
  String _uuid;

  set action(FiatAction action) {
    if (_action == action) {
      return;
    }

    _action = action;
    notifyListeners();
  }

  void setDetailsAction(String uuid) {
    _uuid = uuid;
    _action = FiatAction.tradingDetails;
    notifyListeners();
  }

  FiatAction get action => _action;

  bool get isTradingDetails => _action == FiatAction.tradingDetails;

  set uuid(String uuid) {
    _uuid = uuid;
    notifyListeners();
  }

  String get uuid => _uuid;

  @override
  void reset() {
    action = FiatAction.none;
  }

  @override
  void resetOnLogOut() {
    action = FiatAction.none;
  }
}

enum FiatAction {
  tradingDetails,
  none,
}
