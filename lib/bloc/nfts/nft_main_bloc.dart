import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/nfts/nft_main_repo.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/model/nft.dart';
import 'package:web_dex/model/text_error.dart';

part 'nft_main_event.dart';
part 'nft_main_state.dart';

class NftMainBloc extends Bloc<NftMainEvent, NftMainState> {
  NftMainBloc({
    required NftsRepo repo,
    required KomodoDefiSdk sdk,
  })  : _repo = repo,
        _sdk = sdk,
        super(NftMainState.initial()) {
    on<UpdateChainNftsEvent>(_onUpdateChainNfts);
    on<ChangeNftTabEvent>(_onChangeTab);
    on<ResetNftPageEvent>(_onReset);
    on<RefreshNFTsForChainEvent>(_onRefreshForChain);
    on<StartUpdateNftsEvent>(_onStartUpdate);
    on<StopUpdateNftEvent>(_onStopUpdate);

    _authorizationSubscription = _sdk.auth.authStateChanges.listen((event) {
      final isSignedIn = event != null;
      if (isSignedIn) {
        add(const UpdateChainNftsEvent());
      } else {
        add(const ResetNftPageEvent());
      }
    });
  }

  final NftsRepo _repo;
  final KomodoDefiSdk _sdk;
  late StreamSubscription<KdfUser?> _authorizationSubscription;
  Timer? _updateTimer;

  Future<void> _onChangeTab(
    ChangeNftTabEvent event,
    Emitter<NftMainState> emit,
  ) async {
    emit(state.copyWith(selectedChain: () => event.chain));
    if (!await _sdk.auth.isSignedIn() || !state.isInitialized) {
      return;
    }

    try {
      final List<NftToken> nftList = await _repo.getNfts([event.chain]);

      final (newNftS, newNftCount) =
          _recalculateNftsForChain(nftList, event.chain);
      emit(
        state.copyWith(
          nfts: () => newNftS,
          nftCount: () => newNftCount,
          error: () => null,
        ),
      );
    } on BaseError catch (e) {
      emit(state.copyWith(error: () => e));
    } catch (e) {
      emit(state.copyWith(error: () => TextError(error: e.toString())));
    }
  }

  Future<void> _onUpdateChainNfts(
    UpdateChainNftsEvent event,
    Emitter<NftMainState> emit,
  ) async {
    if (!await _sdk.auth.isSignedIn()) {
      return;
    }

    try {
      final Map<NftBlockchains, List<NftToken>> nfts = await _getAllNfts();
      final (counts, sortedChains) = _calculateNftCount(nfts);

      emit(
        state.copyWith(
          nftCount: () => counts,
          nfts: () => nfts,
          sortedChains: () => sortedChains,
          selectedChain: state.isInitialized ? null : () => sortedChains.first,
          isInitialized: () => true,
          error: () => null,
        ),
      );
    } on BaseError catch (e) {
      emit(state.copyWith(error: () => e));
    } catch (e) {
      emit(state.copyWith(error: () => TextError(error: e.toString())));
    } finally {
      emit(state.copyWith(isInitialized: () => true));
    }
  }

  void _onReset(ResetNftPageEvent event, Emitter<NftMainState> emit) {
    emit(NftMainState.initial());
  }

  Future<void> _onRefreshForChain(
    RefreshNFTsForChainEvent event,
    Emitter<NftMainState> emit,
  ) async {
    if (!await _sdk.auth.isSignedIn() || !state.isInitialized) {
      return;
    }

    final updatingChains = _addUpdatingChains(event.chain);
    emit(state.copyWith(updatingChains: () => updatingChains));

    try {
      final List<NftToken> nftList = await _repo.getNfts([event.chain]);

      final (newNftS, newNftCount) =
          _recalculateNftsForChain(nftList, event.chain);
      emit(
        state.copyWith(
          nfts: () => newNftS,
          nftCount: () => newNftCount,
          error: () => null,
        ),
      );
    } on BaseError catch (e) {
      emit(state.copyWith(error: () => e));
    } catch (e) {
      emit(state.copyWith(error: () => TextError(error: e.toString())));
    } finally {
      final updatingChains = _removeUpdatingChains(event.chain);
      emit(state.copyWith(updatingChains: () => updatingChains));
    }
  }

  void _onStopUpdate(StopUpdateNftEvent event, Emitter<NftMainState> emit) {
    _stopUpdate();
  }

  void _onStartUpdate(StartUpdateNftsEvent event, Emitter<NftMainState> emit) {
    _stopUpdate();
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      add(const UpdateChainNftsEvent());
    });
  }

  Future<Map<NftBlockchains, List<NftToken>>> _getAllNfts({
    List<NftBlockchains> chains = NftBlockchains.values,
  }) async {
    await _repo.updateNft(chains);
    final List<NftToken> list = await _repo.getNfts(chains);

    final Map<NftBlockchains, List<NftToken>> nfts =
        list.fold<Map<NftBlockchains, List<NftToken>>>(
      <NftBlockchains, List<NftToken>>{},
      (prev, element) {
        final List<NftToken> chainList = prev[element.chain] ?? []
          ..add(element);
        prev[element.chain] = chainList;

        return prev;
      },
    );

    return nfts;
  }

  (Map<NftBlockchains, int>, List<NftBlockchains>) _calculateNftCount(
    Map<NftBlockchains, List<NftToken>> nfts,
  ) {
    final Map<NftBlockchains, int> countMap = {};

    for (final NftBlockchains chain in NftBlockchains.values) {
      final count = nfts[chain]?.length ?? 0;
      countMap[chain] = count;
    }

    final sorted = countMap.entries.toList()..sort((a, b) => b.value - a.value);
    final List<NftBlockchains> sortedTabs = sorted.map((e) => e.key).toList();

    return (countMap, sortedTabs);
  }

  void _stopUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  (
    Map<NftBlockchains, List<NftToken>?>,
    Map<NftBlockchains, int?>
  ) _recalculateNftsForChain(List<NftToken> newNftList, NftBlockchains chain) {
    final Map<NftBlockchains, int?> nftCount = {...state.nftCount};
    final Map<NftBlockchains, List<NftToken>?> nfts = {...state.nfts};
    nfts[chain] = newNftList;
    nftCount[chain] = newNftList.length;

    return (nfts, nftCount);
  }

  Map<NftBlockchains, bool> _addUpdatingChains(NftBlockchains chain) {
    final Map<NftBlockchains, bool> updatingChains = {...state.updatingChains};
    updatingChains[chain] = true;
    return updatingChains;
  }

  Map<NftBlockchains, bool> _removeUpdatingChains(NftBlockchains chain) {
    final Map<NftBlockchains, bool> updatingChains = {...state.updatingChains};
    updatingChains[chain] = false;
    return updatingChains;
  }

  @override
  Future<void> close() {
    _authorizationSubscription.cancel();
    _stopUpdate();
    return super.close();
  }
}
