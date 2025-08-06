import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart' show NewAddressStatus;
import 'package:web_dex/analytics/events.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_event.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_state.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';

class CoinAddressesBloc extends Bloc<CoinAddressesEvent, CoinAddressesState> {
  final KomodoDefiSdk _sdk;
  final String _assetId;
  final AnalyticsBloc _analyticsBloc;
  CoinAddressesBloc(
    KomodoDefiSdk sdk,
    String assetId,
    AnalyticsBloc analyticsBloc,
  ) : _sdk = sdk,
      _assetId = assetId,
      _analyticsBloc = analyticsBloc,
      super(const CoinAddressesState()) {
    on<SubmitCreateAddressEvent>(_onSubmitCreateAddress);
    on<LoadAddressesEvent>(_onLoadAddresses);
    on<UpdateHideZeroBalanceEvent>(_onUpdateHideZeroBalance);
  }

  Future<void> _onSubmitCreateAddress(
    SubmitCreateAddressEvent event,
    Emitter<CoinAddressesState> emit,
  ) async {
    emit(
      state.copyWith(
        createAddressStatus: () => FormStatus.submitting,
        newAddressState: () => null,
      ),
    );

    final stream = _sdk.pubkeys.createNewPubkeyStream(
      getSdkAsset(_sdk, _assetId),
    );

    await for (final newAddressState in stream) {
      emit(state.copyWith(newAddressState: () => newAddressState));

      switch (newAddressState.status) {
        case NewAddressStatus.completed:
          final pubkey = newAddressState.address;
          final derivation = pubkey?.derivationPath;
          if (derivation != null) {
            final parsed = parseDerivationPath(derivation);
            _analyticsBloc.logEvent(
              HdAddressGeneratedEventData(
                accountIndex: parsed.accountIndex,
                addressIndex: parsed.addressIndex,
                assetSymbol: _assetId,
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

  Future<void> _onLoadAddresses(
    LoadAddressesEvent event,
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
}
