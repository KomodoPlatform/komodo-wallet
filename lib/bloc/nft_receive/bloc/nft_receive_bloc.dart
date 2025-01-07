import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/blocs/current_wallet_bloc.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/nft.dart';
import 'package:web_dex/views/dex/dex_helpers.dart';

part 'nft_receive_event.dart';
part 'nft_receive_state.dart';

class NftReceiveBloc extends Bloc<NftReceiveEvent, NftReceiveState> {
  NftReceiveBloc({
    required CoinsRepo coinsRepo,
    required CurrentWalletBloc currentWalletBloc,
  })  : _coinsRepo = coinsRepo,
        _currentWalletBloc = currentWalletBloc,
        super(NftReceiveInitial()) {
    on<NftReceiveEventInitial>(_onInitial);
    on<NftReceiveEventRefresh>(_onRefresh);
    on<NftReceiveEventChangedAddress>(_onChangeAddress);
  }

  final CoinsRepo _coinsRepo;
  final CurrentWalletBloc _currentWalletBloc;
  NftBlockchains? chain;

  Future<void> _onInitial(NftReceiveEventInitial event, Emitter emit) async {
    if (state is! NftReceiveAddress) {
      chain = event.chain;
      final abbr = event.chain.coinAbbr();
      var coin = _coinsRepo.getCoin(abbr);

      if (coin != null) {
        final walletConfig = _currentWalletBloc.wallet?.config;
        if (walletConfig?.hasBackup == false && !coin.isTestCoin) {
          return emit(
            NftReceiveHasBackup(),
          );
        }

        if (coin.address?.isEmpty ?? true) {
          final activationErrors =
              await activateCoinIfNeeded(coin.abbr, _coinsRepo);
          if (activationErrors.isNotEmpty) {
            return emit(
              NftReceiveFailure(
                message: activationErrors.first.error,
              ),
            );
          }
          coin = _coinsRepo.getCoin(abbr)!;
        }

        return emit(
          NftReceiveAddress(
            coin: coin,
            address: coin.defaultAddress,
          ),
        );
      }

      return emit(const NftReceiveFailure());
    }
  }

  Future<void> _onRefresh(NftReceiveEventRefresh event, Emitter emit) async {
    final localChain = chain;
    if (localChain != null) {
      emit(NftReceiveEventInitial(chain: localChain));
      add(NftReceiveEventInitial(chain: localChain));
    } else {
      return emit(const NftReceiveFailure());
    }
  }

  void _onChangeAddress(NftReceiveEventChangedAddress event, Emitter emit) {
    final state = this.state;
    if (state is NftReceiveAddress) {
      return emit(
        state.copyWith(
          address: event.address,
        ),
      );
    }
  }
}
