part of 'nft_image_bloc.dart';

/// Events for NFT image loading with fallback mechanism
abstract class NftImageEvent extends Equatable {
  const NftImageEvent();
}

/// Event to start loading an image (bloc will generate fallback URLs)
class NftImageLoadStarted extends NftImageEvent {
  const NftImageLoadStarted({required this.imageUrl});

  final String imageUrl;

  @override
  List<Object> get props => [imageUrl];
}

/// Event triggered when an image fails to load
class NftImageLoadFailed extends NftImageEvent {
  const NftImageLoadFailed({required this.failedUrl, this.errorMessage});

  final String failedUrl;
  final String? errorMessage;

  @override
  List<Object?> get props => [failedUrl, errorMessage];
}

/// Event triggered when an image loads successfully
class NftImageLoadSucceeded extends NftImageEvent {
  const NftImageLoadSucceeded({required this.loadedUrl, this.loadTime});

  final String loadedUrl;
  final Duration? loadTime;

  @override
  List<Object?> get props => [loadedUrl, loadTime];
}

/// Event to start retrying with the next URL in the fallback list
class NftImageRetryStarted extends NftImageEvent {
  const NftImageRetryStarted();

  @override
  List<Object> get props => [];
}

/// Event when the image loading state has been cleared
class NftImageCleared extends NftImageEvent {
  const NftImageCleared();

  @override
  List<Object> get props => [];
}
