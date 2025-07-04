import 'package:flutter/material.dart';
import 'package:komodo_wallet/model/main_menu_value.dart';
import 'package:komodo_wallet/model/settings_menu_value.dart';
import 'package:komodo_wallet/router/state/menu_state_interface.dart';
import 'package:komodo_wallet/router/state/routing_state.dart';

class SettingsSectionState extends ChangeNotifier
    implements IResettableOnLogout {
  SettingsMenuValue _selectedMenu = SettingsMenuValue.none;

  set selectedMenu(SettingsMenuValue menu) {
    if (_selectedMenu == menu) {
      return;
    }

    final isSecurity = menu == SettingsMenuValue.security;
    // final showSecurity = currentWalletBloc.wallet?.isHW == false;
    // TODO! reimplement
    const showSecurity = true;
    // ignore: dead_code
    if (isSecurity && !showSecurity) return;

    _selectedMenu = menu;
    notifyListeners();
  }

  SettingsMenuValue get selectedMenu {
    return _selectedMenu;
  }

  bool get isNone {
    return _selectedMenu == SettingsMenuValue.none;
  }

  @override
  void reset() {
    _selectedMenu = SettingsMenuValue.none;
  }

  Future<void> openSecurity() async {
    routingState.selectedMenu = MainMenuValue.settings;
    selectedMenu = SettingsMenuValue.security;
  }

  @override
  void resetOnLogOut() {
    if (selectedMenu == SettingsMenuValue.security) {
      selectedMenu = SettingsMenuValue.general;
    }
  }
}
