import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/model/settings/market_maker_bot_settings.dart';
import 'package:web_dex/model/stored_settings.dart';

class SettingsState extends Equatable {
  const SettingsState({
    required this.themeMode,
    required this.mmBotSettings,
    required this.testCoinsEnabled,
  });

  factory SettingsState.fromStored(StoredSettings stored) {
    return SettingsState(
      themeMode: stored.mode,
      mmBotSettings: stored.marketMakerBotSettings,
      testCoinsEnabled: stored.testCoinsEnabled,
    );
  }

  final ThemeMode themeMode;
  final MarketMakerBotSettings mmBotSettings;
  final bool testCoinsEnabled;

  @override
  List<Object?> get props => [
        themeMode,
        mmBotSettings,
        testCoinsEnabled,
      ];

  SettingsState copyWith({
    ThemeMode? mode,
    MarketMakerBotSettings? marketMakerBotSettings,
    bool? testCoinsEnabled,
  }) {
    return SettingsState(
      themeMode: mode ?? themeMode,
      mmBotSettings: marketMakerBotSettings ?? mmBotSettings,
      testCoinsEnabled: testCoinsEnabled ?? this.testCoinsEnabled,
    );
  }
}
