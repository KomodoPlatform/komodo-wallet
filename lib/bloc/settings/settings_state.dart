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
    required this.hideZeroBalanceAssets,
  });

  factory SettingsState.fromStored(StoredSettings stored) {
    return SettingsState(
      themeMode: stored.mode,
      mmBotSettings: stored.marketMakerBotSettings,
      testCoinsEnabled: stored.testCoinsEnabled,
      weakPasswordsAllowed: stored.weakPasswordsAllowed,
      hideZeroBalanceAssets: stored.hideZeroBalanceAssets,
    );
  }

  final ThemeMode themeMode;
  final MarketMakerBotSettings mmBotSettings;
  final bool testCoinsEnabled;
  final bool weakPasswordsAllowed;
  final bool hideZeroBalanceAssets;

  @override
  List<Object?> get props => [
        themeMode,
        mmBotSettings,
        testCoinsEnabled,
        weakPasswordsAllowed,
        hideZeroBalanceAssets,
      ];

  SettingsState copyWith({
    ThemeMode? mode,
    MarketMakerBotSettings? marketMakerBotSettings,
    bool? testCoinsEnabled,
    bool? weakPasswordsAllowed,
    bool? hideZeroBalanceAssets,
  }) {
    return SettingsState(
      themeMode: mode ?? themeMode,
      mmBotSettings: marketMakerBotSettings ?? mmBotSettings,
      testCoinsEnabled: testCoinsEnabled ?? this.testCoinsEnabled,
      weakPasswordsAllowed: weakPasswordsAllowed ?? this.weakPasswordsAllowed,
      hideZeroBalanceAssets:
          hideZeroBalanceAssets ?? this.hideZeroBalanceAssets,
    );
  }
}
