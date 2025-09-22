part of 'nft_image_bloc.dart';

/// Image loading states for NFT image fallback mechanism
enum NftImageStatus { initial, loading, success, retrying, exhausted, failure }

/// NFT media types for display handling
enum NftMediaType { image, video, svg, gif, unknown }

/// State for NFT image loading with fallback mechanism
class NftImageState extends Equatable {
  const NftImageState({
    this.status = NftImageStatus.initial,
    this.currentUrl,
    this.currentUrlIndex = 0,
    this.retryCount = 0,
    this.allUrls = const [],
    this.errorMessage,
    this.isRetrying = false,
    this.mediaType = NftMediaType.unknown,
  });

  final NftImageStatus status;
  final String? currentUrl;
  final int currentUrlIndex;
  final int retryCount;
  final List<String> allUrls;
  final String? errorMessage;
  final bool isRetrying;
  final NftMediaType mediaType;

  /// Whether there are more URLs to try
  bool get hasMoreUrls => currentUrlIndex < allUrls.length - 1;

  /// Whether all URLs have been exhausted
  bool get isExhausted =>
      currentUrlIndex >= allUrls.length - 1 && status == NftImageStatus.failure;

  /// The next URL to try
  String? get nextUrl {
    if (!hasMoreUrls) return null;
    return allUrls[currentUrlIndex + 1];
  }

  /// Whether the widget should show a placeholder
  bool get shouldShowPlaceholder =>
      status == NftImageStatus.exhausted ||
      (status == NftImageStatus.failure && !hasMoreUrls);

  /// Whether the widget is in a loading state
  bool get isLoading =>
      status == NftImageStatus.loading ||
      status == NftImageStatus.retrying ||
      currentUrl == null;

  NftImageState copyWith({
    NftImageStatus? status,
    String? currentUrl,
    int? currentUrlIndex,
    int? retryCount,
    List<String>? allUrls,
    String? errorMessage,
    bool? isRetrying,
    NftMediaType? mediaType,
  }) {
    return NftImageState(
      status: status ?? this.status,
      currentUrl: currentUrl ?? this.currentUrl,
      currentUrlIndex: currentUrlIndex ?? this.currentUrlIndex,
      retryCount: retryCount ?? this.retryCount,
      allUrls: allUrls ?? this.allUrls,
      errorMessage: errorMessage,
      isRetrying: isRetrying ?? this.isRetrying,
      mediaType: mediaType ?? this.mediaType,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentUrl,
    currentUrlIndex,
    retryCount,
    allUrls,
    errorMessage,
    isRetrying,
    mediaType,
  ];
}
