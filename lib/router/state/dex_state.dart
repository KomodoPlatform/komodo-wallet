import 'package:flutter/material.dart';
import 'package:web_dex/router/state/menu_state_interface.dart';

class DexState extends ChangeNotifier implements IResettableOnLogout {
  DexState()
      : _action = DexAction.none,
        _uuid = '',
        _isOrder = false,
        _fromCurrency = '',
        _fromAmount = '',
        _toCurrency = '',
        _toAmount = '',
        _orderType = '';

  DexAction _action;
  String _uuid;
  bool _isOrder;

  String _fromCurrency;
  String _fromAmount;
  String _toCurrency;
  String _toAmount;
  String _orderType;

  set action(DexAction action) {
    if (_action == action) {
      return;
    }

    _action = action;
    notifyListeners();
  }

  void setDetailsAction(String uuid, {bool isOrder = false}) {
    _uuid = uuid;
    _isOrder = isOrder;
    _action = DexAction.tradingDetails;
    notifyListeners();
  }

  DexAction get action => _action;

  bool get isTradingDetails => _action == DexAction.tradingDetails;

  set uuid(String uuid) {
    _uuid = uuid;
    notifyListeners();
  }

  String get uuid => _uuid;

  bool get isOrder => _isOrder;

  String get fromCurrency => _fromCurrency;
  set fromCurrency(String fromCurrency) {
    _fromCurrency = fromCurrency;
    notifyListeners();
  }

  String get fromAmount => _fromAmount;
  set fromAmount(String fromAmount) {
    _fromAmount = fromAmount;
    notifyListeners();
  }

  String get toCurrency => _toCurrency;
  set toCurrency(String toCurrency) {
    _toCurrency = toCurrency;
    notifyListeners();
  }

  String get toAmount => _toAmount;
  set toAmount(String toAmount) {
    _toAmount = toAmount;
    notifyListeners();
  }

  String get orderType => _orderType;
  set orderType(String orderType) {
    _orderType = orderType;
    notifyListeners();
  }

  @override
  void reset() {
    action = DexAction.none;
    _uuid = '';
    _isOrder = false;
  }

  @override
  void resetOnLogOut() {
    reset();
  }

  void clearDexParams() {
    _fromCurrency = '';
    _fromAmount = '';
    _toCurrency = '';
    _toAmount = '';
    _orderType = '';
  }
}

enum DexAction {
  tradingDetails,
  none,
}
