import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart' show Asset;
import 'package:komodo_defi_types/komodo_defi_types.dart' show NewAddressStatus;
import 'package:web_dex/analytics/events.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_event.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_state.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';

class CoinAddressesBloc extends Bloc<CoinAddressesEvent, CoinAddressesState> {
  final KomodoDefiSdk sdk;
  final String assetId;
  final AnalyticsBloc analyticsBloc;

  StreamSubscription<dynamic>? _pubkeysSub;
  CoinAddressesBloc(this.sdk, this.assetId, this.analyticsBloc)
    : super(const CoinAddressesState()) {
    on<CoinAddressesAddressCreationSubmitted>(_onCreateAddressSubmitted);
    on<CoinAddressesStarted>(_onStarted);
    on<CoinAddressesSubscriptionRequested>(_onAddressesSubscriptionRequested);
    on<CoinAddressesZeroBalanceVisibilityChanged>(_onHideZeroBalanceChanged);
    on<CoinAddressesPubkeysUpdated>(_onPubkeysUpdated);
    on<CoinAddressesPubkeysSubscriptionFailed>(_onPubkeysSubscriptionFailed);
  }

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

    final stream = sdk.pubkeys.watchCreateNewPubkey(getSdkAsset(sdk, assetId));

    await for (final newAddressState in stream) {
      emit(state.copyWith(newAddressState: () => newAddressState));

      switch (newAddressState.status) {
        case NewAddressStatus.completed:
          final pubkey = newAddressState.address;
          final derivation = pubkey?.derivationPath;
          if (derivation != null) {
            final parsed = parseDerivationPath(derivation);
            analyticsBloc.logEvent(
              HdAddressGeneratedEventData(
                accountIndex: parsed.accountIndex,
                addressIndex: parsed.addressIndex,
                assetSymbol: assetId,
              ),
            );
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
  }

  Future<void> _onAddressesSubscriptionRequested(
    CoinAddressesSubscriptionRequested event,
    Emitter<CoinAddressesState> emit,
  ) async {
    emit(state.copyWith(status: () => FormStatus.submitting));

    try {
      final asset = getSdkAsset(sdk, assetId);
      final addresses = (await asset.getPubkeys(sdk)).keys;

      final reasons = await asset.getCantCreateNewAddressReasons(sdk);

      emit(
        state.copyWith(
          status: () => FormStatus.success,
          addresses: () => addresses,
          cantCreateNewAddressReasons: () => reasons,
        ),
      );

      _startWatchingPubkeys(asset);
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
      final asset = getSdkAsset(sdk, assetId);
      final reasons = await asset.getCantCreateNewAddressReasons(sdk);
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
    emit(state.copyWith(errorMessage: () => event.error));
  }

  void _startWatchingPubkeys(Asset asset) {
    _pubkeysSub?.cancel();
    // pre-cache pubkeys to ensure that any newly created pubkeys are available
    // when we start watching. UI flickering between old and new states is
    // avoided this way. The watchPubkeys function yields the last known pubkeys
    // when the pubkeys stream is first activated.
    sdk.pubkeys.watchCreateNewPubkey(asset);
    _pubkeysSub = sdk.pubkeys
        .watchPubkeys(asset, activateIfNeeded: true)
        .listen(
          (assetPubkeys) {
            add(CoinAddressesPubkeysUpdated(assetPubkeys.keys));
          },
          onError: (Object err) {
            add(CoinAddressesPubkeysSubscriptionFailed(err.toString()));
          },
        );
  }

  @override
  Future<void> close() async {
    await _pubkeysSub?.cancel();
    _pubkeysSub = null;
    return super.close();
  }
}
