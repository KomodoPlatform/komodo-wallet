import 'package:equatable/equatable.dart';

/// Represents the different steps in the security settings flow.
/// Each step corresponds to a different screen or phase of the user journey.
enum SecuritySettingsStep {
  /// The main security settings screen with backup options.
  securityMain,

  /// The screen showing the seed words for backup.
  seedShow,

  /// The screen confirming that the seed words have been written down.
  seedConfirm,

  /// The screen showing that the seed words have been successfully confirmed.
  seedSuccess,

  /// The screen showing the private keys for export.
  /// Note: Actual private key data is NOT stored in state for security reasons.
  privateKeyShow,

  /// The screen for updating the wallet password.
  passwordUpdate,
}

/// State for the security settings flow.
///
/// **Security Note**: This state intentionally does NOT contain actual private
/// key data. Private keys are handled directly in the UI layer to minimize
/// their memory lifetime and exposure. Only authentication status and flow
/// control state is managed here.
class SecuritySettingsState extends Equatable {
  const SecuritySettingsState({
    required this.step,
    required this.showSeedWords,
    required this.isSeedSaved,
    required this.showPrivateKeys,
    required this.arePrivateKeysSaved,
    required this.isAuthenticating,
    required this.privateKeyAuthenticationSuccess,
    required this.authError,
  });

  /// Creates the initial state for security settings.
  factory SecuritySettingsState.initialState() {
    return const SecuritySettingsState(
      step: SecuritySettingsStep.securityMain,
      showSeedWords: false,
      isSeedSaved: false,
      showPrivateKeys: false,
      arePrivateKeysSaved: false,
      isAuthenticating: false,
      privateKeyAuthenticationSuccess: false,
      authError: null,
    );
  }

  /// The current step of the security settings flow.
  final SecuritySettingsStep step;

  /// Whether the seed words are currently being shown.
  final bool showSeedWords;

  /// Whether the seed words have been written down or saved somewhere by the user.
  final bool isSeedSaved;

  /// Whether the private keys are currently being shown.
  /// Note: This only controls UI visibility, not the actual private key data.
  final bool showPrivateKeys;

  /// Whether the private keys have been written down or saved somewhere by the user.
  final bool arePrivateKeysSaved;

  /// Whether authentication is currently in progress for private key access.
  final bool isAuthenticating;

  /// Whether authentication for private key access was successful.
  /// This triggers the UI to fetch private keys from the SDK.
  final bool privateKeyAuthenticationSuccess;

  /// Any authentication error that occurred during private key access.
  final String? authError;

  @override
  List<Object?> get props => [
    step,
    showSeedWords,
    isSeedSaved,
    showPrivateKeys,
    arePrivateKeysSaved,
    isAuthenticating,
    privateKeyAuthenticationSuccess,
    authError,
  ];

  /// Creates a copy of this state with the given fields replaced with new values.
  SecuritySettingsState copyWith({
    SecuritySettingsStep? step,
    bool? showSeedWords,
    bool? isSeedSaved,
    bool? showPrivateKeys,
    bool? arePrivateKeysSaved,
    bool? isAuthenticating,
    bool? privateKeyAuthenticationSuccess,
    String? authError,
    bool clearAuthError = false,
  }) {
    return SecuritySettingsState(
      step: step ?? this.step,
      showSeedWords: showSeedWords ?? this.showSeedWords,
      isSeedSaved: isSeedSaved ?? this.isSeedSaved,
      showPrivateKeys: showPrivateKeys ?? this.showPrivateKeys,
      arePrivateKeysSaved: arePrivateKeysSaved ?? this.arePrivateKeysSaved,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      privateKeyAuthenticationSuccess:
          privateKeyAuthenticationSuccess ??
          this.privateKeyAuthenticationSuccess,
      authError: clearAuthError ? null : (authError ?? this.authError),
    );
  }
}
