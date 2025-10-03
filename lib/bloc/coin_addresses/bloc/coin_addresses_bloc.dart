import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart'
    show Asset, NewAddressStatus, AssetPubkeys, KdfUser, WalletId;
import 'package:logging/logging.dart';
import 'package:web_dex/analytics/events.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_event.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_state.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';

class CoinAddressesBloc extends Bloc<CoinAddressesEvent, CoinAddressesState> {
  CoinAddressesBloc(this._sdk, this._assetId, this._analyticsBloc)
    : super(const CoinAddressesState()) {
    on<CoinAddressesAddressCreationSubmitted>(_onCreateAddressSubmitted);
    on<CoinAddressesStarted>(_onStarted);
    on<CoinAddressesSubscriptionRequested>(_onAddressesSubscriptionRequested);
    on<CoinAddressesZeroBalanceVisibilityChanged>(_onHideZeroBalanceChanged);
    on<CoinAddressesPubkeysUpdated>(_onPubkeysUpdated);
    on<CoinAddressesPubkeysSubscriptionFailed>(_onPubkeysSubscriptionFailed);
    on<CoinAddressesAuthStateChanged>(_onAuthStateChanged);

    // Listen to auth state changes to clear subscriptions on logout/wallet switch
    _authSubscription = _sdk.auth.watchCurrentUser().listen((user) {
      if (!isClosed) {
        add(CoinAddressesAuthStateChanged(user));
      }
    });
  }

  final KomodoDefiSdk _sdk;
  final String _assetId;
  final AnalyticsBloc _analyticsBloc;

  static final Logger _log = Logger('CoinAddressesBloc');

  StreamSubscription<AssetPubkeys>? _pubkeysSub;
  StreamSubscription<KdfUser?>? _authSubscription;

  /// Current wallet ID being tracked for auth state changes
  WalletId? _currentWalletId;

  Future<void> _onStarted(
    CoinAddressesStarted event,
    Emitter<CoinAddressesState> emit,
  ) async {
    add(const CoinAddressesSubscriptionRequested());
  }

  Future<void> _onCreateAddressSubmitted(
    CoinAddressesAddressCreationSubmitted event,
    Emitter<CoinAddressesState> emit,
  ) async {
    emit(
      state.copyWith(
        createAddressStatus: () => FormStatus.submitting,
        newAddressState: () => null,
      ),
    );
    try {
      final asset = getSdkAsset(_sdk, _assetId);
      final stream = _sdk.pubkeys.watchCreateNewPubkey(asset);

      await for (final newAddressState in stream) {
        emit(state.copyWith(newAddressState: () => newAddressState));

        switch (newAddressState.status) {
          case NewAddressStatus.completed:
            final pubkey = newAddressState.address;
            final derivation = pubkey?.derivationPath;
            if (derivation != null) {
              try {
                final parsed = parseDerivationPath(derivation);
                _analyticsBloc.logEvent(
                  HdAddressGeneratedEventData(
                    accountIndex: parsed.accountIndex,
                    addressIndex: parsed.addressIndex,
                    asset: _assetId,
                  ),
                );
              } catch (_) {
                // Non-fatal: continue without analytics if derivation parsing fails
              }
            }

            add(const CoinAddressesSubscriptionRequested());

            emit(
              state.copyWith(
                createAddressStatus: () => FormStatus.success,
                newAddressState: () => null,
              ),
            );
            return;
          case NewAddressStatus.error:
            emit(
              state.copyWith(
                createAddressStatus: () => FormStatus.failure,
                errorMessage: () => newAddressState.error,
                newAddressState: () => null,
              ),
            );
            return;
          case NewAddressStatus.cancelled:
            emit(
              state.copyWith(
                createAddressStatus: () => FormStatus.initial,
                newAddressState: () => null,
              ),
            );
            return;
          default:
            // continue listening for next events
            break;
        }
      }
    } catch (e) {
      emit(
        state.copyWith(
          createAddressStatus: () => FormStatus.failure,
          errorMessage: () => e.toString(),
          newAddressState: () => null,
        ),
      );
    }
  }

  Future<void> _onAddressesSubscriptionRequested(
    CoinAddressesSubscriptionRequested event,
    Emitter<CoinAddressesState> emit,
  ) async {
    emit(state.copyWith(status: () => FormStatus.submitting));

    try {
      final asset = getSdkAsset(_sdk, _assetId);
      final addresses = (await asset.getPubkeys(_sdk)).keys;

      final reasons = await asset.getCantCreateNewAddressReasons(_sdk);

      emit(
        state.copyWith(
          status: () => FormStatus.success,
          addresses: () => addresses,
          cantCreateNewAddressReasons: () => reasons,
          errorMessage: () => null,
        ),
      );

      await _startWatchingPubkeys(asset);
    } catch (e) {
      emit(
        state.copyWith(
          status: () => FormStatus.failure,
          errorMessage: () => e.toString(),
        ),
      );
    }
  }

