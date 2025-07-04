import 'package:flutter/material.dart';
import 'package:komodo_wallet/router/state/menu_state_interface.dart';

class WalletState extends ChangeNotifier implements IResettableOnLogout {
  WalletState()
      : _selectedCoin = '',
        _action = '';

  String _selectedCoin;
  String _action;

  String get selectedCoin => _selectedCoin;
  set selectedCoin(String abbrCoin) {
    if (_selectedCoin == abbrCoin) {
      return;
    }

    _selectedCoin = abbrCoin;
    action = '';
    notifyListeners();
  }

  set action(String action) {
    if (_action == action) {
      return;
    }
    _action = action;
    _selectedCoin = '';
    notifyListeners();
  }

  String get action => _action;

  CoinsManagerAction get coinsManagerAction {
    return coinsManagerRouteAction.toEnum(_action);
  }

  @override
  void reset() {
    selectedCoin = '';
    action = '';
  }

  @override
  void resetOnLogOut() {
    selectedCoin = '';
    action = '';
  }
}

class CoinsManagerRouteAction {
  final String addAssets = 'add-assets';
  final String removeAssets = 'remove-assets';
  final String none = '';

  CoinsManagerAction toEnum(String action) {
    if (action == addAssets) return CoinsManagerAction.add;
    if (action == removeAssets) return CoinsManagerAction.remove;
    return CoinsManagerAction.none;
  }
}

final CoinsManagerRouteAction coinsManagerRouteAction =
    CoinsManagerRouteAction();

enum CoinsManagerAction {
  add,
  remove,
  none,
}
