import 'package:flutter/material.dart';
import 'package:web_dex/router/state/menu_state_interface.dart';

class NFTsState extends ChangeNotifier implements IResettableOnLogout {
  NFTsState()
      : _selectedNftIndex = '',
        _uuid = '',
        _pageState = NFTSelectedState.none;

  String _selectedNftIndex;
  String _uuid;
  NFTSelectedState _pageState;

  String get selectedNftIndex => _selectedNftIndex;
  set selectedNftIndex(String nftIndex) {
    if (_selectedNftIndex == nftIndex) {
      return;
    }
    _selectedNftIndex = nftIndex;
    notifyListeners();
  }

  String get uuid => _uuid;
  set uuid(String uuid) {
    _uuid = uuid;
    notifyListeners();
  }

  NFTSelectedState get pageState => _pageState;
  set pageState(NFTSelectedState action) {
    if (_pageState == action) {
      return;
    }
    _pageState = action;
    notifyListeners();
  }

  void setDetailsAction(String uuid, bool isSend) {
    _uuid = uuid;
    _pageState = isSend ? NFTSelectedState.send : NFTSelectedState.details;
    notifyListeners();
  }

  void setReceiveAction() {
    _pageState = NFTSelectedState.receive;
    notifyListeners();
  }

  void setTransactionsAction() {
    _pageState = NFTSelectedState.transactions;
    notifyListeners();
  }

  @override
  void reset() {
    uuid = '';
    pageState = NFTSelectedState.none;
  }

  @override
  void resetOnLogOut() {
    uuid = '';
    pageState = NFTSelectedState.none;
  }
}

enum NFTSelectedState {
  details,
  send,
  receive,
  transactions,
  none,
}
