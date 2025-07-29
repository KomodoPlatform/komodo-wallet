import 'package:equatable/equatable.dart';
import 'package:komodo_defi_rpc_methods/komodo_defi_rpc_methods.dart';

/// Base class for all security settings events.
abstract class SecuritySettingsEvent extends Equatable {
  const SecuritySettingsEvent();

  @override
  List<Object> get props => [];
}

/// Event to reset the security settings to the initial state.
class ResetEvent extends SecuritySettingsEvent {
  const ResetEvent();
}

/// Event to show the seed phrase backup screen.
class ShowSeedEvent extends SecuritySettingsEvent {
  const ShowSeedEvent();
}

/// Event to proceed to seed phrase confirmation.
class SeedConfirmEvent extends SecuritySettingsEvent {
  const SeedConfirmEvent();
}

/// Event when the user has confirmed they saved their seed phrase.
class SeedConfirmedEvent extends SecuritySettingsEvent {
  const SeedConfirmedEvent();
}

/// Event to toggle visibility of seed words in the UI.
class ShowSeedWordsEvent extends SecuritySettingsEvent {
  const ShowSeedWordsEvent(this.isShow);
  final bool isShow;
}

/// Event when seed phrase has been copied to clipboard.
class ShowSeedCopiedEvent extends SecuritySettingsEvent {
  const ShowSeedCopiedEvent();
}

/// Event to show the password update screen.
class PasswordUpdateEvent extends SecuritySettingsEvent {
  const PasswordUpdateEvent();
}

/// Event to authenticate user for private key access.
///
/// **Security Note**: This event does NOT contain the actual password.
/// Authentication is handled through the existing wallet password dialog,
/// and this event only triggers the authentication process in the BLoC.
/// Actual private key retrieval happens in the UI layer after authentication
/// succeeds to minimize sensitive data exposure.
class AuthenticateForPrivateKeysEvent extends SecuritySettingsEvent {
  const AuthenticateForPrivateKeysEvent();
}

/// Event to show the private keys screen.
///
/// **Security Note**: This event does NOT contain private key data.
/// It only controls the UI flow. The actual private keys are fetched
/// and stored in the UI layer for minimal memory exposure.
class ShowPrivateKeysEvent extends SecuritySettingsEvent {
  const ShowPrivateKeysEvent();
}

/// Event to toggle visibility of private keys in the UI.
///
/// **Security Note**: This only controls UI visibility state.
/// The actual private key data remains in the UI layer.
class ShowPrivateKeysWordsEvent extends SecuritySettingsEvent {
  const ShowPrivateKeysWordsEvent(this.isShow);
  final bool isShow;

  @override
  List<Object> get props => [isShow];
}

/// Event when private keys have been copied to clipboard.
class ShowPrivateKeysCopiedEvent extends SecuritySettingsEvent {
  const ShowPrivateKeysCopiedEvent();
}

/// Event to download private keys to a file.
class PrivateKeysDownloadRequestedEvent extends SecuritySettingsEvent {
  const PrivateKeysDownloadRequestedEvent();
}

/// Event to clear any authentication errors.
class ClearAuthenticationErrorEvent extends SecuritySettingsEvent {
  const ClearAuthenticationErrorEvent();
}

/// Event to trigger unbanning of all banned public keys.
///
/// This operation does not require password authentication as it's considered
/// a non-destructive action that improves wallet functionality.
class UnbanPubkeysEvent extends SecuritySettingsEvent {
  const UnbanPubkeysEvent();
}

/// Event when pubkey unbanning completes successfully.
class UnbanPubkeysCompletedEvent extends SecuritySettingsEvent {
  const UnbanPubkeysCompletedEvent(this.result);

  final UnbanPubkeysResult result;

  @override
  List<Object> get props => [result];
}

/// Event when pubkey unbanning fails.
class UnbanPubkeysFailedEvent extends SecuritySettingsEvent {
  const UnbanPubkeysFailedEvent(this.error);

  final String error;

  @override
  List<Object> get props => [error];
}