  void _onHideZeroBalanceChanged(
    CoinAddressesZeroBalanceVisibilityChanged event,
    Emitter<CoinAddressesState> emit,
  ) {
    emit(state.copyWith(hideZeroBalance: () => event.hideZeroBalance));
  }

  Future<void> _onPubkeysUpdated(
    CoinAddressesPubkeysUpdated event,
    Emitter<CoinAddressesState> emit,
  ) async {
    try {
      final asset = getSdkAsset(_sdk, _assetId);
      final reasons = await asset.getCantCreateNewAddressReasons(_sdk);
      emit(
        state.copyWith(
          status: () => FormStatus.success,
          addresses: () => event.addresses,
          cantCreateNewAddressReasons: () => reasons,
          errorMessage: () => null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: () => e.toString()));
    }
  }

  void _onPubkeysSubscriptionFailed(
    CoinAddressesPubkeysSubscriptionFailed event,
    Emitter<CoinAddressesState> emit,
  ) {
    emit(
      state.copyWith(
        status: () => FormStatus.failure,
        errorMessage: () => event.error,
      ),
    );
  }

  Future<void> _startWatchingPubkeys(Asset asset) async {
    try {
      // Cancel any existing subscription first
      await _cancelPubkeySubscription();

      _log.fine('Starting pubkey watching for asset ${asset.id.id}');

      // Pre-cache pubkeys to ensure that any newly created pubkeys are available
      // when we start watching. UI flickering between old and new states is
      // avoided this way. The watchPubkeys function yields the last known pubkeys
      // when the pubkeys stream is first activated.
      await _sdk.pubkeys.precachePubkeys(asset);
      _pubkeysSub = _sdk.pubkeys
          .watchPubkeys(asset)
          .listen(
            (AssetPubkeys assetPubkeys) {
              if (!isClosed) {
                _log.finest(
                  'Received pubkey update for asset ${asset.id.id}: ${assetPubkeys.keys.length} addresses',
                );
                add(CoinAddressesPubkeysUpdated(assetPubkeys.keys));
              }
            },
            onError: (Object err) {
              _log.warning(
                'Pubkey subscription error for asset ${asset.id.id}: $err',
              );
              if (!isClosed) {
                add(CoinAddressesPubkeysSubscriptionFailed(err.toString()));
              }
            },
          );

      _log.fine(
        'Pubkey watching started successfully for asset ${asset.id.id}',
      );
    } catch (e) {
      _log.severe(
        'Failed to start pubkey watching for asset ${asset.id.id}: $e',
      );
      if (!isClosed) {
        add(CoinAddressesPubkeysSubscriptionFailed(e.toString()));
      }
    }
  }

  @override
  Future<void> close() async {
    _log.fine('Closing CoinAddressesBloc for asset $_assetId');

    // Cancel auth subscription
    try {
      await _authSubscription?.cancel();
      _authSubscription = null;
    } catch (e) {
      _log.warning(
        'Error cancelling auth subscription for asset $_assetId: $e',
      );
    }

    // Cancel pubkey subscription
    await _cancelPubkeySubscription();

    return super.close();
  }

  /// Clears pubkeys subscription when auth state changes (logout or wallet switch).
  /// This prevents stale subscriptions from continuing to receive updates
  /// for the previous wallet's addresses.
  Future<void> _onAuthStateChanged(
    CoinAddressesAuthStateChanged event,
    Emitter<CoinAddressesState> emit,
  ) async {
    final newWalletId = event.user?.walletId;

    _log.fine(
      'Auth state changed for asset $_assetId: ${_currentWalletId?.name} -> '
      '${newWalletId?.name}',
    );

    // If the wallet ID has changed, clear subscriptions and reset state
    if (_currentWalletId != newWalletId) {
      _log.info(
        'Wallet change detected for asset $_assetId, clearing pubkey subscriptions',
      );

      await _cancelPubkeySubscription();
      _currentWalletId = newWalletId;

      // Reset to initial state when wallet changes
      emit(const CoinAddressesState());

      _log.fine(
        'Auth state change handling completed for asset $_assetId, wallet: '
        '${newWalletId?.name}',
      );
    } else {
      _log.finest(
        'No wallet change detected for asset $_assetId, keeping current state',
      );
    }
  }

  /// Cancels the current pubkey subscription with proper error handling
  Future<void> _cancelPubkeySubscription() async {
    try {
      await _pubkeysSub?.cancel();
      _pubkeysSub = null;
      _log.fine('Pubkey subscription cancelled for asset $_assetId');
    } catch (e) {
      _log.warning(
        'Error cancelling pubkey subscription for asset $_assetId: $e',
      );
      // Still set to null to prevent further issues
      _pubkeysSub = null;
    }
  }
}
