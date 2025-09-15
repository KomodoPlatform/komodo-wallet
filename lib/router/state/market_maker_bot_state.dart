import 'package:flutter/material.dart';
import 'package:web_dex/router/state/menu_state_interface.dart';

class MarketMakerBotState extends ChangeNotifier
    implements IResettableOnLogout {
  MarketMakerBotState() : _action = MarketMakerBotAction.none, _uuid = '';

  MarketMakerBotAction _action;
  String _uuid;

  set action(MarketMakerBotAction action) {
    if (_action == action) {
      return;
    }

    _action = action;
    notifyListeners();
  }

  void setDetailsAction(String uuid) {
    _uuid = uuid;
    _action = MarketMakerBotAction.tradingDetails;
    notifyListeners();
  }

  MarketMakerBotAction get action => _action;

  bool get isTradingDetails => _action == MarketMakerBotAction.tradingDetails;

  set uuid(String uuid) {
    _uuid = uuid;
    notifyListeners();
  }

  String get uuid => _uuid;

  @override
  void reset() {
    action = MarketMakerBotAction.none;
  }

  @override
  void resetOnLogOut() {
    action = MarketMakerBotAction.none;
  }
}

enum MarketMakerBotAction { tradingDetails, none }
