import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/model/settings/market_maker_bot_settings.dart';
import 'package:web_dex/model/stored_settings.dart';

class SettingsState extends Equatable {
  const SettingsState({
    required this.themeMode,
    required this.mmBotSettings,
    required this.testCoinsEnabled,
    required this.weakPasswordsAllowed,
    required this.ultraDark,
    required this.coinThemeFromIcon,
  });

  factory SettingsState.fromStored(StoredSettings stored) {
    return SettingsState(
      themeMode: stored.mode,
      mmBotSettings: stored.marketMakerBotSettings,
      testCoinsEnabled: stored.testCoinsEnabled,
      weakPasswordsAllowed: stored.weakPasswordsAllowed,
      ultraDark: stored.ultraDark,
      coinThemeFromIcon: stored.coinThemeFromIcon,
    );
  }

  final ThemeMode themeMode;
  final MarketMakerBotSettings mmBotSettings;
  final bool testCoinsEnabled;
  final bool weakPasswordsAllowed;
  final bool ultraDark;
  final bool coinThemeFromIcon;

  @override
  List<Object?> get props => [
        themeMode,
        mmBotSettings,
        testCoinsEnabled,
        weakPasswordsAllowed,
        ultraDark,
        coinThemeFromIcon,
      ];

  SettingsState copyWith({
    ThemeMode? mode,
    MarketMakerBotSettings? marketMakerBotSettings,
    bool? testCoinsEnabled,
    bool? weakPasswordsAllowed,
    bool? ultraDark,
    bool? coinThemeFromIcon,
  }) {
    return SettingsState(
      themeMode: mode ?? themeMode,
      mmBotSettings: marketMakerBotSettings ?? mmBotSettings,
      testCoinsEnabled: testCoinsEnabled ?? this.testCoinsEnabled,
      weakPasswordsAllowed: weakPasswordsAllowed ?? this.weakPasswordsAllowed,
      ultraDark: ultraDark ?? this.ultraDark,
      coinThemeFromIcon: coinThemeFromIcon ?? this.coinThemeFromIcon,
    );
  }
}
