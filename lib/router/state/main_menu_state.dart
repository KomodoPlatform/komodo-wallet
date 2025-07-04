import 'package:flutter/material.dart';
import 'package:komodo_wallet/model/main_menu_value.dart';

class MainMenuState extends ChangeNotifier {
  MainMenuState() : _selectedMenu = MainMenuValue.none;

  MainMenuValue _selectedMenu;

  MainMenuValue get selectedMenu => _selectedMenu;

  set selectedMenu(MainMenuValue menu) {
    _selectedMenu = menu;
    notifyListeners();
  }

  void reset() {
    selectedMenu = MainMenuValue.wallet;
  }
}
