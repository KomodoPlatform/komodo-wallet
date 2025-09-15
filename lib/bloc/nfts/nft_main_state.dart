part of 'nft_main_bloc.dart';

class NftMainState extends Equatable {
  const NftMainState({
    required this.nfts,
    required this.selectedChain,
    required this.nftCount,
    required this.sortedChains,
    required this.isInitialized,
    required this.updatingChains,
    this.error,
  });

  factory NftMainState.initial() => const NftMainState(
    nfts: {},
    isInitialized: false,
    updatingChains: {},
    selectedChain: NftBlockchains.eth,
    nftCount: {},
    sortedChains: [],
  );

  final Map<NftBlockchains, List<NftToken>?> nfts;
  final NftBlockchains selectedChain;
  final bool isInitialized;
  final Map<NftBlockchains, bool> updatingChains;
  final Map<NftBlockchains, int?> nftCount;
  final List<NftBlockchains> sortedChains;
  final BaseError? error;

  @override
  List<Object?> get props => [
    nfts,
    selectedChain,
    nftCount,
    sortedChains,
    error,
    updatingChains,
    isInitialized,
  ];

  NftMainState copyWith({
    Map<NftBlockchains, List<NftToken>?> Function()? nfts,
    NftBlockchains Function()? selectedChain,
    bool Function()? isInitialized,
    Map<NftBlockchains, int?> Function()? nftCount,
    List<NftBlockchains> Function()? sortedChains,
    BaseError? Function()? error,
    Map<NftBlockchains, bool> Function()? updatingChains,
  }) {
    return NftMainState(
      nfts: nfts != null ? nfts() : this.nfts,
      selectedChain: selectedChain != null
          ? selectedChain()
          : this.selectedChain,
      nftCount: nftCount != null ? nftCount() : this.nftCount,
      sortedChains: sortedChains != null ? sortedChains() : this.sortedChains,
      isInitialized: isInitialized != null
          ? isInitialized()
          : this.isInitialized,
      error: error != null ? error() : this.error,
      updatingChains: updatingChains != null
          ? updatingChains()
          : this.updatingChains,
    );
  }
}
