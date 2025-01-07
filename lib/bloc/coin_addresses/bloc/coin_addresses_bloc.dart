import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_event.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_state.dart';
import 'package:web_dex/shared/utils/utils.dart';

class CoinAddressesBloc extends Bloc<CoinAddressesEvent, CoinAddressesState> {
  final KomodoDefiSdk? sdk;
  final String assetId;

  CoinAddressesBloc(this.sdk, this.assetId)
      : super(const CoinAddressesState()) {
    on<SubmitCreateAddressEvent>(_onSubmitCreateAddress);
    on<LoadAddressesEvent>(_onLoadAddresses);
    on<UpdateHideZeroBalanceEvent>(_onUpdateHideZeroBalance);
  }

  Future<void> _onSubmitCreateAddress(
      SubmitCreateAddressEvent event, Emitter<CoinAddressesState> emit) async {
    emit(state.copyWith(createAddressStatus: () => FormStatus.submitting));

    try {
      if (sdk == null) {
        throw Exception('Coin Addresses KDF SDK is null');
      }

      await sdk!.pubkeys.createNewPubkey(getSdkAsset(sdk, assetId));

      add(const LoadAddressesEvent());

      emit(state.copyWith(
        createAddressStatus: () => FormStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        createAddressStatus: () => FormStatus.failure,
        errorMessage: () => e.toString(),
      ));
    }
  }

  Future<void> _onLoadAddresses(
      LoadAddressesEvent event, Emitter<CoinAddressesState> emit) async {
    emit(state.copyWith(status: () => FormStatus.submitting));

    try {
      final asset = getSdkAsset(sdk, assetId);
      final addresses = (await asset.getPubkeys()).keys;

      final reasons = await asset.getCantCreateNewAddressReasons(sdk);

      emit(state.copyWith(
        status: () => FormStatus.success,
        addresses: () => addresses,
        cantCreateNewAddressReasons: () => reasons,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: () => FormStatus.failure,
        errorMessage: () => e.toString(),
      ));
    }
  }

  void _onUpdateHideZeroBalance(
      UpdateHideZeroBalanceEvent event, Emitter<CoinAddressesState> emit) {
    emit(state.copyWith(hideZeroBalance: () => event.hideZeroBalance));
  }
}
