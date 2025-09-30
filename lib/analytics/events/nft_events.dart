import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:web_dex/bloc/analytics/analytics_event.dart';
import 'package:web_dex/bloc/analytics/analytics_repo.dart';

/// E23: NFT gallery opened
class NftGalleryOpenedEventData extends AnalyticsEventData {
  const NftGalleryOpenedEventData({
    required this.nftCount,
    required this.loadTimeMs,
  });

  final int nftCount;
  final int loadTimeMs;

  @override
  String get name => 'nft_gallery_opened';

  @override
  JsonMap get parameters => {'nft_count': nftCount, 'load_time_ms': loadTimeMs};
}

class AnalyticsNftGalleryOpenedEvent extends AnalyticsSendDataEvent {
  AnalyticsNftGalleryOpenedEvent({
    required int nftCount,
    required int loadTimeMs,
  }) : super(
         NftGalleryOpenedEventData(nftCount: nftCount, loadTimeMs: loadTimeMs),
       );
}

/// E24: NFT send flow started
class NftTransferInitiatedEventData extends AnalyticsEventData {
  const NftTransferInitiatedEventData({
    required this.collectionName,
    required this.tokenId,
    required this.walletType,
  });

  final String collectionName;
  final String tokenId;
  final String walletType;

  @override
  String get name => 'nft_transfer_initiated';

  @override
  JsonMap get parameters => {
    'collection_name': collectionName,
    'token_id': tokenId,
    'wallet_type': walletType,
  };
}

class AnalyticsNftTransferInitiatedEvent extends AnalyticsSendDataEvent {
  AnalyticsNftTransferInitiatedEvent({
    required String collectionName,
    required String tokenId,
    required String walletType,
  }) : super(
         NftTransferInitiatedEventData(
           collectionName: collectionName,
           tokenId: tokenId,
           walletType: walletType,
         ),
       );
}

/// E25: NFT sent successfully
class NftTransferSuccessEventData extends AnalyticsEventData {
  const NftTransferSuccessEventData({
    required this.collectionName,
    required this.tokenId,
    required this.fee,
    required this.walletType,
  });

  final String collectionName;
  final String tokenId;
  final double fee;
  final String walletType;

  @override
  String get name => 'nft_transfer_success';

  @override
  JsonMap get parameters => {
    'collection_name': collectionName,
    'token_id': tokenId,
    'fee': fee,
    'wallet_type': walletType,
  };
}

class AnalyticsNftTransferSuccessEvent extends AnalyticsSendDataEvent {
  AnalyticsNftTransferSuccessEvent({
    required String collectionName,
    required String tokenId,
    required double fee,
    required String walletType,
  }) : super(
         NftTransferSuccessEventData(
           collectionName: collectionName,
           tokenId: tokenId,
           fee: fee,
           walletType: walletType,
         ),
       );
}

/// E26: NFT send failed
class NftTransferFailureEventData extends AnalyticsEventData {
  const NftTransferFailureEventData({
    required this.collectionName,
    required this.failReason,
    required this.walletType,
  });

  final String collectionName;
  final String failReason;
  final String walletType;

  @override
  String get name => 'nft_transfer_failure';

  @override
  JsonMap get parameters => {
    'collection_name': collectionName,
    'fail_reason': failReason,
    'wallet_type': walletType,
  };
}

class AnalyticsNftTransferFailureEvent extends AnalyticsSendDataEvent {
  AnalyticsNftTransferFailureEvent({
    required String collectionName,
    required String failReason,
    required String walletType,
  }) : super(
         NftTransferFailureEventData(
           collectionName: collectionName,
           failReason: failReason,
           walletType: walletType,
         ),
       );
}
