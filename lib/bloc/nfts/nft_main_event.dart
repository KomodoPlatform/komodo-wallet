part of 'nft_main_bloc.dart';

abstract class NftMainEvent {
  const NftMainEvent();
}

class NftMainChainUpdateRequested extends NftMainEvent {
  const NftMainChainUpdateRequested();
}

class NftMainUpdateNftsStopped extends NftMainEvent {
  const NftMainUpdateNftsStopped();
}

class NftMainUpdateNftsStarted extends NftMainEvent {
  const NftMainUpdateNftsStarted();
}

class NftMainResetRequested extends NftMainEvent {
  const NftMainResetRequested();
}

class NftMainTabChanged extends NftMainEvent {
  const NftMainTabChanged(this.chain);
  final NftBlockchains chain;
}

class NftMainChainNftsRefreshed extends NftMainEvent {
  const NftMainChainNftsRefreshed(this.chain);
  final NftBlockchains chain;
}
