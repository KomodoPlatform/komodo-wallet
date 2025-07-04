import 'package:flutter/material.dart';
import 'package:komodo_wallet/router/state/menu_state_interface.dart';

class BridgeSectionState extends ChangeNotifier implements IResettableOnLogout {
  BridgeSectionState()
      : _action = BridgeAction.none,
        _uuid = '';

  BridgeAction _action;
  String _uuid;

  set action(BridgeAction action) {
    if (_action == action) {
      return;
    }
    _action = action;
    notifyListeners();
  }

  void setDetailsAction(String uuid) {
    _uuid = uuid;
    _action = BridgeAction.tradingDetails;
    notifyListeners();
  }

  BridgeAction get action => _action;

  set uuid(String uuid) {
    _uuid = uuid;
    notifyListeners();
  }

  String get uuid => _uuid;

  @override
  void reset() {
    action = BridgeAction.none;
  }

  @override
  void resetOnLogOut() {
    action = BridgeAction.none;
  }
}

enum BridgeAction {
  tradingDetails,
  none,
}
