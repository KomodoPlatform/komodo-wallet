import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/model/settings/market_maker_bot_settings.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class ThemeModeChanged extends SettingsEvent {
  const ThemeModeChanged({required this.mode});
  final ThemeMode mode;
}

class TestCoinsEnabledChanged extends SettingsEvent {
  const TestCoinsEnabledChanged({required this.testCoinsEnabled});
  final bool testCoinsEnabled;
}

class HideBalancesChanged extends SettingsEvent {
  const HideBalancesChanged({required this.hideBalances});
  final bool hideBalances;
}

class MarketMakerBotSettingsChanged extends SettingsEvent {
  const MarketMakerBotSettingsChanged(this.settings);

  final MarketMakerBotSettings settings;

  @override
  List<Object> get props => [settings];
}
