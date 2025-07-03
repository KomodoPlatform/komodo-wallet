import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/trading_status/trading_status_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/bloc/settings/settings_event.dart';
import 'package:web_dex/bloc/settings/settings_state.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/main_menu_value.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/views/common/main_menu/main_menu_desktop_item.dart';

class MainMenuDesktop extends StatefulWidget {
  @override
  State<MainMenuDesktop> createState() => _MainMenuDesktopState();
}

class _MainMenuDesktopState extends State<MainMenuDesktop> {
  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context
        .select((AuthBloc bloc) => bloc.state.mode == AuthorizeMode.logIn);

    return BlocBuilder<AuthBloc, AuthBlocState>(
      builder: (context, state) {
        return BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, settingsState) {
            final bool isDarkTheme = settingsState.themeMode == ThemeMode.dark;
            final bool isMMBotEnabled =
                settingsState.mmBotSettings.isMMBotEnabled;
            final bool tradingEnabled =
                context.watch<TradingStatusBloc>().state is TradingEnabled;
            final SettingsBloc settings = context.read<SettingsBloc>();
            final currentWallet = state.currentUser?.wallet;
            return Container(
              margin: isWideScreen
                  ? const EdgeInsets.fromLTRB(0, mainLayoutPadding + 12, 24, 0)
                  : const EdgeInsets.fromLTRB(
                      mainLayoutPadding,
                      mainLayoutPadding + 12,
                      27,
                      mainLayoutPadding,
                    ),
              child: FocusTraversalGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    DesktopMenuDesktopItem(
                      key: const Key('main-menu-wallet'),
                      menu: MainMenuValue.wallet,
                      onTap: onTapItem,
                      isSelected: _checkSelectedItem(MainMenuValue.wallet),
                    ),
                    DesktopMenuDesktopItem(
                      key: const Key('main-menu-fiat'),
                      enabled: currentWallet?.isHW != true,
                      menu: MainMenuValue.fiat,
                      onTap: onTapItem,
                      isSelected: _checkSelectedItem(MainMenuValue.fiat),
                    ),
                    Tooltip(
                      message: tradingEnabled
                          ? ''
                          : LocaleKeys.tradingDisabledTooltip.tr(),
                      child: DesktopMenuDesktopItem(
                        key: const Key('main-menu-dex'),
                        enabled: currentWallet?.isHW != true,
                        menu: MainMenuValue.dex,
                        onTap: onTapItem,
                        isSelected: _checkSelectedItem(MainMenuValue.dex),
                      ),
                    ),
                    Tooltip(
                      message: tradingEnabled
                          ? ''
                          : LocaleKeys.tradingDisabledTooltip.tr(),
                      child: DesktopMenuDesktopItem(
                        key: const Key('main-menu-bridge'),
                        enabled: currentWallet?.isHW != true,
                        menu: MainMenuValue.bridge,
                        onTap: onTapItem,
                        isSelected: _checkSelectedItem(MainMenuValue.bridge),
                      ),
                    ),
                    if (isMMBotEnabled && isAuthenticated)
                      Tooltip(
                        message: tradingEnabled
                            ? ''
                            : LocaleKeys.tradingDisabledTooltip.tr(),
                        child: DesktopMenuDesktopItem(
                          key: const Key('main-menu-market-maker-bot'),
                          enabled: currentWallet?.isHW != true,
                          menu: MainMenuValue.marketMakerBot,
                          onTap: onTapItem,
                          isSelected:
                              _checkSelectedItem(MainMenuValue.marketMakerBot),
                        ),
                      ),
                    DesktopMenuDesktopItem(
                        key: const Key('main-menu-nft'),
                        enabled: currentWallet?.isHW != true,
                        menu: MainMenuValue.nft,
                        onTap: onTapItem,
                        isSelected: _checkSelectedItem(MainMenuValue.nft)),
                    const Spacer(),
                    DesktopMenuDesktopItem(
                      key: const Key('main-menu-settings'),
                      menu: MainMenuValue.settings,
                      onTap: onTapItem,
                      needAttention: currentWallet?.config.hasBackup == false,
                      isSelected: _checkSelectedItem(MainMenuValue.settings),
                    ),
                    Theme(
                      data: isDarkTheme ? newThemeDark : newThemeLight,
                      child: Builder(builder: (context) {
                        final ColorSchemeExtension colorScheme =
                            Theme.of(context)
                                .extension<ColorSchemeExtension>()!;
                        return DexThemeSwitcher(
                          isDarkTheme: isDarkTheme,
                          lightThemeTitle: LocaleKeys.lightMode.tr(),
                          darkThemeTitle: LocaleKeys.darkMode.tr(),
                          buttonKeyValue: 'theme-switcher',
                          onThemeModeChanged: (mode) {
                            settings.add(
                              ThemeModeChanged(
                                mode: isDarkTheme
                                    ? ThemeMode.light
                                    : ThemeMode.dark,
                              ),
                            );
                          },
                          switcherStyle: DexThemeSwitcherStyle(
                            textColor: colorScheme.primary,
                            thumbBgColor: colorScheme.surfContLow,
                            switcherBgColor: colorScheme.p10,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 48),
                  ].toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void onTapItem(MainMenuValue selectedMenu) {
    routingState.selectedMenu = selectedMenu;
  }

  bool _checkSelectedItem(MainMenuValue menu) {
    return routingState.selectedMenu == menu;
  }
}
