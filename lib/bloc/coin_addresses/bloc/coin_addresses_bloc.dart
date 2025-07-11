import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/analytics/events.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_event.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_state.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';

class CoinAddressesBloc extends Bloc<CoinAddressesEvent, CoinAddressesState> {
  final KomodoDefiSdk sdk;
  final String assetId;
  final AnalyticsBloc analyticsBloc;
  StreamSubscription<NewAddressState>? _createAddressSubscription;
  CoinAddressesBloc(
    this.sdk,
    this.assetId,
    this.analyticsBloc,
  ) : super(const CoinAddressesState()) {
    on<SubmitCreateAddressEvent>(_onSubmitCreateAddress);
    on<LoadAddressesEvent>(_onLoadAddresses);
    on<UpdateHideZeroBalanceEvent>(_onUpdateHideZeroBalance);
  }

  Future<void> _onSubmitCreateAddress(
    SubmitCreateAddressEvent event,
    Emitter<CoinAddressesState> emit,
  ) async {
    // Cancel any existing address creation subscription to prevent conflicts
    await _createAddressSubscription?.cancel();

    emit(
      state.copyWith(
        createAddressStatus: () => FormStatus.submitting,
        newAddressState: () => null,
      ),
    );

    final stream = sdk.pubkeys.createNewPubkeyStream(getSdkAsset(sdk, assetId));

    _createAddressSubscription = stream.listen(
      (newAddressState) {
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

            add(const LoadAddressesEvent());

            emit(
              state.copyWith(
                createAddressStatus: () => FormStatus.success,
                newAddressState: () => null,
              ),
            );
            _createAddressSubscription?.cancel();
            break;
          case NewAddressStatus.error:
            emit(
              state.copyWith(
                createAddressStatus: () => FormStatus.failure,
                errorMessage: () => newAddressState.error,
                newAddressState: () => null,
              ),
            );
            _createAddressSubscription?.cancel();
            break;
          case NewAddressStatus.cancelled:
            emit(
              state.copyWith(
                createAddressStatus: () => FormStatus.initial,
                newAddressState: () => null,
              ),
            );
            _createAddressSubscription?.cancel();
            break;
          default:
            // continue listening for next events
            break;
        }
      },
      onError: (error) {
        emit(
          state.copyWith(
            createAddressStatus: () => FormStatus.failure,
            errorMessage: () => error.toString(),
            newAddressState: () => null,
          ),
        );
        _createAddressSubscription?.cancel();
      },
    );
  }

  Future<void> _onLoadAddresses(
    LoadAddressesEvent event,
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
    } catch (e) {
      emit(
        state.copyWith(
          status: () => FormStatus.failure,
          errorMessage: () => e.toString(),
        ),
      );
    }
  }

  void _onUpdateHideZeroBalance(
    UpdateHideZeroBalanceEvent event,
    Emitter<CoinAddressesState> emit,
  ) {
    emit(state.copyWith(hideZeroBalance: () => event.hideZeroBalance));
  }

  @override
  Future<void> close() async {
    await _createAddressSubscription?.cancel();
    return super.close();
  }
}
