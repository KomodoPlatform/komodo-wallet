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
    required this.hdType,
  });

  final String collectionName;
  final String tokenId;
  final String hdType;

  @override
  String get name => 'nft_transfer_initiated';

  @override
  JsonMap get parameters => {
    'collection_name': collectionName,
    'token_id': tokenId,
    'hd_type': hdType,
  };
}

class AnalyticsNftTransferInitiatedEvent extends AnalyticsSendDataEvent {
  AnalyticsNftTransferInitiatedEvent({
    required String collectionName,
    required String tokenId,
    required String hdType,
  }) : super(
         NftTransferInitiatedEventData(
           collectionName: collectionName,
           tokenId: tokenId,
           hdType: hdType,
         ),
       );
}

/// E25: NFT sent successfully
class NftTransferSuccessEventData extends AnalyticsEventData {
  const NftTransferSuccessEventData({
    required this.collectionName,
    required this.tokenId,
    required this.fee,
    required this.hdType,
  });

  final String collectionName;
  final String tokenId;
  final double fee;
  final String hdType;

  @override
  String get name => 'nft_transfer_success';

  @override
  JsonMap get parameters => {
    'collection_name': collectionName,
    'token_id': tokenId,
    'fee': fee,
    'hd_type': hdType,
  };
}

class AnalyticsNftTransferSuccessEvent extends AnalyticsSendDataEvent {
  AnalyticsNftTransferSuccessEvent({
    required String collectionName,
    required String tokenId,
    required double fee,
    required String hdType,
  }) : super(
         NftTransferSuccessEventData(
           collectionName: collectionName,
           tokenId: tokenId,
           fee: fee,
           hdType: hdType,
         ),
       );
}

/// E26: NFT send failed
class NftTransferFailureEventData extends AnalyticsEventData {
  const NftTransferFailureEventData({
    required this.collectionName,
    required this.failureDetail,
    required this.hdType,
  });

  final String collectionName;
  final String failureDetail;
  final String hdType;

  @override
  String get name => 'nft_transfer_failure';

  @override
  JsonMap get parameters => {
    'collection_name': collectionName,
    'failure_reason': _formatFailureReason(reason: failureDetail),
    'hd_type': hdType,
  };
}

class AnalyticsNftTransferFailureEvent extends AnalyticsSendDataEvent {
  AnalyticsNftTransferFailureEvent({
    required String collectionName,
    required String failureDetail,
    required String hdType,
  }) : super(
         NftTransferFailureEventData(
           collectionName: collectionName,
           failureDetail: failureDetail,
           hdType: hdType,
         ),
       );
}

String _formatFailureReason({String? stage, String? reason, String? code}) {
  final parts = <String>[];

  String? sanitize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  final sanitizedStage = sanitize(stage);
  final sanitizedReason = sanitize(reason);
  final sanitizedCode = sanitize(code);

  if (sanitizedStage != null) {
    parts.add('stage:$sanitizedStage');
  }
  if (sanitizedReason != null) {
    parts.add('reason:$sanitizedReason');
  }
  if (sanitizedCode != null && sanitizedCode != sanitizedReason) {
    parts.add('code:$sanitizedCode');
  }

  if (parts.isEmpty) {
    return 'reason:unknown';
  }
  return parts.join('|');
}
