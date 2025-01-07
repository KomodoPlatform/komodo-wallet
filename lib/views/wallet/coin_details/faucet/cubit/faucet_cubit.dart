import 'package:bloc/bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/3p_api/faucet/faucet.dart' as api;
import 'package:web_dex/3p_api/faucet/faucet_response.dart';
import 'package:web_dex/views/wallet/coin_details/faucet/cubit/faucet_state.dart';

class FaucetCubit extends Cubit<FaucetState> {
  final String coinAbbr;
  final KomodoDefiSdk kdfSdk;

  FaucetCubit({
    required this.coinAbbr,
    required this.kdfSdk,
  }) : super(const FaucetInitial());

  Future<void> callFaucet() async {
    emit(const FaucetLoading());
    try {
      // Temporary band-aid fix to faucet to support HD wallet - currently 
      // defaults to calling faucet on all addresses
      // TODO: maybe add faucet button per address, or ask user if they want 
      // to faucet all addresses at once (or offer both options)
      final asset = kdfSdk.assets.assetsFromTicker(coinAbbr).single;
      final addresses = (await asset.getPubkeys(kdfSdk)).keys;
      final faucetFutures = addresses.map((address) async {
        return await api.callFaucet(coinAbbr, address.address);
      }).toList();
      final responses = await Future.wait<FaucetResponse>(faucetFutures);
      if (!responses
          .any((response) => response.status == FaucetStatus.success)) {
        return emit(FaucetError(responses.first.message));
      } else {
        final response = responses.firstWhere(
          (response) => response.status == FaucetStatus.success,
        );
        return emit(FaucetSuccess(response));
      }
    } catch (error) {
      return emit(FaucetError(error.toString()));
    }
  }
}
