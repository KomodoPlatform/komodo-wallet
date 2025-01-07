import 'package:equatable/equatable.dart';

enum SecuritySettingsStep {
  securityMain,
  seedShow,
  seedConfirm,
  seedSuccess,
  // passwordUpdate,
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

  final SecuritySettingsStep step;
  final bool showSeedWords;
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
