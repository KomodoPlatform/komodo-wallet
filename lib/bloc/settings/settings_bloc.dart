import 'package:app_theme/app_theme.dart';
import 'package:bloc/bloc.dart';
import 'package:web_dex/bloc/settings/settings_event.dart';
import 'package:web_dex/bloc/settings/settings_repository.dart';
import 'package:web_dex/bloc/settings/settings_state.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/model/stored_settings.dart';
import 'package:web_dex/platform/platform.dart';
import 'package:web_dex/shared/utils/utils.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(StoredSettings stored, SettingsRepository repository)
      : _settingsRepo = repository,
        super(SettingsState.fromStored(stored)) {
    _storedSettings = stored;
    theme.mode = state.themeMode;

    on<ThemeModeChanged>(_onThemeModeChanged);
    on<MarketMakerBotSettingsChanged>(_onMarketMakerBotSettingsChanged);
    on<TestCoinsEnabledChanged>(_onTestCoinsEnabledChanged);
    on<WeakPasswordsAllowedChanged>(_onWeakPasswordsAllowedChanged);
    on<HideZeroBalanceAssetsChanged>(_onHideZeroBalanceAssetsChanged);
  }

  late StoredSettings _storedSettings;
  final SettingsRepository _settingsRepo;

  Future<void> _onThemeModeChanged(
    ThemeModeChanged event,
    Emitter<SettingsState> emitter,
  ) async {
    if (materialPageContext == null) return;
    final newMode = event.mode;
    theme.mode = newMode;
    await _settingsRepo.updateSettings(_storedSettings.copyWith(mode: newMode));
    changeHtmlTheme(newMode.index);
    emitter(state.copyWith(mode: newMode));

    rebuildAll(null);
  }

  Future<void> _onMarketMakerBotSettingsChanged(
    MarketMakerBotSettingsChanged event,
    Emitter<SettingsState> emitter,
  ) async {
    await _settingsRepo.updateSettings(
      _storedSettings.copyWith(marketMakerBotSettings: event.settings),
    );
    emitter(state.copyWith(marketMakerBotSettings: event.settings));
  }

  Future<void> _onTestCoinsEnabledChanged(
    TestCoinsEnabledChanged event,
    Emitter<SettingsState> emitter,
  ) async {
    await _settingsRepo.updateSettings(
      _storedSettings.copyWith(testCoinsEnabled: event.testCoinsEnabled),
    );
    emitter(state.copyWith(testCoinsEnabled: event.testCoinsEnabled));
  }

  Future<void> _onWeakPasswordsAllowedChanged(
    WeakPasswordsAllowedChanged event,
    Emitter<SettingsState> emitter,
  ) async {
    await _settingsRepo.updateSettings(
      _storedSettings.copyWith(
          weakPasswordsAllowed: event.weakPasswordsAllowed),
    );
    emitter(state.copyWith(weakPasswordsAllowed: event.weakPasswordsAllowed));
  }

  Future<void> _onHideZeroBalanceAssetsChanged(
    HideZeroBalanceAssetsChanged event,
    Emitter<SettingsState> emitter,
  ) async {
    await _settingsRepo.updateSettings(
      _storedSettings.copyWith(
        hideZeroBalanceAssets: event.hideZeroBalanceAssets,
      ),
    );
    emitter(state.copyWith(hideZeroBalanceAssets: event.hideZeroBalanceAssets));
  }
}
