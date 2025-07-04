import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_event.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_state.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/analytics/events.dart';

class CoinAddressesBloc extends Bloc<CoinAddressesEvent, CoinAddressesState> {
  final KomodoDefiSdk sdk;
  final String assetId;
  final AnalyticsBloc analyticsBloc;
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
    emit(state.copyWith(createAddressStatus: () => FormStatus.submitting));

    const maxAttempts = 3;
    int attempts = 0;
    Exception? lastException;

    while (attempts < maxAttempts) {
      attempts++;
      try {
        final newKey =
            await sdk.pubkeys.createNewPubkey(getSdkAsset(sdk, assetId));

        final derivation = (newKey as dynamic).derivationPath as String?;
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
          ),
        );
        return;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        if (attempts >= maxAttempts) {
          break;
        }
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }

    emit(
      state.copyWith(
        createAddressStatus: () => FormStatus.failure,
        errorMessage: () =>
            'Failed after $attempts attempts: ${lastException.toString()}',
      ),
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
}
