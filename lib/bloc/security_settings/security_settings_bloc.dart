import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/bloc/security_settings/security_settings_event.dart';
import 'package:web_dex/bloc/security_settings/security_settings_state.dart';

/// BLoC for managing security settings flow and authentication.
///
/// **Security Architecture**: This BLoC follows a hybrid approach for maximum security:
/// - **Non-sensitive operations** (authentication, loading states, navigation) are managed here
/// - **Sensitive data** (actual private keys) are handled directly in the UI layer
/// - This minimizes the lifetime and scope of sensitive data in memory
///
/// The BLoC authenticates users and manages the flow, but never stores private keys.
/// Private key retrieval and storage happens in the UI layer after authentication succeeds.
class SecuritySettingsBloc
    extends Bloc<SecuritySettingsEvent, SecuritySettingsState> {
  /// Creates a new SecuritySettingsBloc.
  ///
  /// [initialState] The initial state for the bloc.
  /// [kdfSdk] The Komodo DeFi SDK instance for authentication operations.
  SecuritySettingsBloc(super.initialState, {KomodoDefiSdk? kdfSdk})
    : _kdfSdk = kdfSdk {
    // Seed phrase events
    on<ResetEvent>(_onReset);
    on<ShowSeedEvent>(_onShowSeed);
    on<SeedConfirmEvent>(_onSeedConfirm);
    on<SeedConfirmedEvent>(_onSeedConfirmed);
    on<ShowSeedWordsEvent>(_onShowSeedWords);
    on<ShowSeedCopiedEvent>(_onSeedCopied);
    on<PasswordUpdateEvent>(_onPasswordUpdate);

    // Private key events - hybrid security approach
    on<AuthenticateForPrivateKeysEvent>(_onAuthenticateForPrivateKeys);
    on<ShowPrivateKeysEvent>(_onShowPrivateKeys);
    on<ShowPrivateKeysWordsEvent>(_onShowPrivateKeysWords);
    on<ShowPrivateKeysCopiedEvent>(_onPrivateKeysCopied);
    on<PrivateKeysDownloadRequestedEvent>(_onPrivateKeysDownloadRequested);
    on<ClearAuthenticationErrorEvent>(_onClearAuthenticationError);
  }

  /// The Komodo DeFi SDK instance for authentication operations.
  /// This is optional to support testing scenarios.
  final KomodoDefiSdk? _kdfSdk;

  // MARK: - Reset and Navigation Events

  /// Handles resetting the security settings to initial state.
  void _onReset(ResetEvent event, Emitter<SecuritySettingsState> emit) {
    emit(SecuritySettingsState.initialState());
  }

  // MARK: - Seed Phrase Events

  /// Handles showing the seed phrase backup screen.
  void _onShowSeed(ShowSeedEvent event, Emitter<SecuritySettingsState> emit) {
    final newState = state.copyWith(
      step: SecuritySettingsStep.seedShow,
      showSeedWords: false,
    );
    emit(newState);
  }

  /// Handles toggling seed word visibility and tracking if user has viewed them.
  Future<void> _onShowSeedWords(
    ShowSeedWordsEvent event,
    Emitter<SecuritySettingsState> emit,
  ) async {
    final newState = state.copyWith(
      step: SecuritySettingsStep.seedShow,
      showSeedWords: event.isShow,
      isSeedSaved: state.isSeedSaved || event.isShow,
    );
    emit(newState);
  }

  /// Handles proceeding to seed phrase confirmation.
  void _onSeedConfirm(
    SeedConfirmEvent event,
    Emitter<SecuritySettingsState> emit,
  ) {
    final newState = state.copyWith(
      step: SecuritySettingsStep.seedConfirm,
      showSeedWords: false,
    );
    emit(newState);
  }

  /// Handles successful seed phrase confirmation.
  Future<void> _onSeedConfirmed(
    SeedConfirmedEvent event,
    Emitter<SecuritySettingsState> emit,
  ) async {
    final newState = state.copyWith(
      step: SecuritySettingsStep.seedSuccess,
      showSeedWords: false,
    );
    emit(newState);
  }

  /// Handles seed phrase being copied to clipboard.
  Future<void> _onSeedCopied(
    ShowSeedCopiedEvent event,
    Emitter<SecuritySettingsState> emit,
  ) async {
    emit(state.copyWith(isSeedSaved: true));
  }

  /// Handles showing the password update screen.
  void _onPasswordUpdate(
    PasswordUpdateEvent event,
    Emitter<SecuritySettingsState> emit,
  ) {
    final newState = state.copyWith(
      step: SecuritySettingsStep.passwordUpdate,
      showSeedWords: false,
    );
    emit(newState);
  }

  // MARK: - Private Key Events (Hybrid Security Approach)

  /// Handles authentication for private key access.
  ///
  /// **Security Note**: This method only validates that a user is authenticated.
  /// It does NOT store or handle actual private keys. After successful
  /// authentication, the UI layer is responsible for fetching and managing
  /// private keys directly to minimize their memory exposure.
  ///
  /// The authentication success state triggers the UI to safely retrieve
  /// private keys using the SecurityManager.
  Future<void> _onAuthenticateForPrivateKeys(
    AuthenticateForPrivateKeysEvent event,
    Emitter<SecuritySettingsState> emit,
  ) async {
    emit(state.copyWith(isAuthenticating: true, clearAuthError: true));

    try {
      // Verify user is authenticated without handling sensitive data
      if (_kdfSdk == null) {
        throw Exception('SDK not available');
      }

      final currentUser = await _kdfSdk.auth.currentUser;
      if (currentUser == null) {
        emit(
          state.copyWith(
            isAuthenticating: false,
            authError: 'User not authenticated',
          ),
        );
        return;
      }

      // Authentication successful - signal UI to fetch private keys
      emit(
        state.copyWith(
          isAuthenticating: false,
          privateKeyAuthenticationSuccess: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isAuthenticating: false,
          authError: 'Authentication failed: ${e.toString()}',
        ),
      );
    }
  }

  /// Handles showing the private keys screen.
  ///
  /// **Security Note**: This only manages UI flow state. Actual private
  /// key data is handled in the UI layer for security reasons.
  void _onShowPrivateKeys(
    ShowPrivateKeysEvent event,
    Emitter<SecuritySettingsState> emit,
  ) {
    final newState = state.copyWith(
      step: SecuritySettingsStep.privateKeyShow,
      showPrivateKeys: false,
      // Reset authentication success flag after use
      privateKeyAuthenticationSuccess: false,
    );
    emit(newState);
  }

  /// Handles toggling private key visibility in the UI.
  ///
  /// **Security Note**: This only controls UI visibility state.
  /// The actual private key data remains in the UI layer.
  Future<void> _onShowPrivateKeysWords(
    ShowPrivateKeysWordsEvent event,
    Emitter<SecuritySettingsState> emit,
  ) async {
    final newState = state.copyWith(
      step: SecuritySettingsStep.privateKeyShow,
      showPrivateKeys: event.isShow,
      arePrivateKeysSaved: state.arePrivateKeysSaved || event.isShow,
    );
    emit(newState);
  }

  /// Handles private keys being copied to clipboard.
  Future<void> _onPrivateKeysCopied(
    ShowPrivateKeysCopiedEvent event,
    Emitter<SecuritySettingsState> emit,
  ) async {
    emit(state.copyWith(arePrivateKeysSaved: true));
  }

  /// Handles private keys being downloaded to a file.
  Future<void> _onPrivateKeysDownloadRequested(
    PrivateKeysDownloadRequestedEvent event,
    Emitter<SecuritySettingsState> emit,
  ) async {
    emit(state.copyWith(arePrivateKeysSaved: true));
  }

  /// Handles clearing authentication errors.
  void _onClearAuthenticationError(
    ClearAuthenticationErrorEvent event,
    Emitter<SecuritySettingsState> emit,
  ) {
    emit(state.copyWith(clearAuthError: true));
  }
}
