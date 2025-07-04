import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/bloc/analytics/analytics_event.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_event.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_state.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/analytics/events.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/get_new_address/get_new_address_response.dart';
import 'package:web_dex/model/wallet.dart';

class CoinAddressesBloc extends Bloc<CoinAddressesEvent, CoinAddressesState> {
  final KomodoDefiSdk sdk;
  final String assetId;
  final AnalyticsBloc analyticsBloc;
  final CoinsRepo coinsRepo;
  CoinAddressesBloc(
    this.sdk,
    this.assetId,
    this.analyticsBloc,
    this.coinsRepo,
  ) : super(const CoinAddressesState()) {
    on<SubmitCreateAddressEvent>(_onSubmitCreateAddress);
    on<LoadAddressesEvent>(_onLoadAddresses);
    on<UpdateHideZeroBalanceEvent>(_onUpdateHideZeroBalance);
    on<AddressStatusUpdated>(_onAddressStatusUpdated);
  }

  Future<void> _onSubmitCreateAddress(
    SubmitCreateAddressEvent event,
    Emitter<CoinAddressesState> emit,
  ) async {
    emit(state.copyWith(createAddressStatus: () => FormStatus.submitting));
    final wallet = await sdk.auth.currentUser?.wallet;
    final asset = getSdkAsset(sdk, assetId);

    if (wallet?.config.type == WalletType.trezor) {
      final taskId = await coinsRepo.trezor.initNewAddress(asset);
      if (taskId == null) {
        emit(
          state.copyWith(
            createAddressStatus: () => FormStatus.failure,
            errorMessage: () => 'Failed to start address creation',
          ),
        );
        return;
      }

      coinsRepo.trezor.subscribeOnNewAddressStatus(
        taskId,
        asset,
        (status) => add(AddressStatusUpdated(status)),
      );
      return;
    }

    const maxAttempts = 3;
    int attempts = 0;
    Exception? lastException;

    while (attempts < maxAttempts) {
      attempts++;
      try {
        final newKey = await sdk.pubkeys.createNewPubkey(asset);

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

  Future<void> _onAddressStatusUpdated(
    AddressStatusUpdated event,
    Emitter<CoinAddressesState> emit,
  ) async {
    final response = event.status;
    final error = response.error;
    if (error != null) {
      coinsRepo.trezor.unsubscribeFromNewAddressStatus();
      emit(
        state.copyWith(
          createAddressStatus: () => FormStatus.failure,
          errorMessage: () => error,
          confirmAddress: () => null,
        ),
      );
      return;
    }

    final status = response.result?.status;
    final details = response.result?.details;

    switch (status) {
      case GetNewAddressStatus.inProgress:
        if (details is GetNewAddressResultConfirmAddressDetails) {
          emit(state.copyWith(confirmAddress: () => details.expectedAddress));
        }
        break;
      case GetNewAddressStatus.ok:
        if (details is GetNewAddressResultOkDetails) {
          coinsRepo.trezor.unsubscribeFromNewAddressStatus();

          final derivation = details.newAddress.derivationPath;
          if (derivation.isNotEmpty) {
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
              confirmAddress: () => null,
            ),
          );
        }
        break;
      case GetNewAddressStatus.unknown:
      case null:
        break;
    }
  }
}
