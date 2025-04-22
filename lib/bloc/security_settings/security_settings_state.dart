import 'package:equatable/equatable.dart';

enum SecuritySettingsStep {
  /// The main security settings screen.
  securityMain,

  /// The screen showing the seed words.
  seedShow,

  /// The screen confirming that the seed words have been written down.
  seedConfirm,

  /// The screen showing that the seed words have been successfully confirmed.
  seedSuccess,

  /// The screen for updating the password.
  passwordUpdate,
}

class SecuritySettingsState extends Equatable {
  const SecuritySettingsState({
    required this.step,
    required this.showSeedWords,
    required this.isSeedSaved,
  });

  factory SecuritySettingsState.initialState() {
    return const SecuritySettingsState(
      step: SecuritySettingsStep.securityMain,
      showSeedWords: false,
      isSeedSaved: false,
    );
  }

  /// The current step of the security settings flow.
  final SecuritySettingsStep step;

  /// Whether the seed words are currently being shown.
  final bool showSeedWords;

  /// Whether the seed words have been written down or saved somewhere by the
  /// user.
  final bool isSeedSaved;

  @override
  List<Object?> get props => [step, showSeedWords, isSeedSaved];

  SecuritySettingsState copyWith({
    SecuritySettingsStep? step,
    bool? showSeedWords,
    bool? isSeedSaved,
  }) {
    return SecuritySettingsState(
      step: step ?? this.step,
      showSeedWords: showSeedWords ?? this.showSeedWords,
      isSeedSaved: isSeedSaved ?? this.isSeedSaved,
    );
  }
}
