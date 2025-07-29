import 'dart:async';

import 'package:equatable/equatable.dart' show Equatable;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/shared/utils/ipfs_gateway_manager.dart';
import 'package:http/http.dart' as http;

part 'nft_image_event.dart';
part 'nft_image_state.dart';

/// BLoC for managing NFT image loading with fallback mechanism
class NftImageBloc extends Bloc<NftImageEvent, NftImageState> {
  NftImageBloc({required IpfsGatewayManager ipfsGatewayManager})
      : _ipfsGatewayManager = ipfsGatewayManager,
        super(const NftImageState()) {
    on<NftImageLoadRequested>(_onLoadImage);
    on<NftImageLoadFailed>(_onImageLoadFailed);
    on<NftImageLoadSucceeded>(_onImageLoadSuccess);
    on<NftImageRetryRequested>(_onRetryImageLoad);
    on<NftImageResetRequested>(_onResetImageLoad);
  }

  final IpfsGatewayManager _ipfsGatewayManager;

  static const int maxRetryAttempts = 3;
  static const Duration baseRetryDelay = Duration(seconds: 1);
  static const Duration urlTestTimeout = Duration(seconds: 5);

  Timer? _retryTimer;

  /// Test if a URL is accessible
  Future<bool> _testUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url)).timeout(urlTestTimeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Find the first working URL from the list
  Future<String?> _findWorkingUrl(List<String> urls, int startIndex) async {
    for (int i = startIndex; i < urls.length; i++) {
      final url = urls[i];

      // Skip URLs that are recently failed according to circuit breaker
      if (_ipfsGatewayManager.shouldSkipUrl(url)) {
        continue;
      }

      final isWorking = await _testUrl(url);
      if (isWorking) {
        return url;
      } else {
        // Log the failed attempt
        _ipfsGatewayManager.logGatewayAttempt(
          url,
          false,
          errorMessage: 'URL accessibility test failed',
        );
      }
    }
    return null;
  }

  /// Detect media type from URL
  static NftMediaType _detectMediaType(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.endsWith('.svg')) return NftMediaType.svg;
    if (lowerUrl.endsWith('.gif')) return NftMediaType.gif;
    if (lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.webm') ||
        lowerUrl.endsWith('.mov')) {
      return NftMediaType.video;
    }
    return NftMediaType.image;
  }

  /// Generates all possible URLs for the image including normalized URL and fallbacks
  List<String> _generateAllUrls(String imageUrl) {
    final List<String> urls = [];

    // First, try to normalize the URL if it's an IPFS URL
    final normalizedUrl = _ipfsGatewayManager.normalizeIpfsUrl(imageUrl);
    if (normalizedUrl != null && normalizedUrl != imageUrl) {
      urls.add(normalizedUrl);
    }

    // Add the original URL if not already added
    if (!urls.contains(imageUrl)) {
      urls.add(imageUrl);
    }

    // Generate IPFS gateway alternatives if it's an IPFS URL
    if (IpfsGatewayManager.isIpfsUrl(imageUrl)) {
      final ipfsUrls = _ipfsGatewayManager.getReliableGatewayUrls(imageUrl);
      // Add URLs that aren't already in the list
      for (final url in ipfsUrls) {
        if (!urls.contains(url)) {
          urls.add(url);
        }
      }
    }

    return urls;
  }

  /// Handles the load image event
  Future<void> _onLoadImage(
    NftImageLoadRequested event,
    Emitter<NftImageState> emit,
  ) async {
    _retryTimer?.cancel();

    final allUrls = _generateAllUrls(event.imageUrl);
    final mediaType = _detectMediaType(event.imageUrl);

    if (allUrls.isEmpty) {
      emit(state.copyWith(
        status: ImageLoadStatus.error,
        errorMessage: 'No URLs available to load',
        mediaType: mediaType,
      ));
      return;
    }

    // Emit initial state with all URLs but no current URL yet
    emit(state.copyWith(
      status: ImageLoadStatus.loading,
      currentUrl: null,
      currentUrlIndex: 0,
      retryCount: 0,
      allUrls: allUrls,
      errorMessage: null,
      isRetrying: false,
      mediaType: mediaType,
    ));

    // Find the first working URL
    final workingUrl = await _findWorkingUrl(allUrls, 0);

    if (workingUrl != null) {
      final urlIndex = allUrls.indexOf(workingUrl);
      emit(state.copyWith(
        status: ImageLoadStatus.loading,
        currentUrl: workingUrl,
        currentUrlIndex: urlIndex,
      ));
    } else {
      emit(state.copyWith(
        status: ImageLoadStatus.exhausted,
        errorMessage: 'No accessible URLs found',
      ));
    }
  }

  /// Handles image load failure - try next URL immediately
  Future<void> _onImageLoadFailed(
    NftImageLoadFailed event,
    Emitter<NftImageState> emit,
  ) async {
    // Log the failed attempt
    _ipfsGatewayManager.logGatewayAttempt(
      event.failedUrl,
      false,
      errorMessage: event.errorMessage,
    );

    // Try to find the next working URL
    final nextWorkingUrl =
        await _findWorkingUrl(state.allUrls, state.currentUrlIndex + 1);

    if (nextWorkingUrl != null && state.retryCount < maxRetryAttempts) {
      final urlIndex = state.allUrls.indexOf(nextWorkingUrl);
      emit(state.copyWith(
        status: ImageLoadStatus.loading,
        currentUrl: nextWorkingUrl,
        currentUrlIndex: urlIndex,
        retryCount: state.retryCount + 1,
        errorMessage: null,
        isRetrying: false,
      ));
    } else {
      // All URLs exhausted or max retries reached
      emit(state.copyWith(
        status: ImageLoadStatus.exhausted,
        errorMessage: event.errorMessage ?? 'All image URLs failed to load',
        isRetrying: false,
      ));
    }
  }

  /// Handles successful image load
  Future<void> _onImageLoadSuccess(
    NftImageLoadSucceeded event,
    Emitter<NftImageState> emit,
  ) async {
    _retryTimer?.cancel();

    // Log the successful attempt
    _ipfsGatewayManager.logGatewayAttempt(
      event.loadedUrl,
      true,
      loadTime: event.loadTime,
    );

    emit(state.copyWith(
      status: ImageLoadStatus.loaded,
      currentUrl: event.loadedUrl,
      errorMessage: null,
      isRetrying: false,
    ));
  }

  /// Handles manual retry request (only used for failed states)
  Future<void> _onRetryImageLoad(
    NftImageRetryRequested event,
    Emitter<NftImageState> emit,
  ) async {
    if (state.status == ImageLoadStatus.exhausted ||
        state.status == ImageLoadStatus.error) {
      // Try to find any working URL from the beginning
      final workingUrl = await _findWorkingUrl(state.allUrls, 0);

      if (workingUrl != null) {
        final urlIndex = state.allUrls.indexOf(workingUrl);
        emit(state.copyWith(
          status: ImageLoadStatus.loading,
          currentUrl: workingUrl,
          currentUrlIndex: urlIndex,
          retryCount: 0,
          errorMessage: null,
          isRetrying: false,
        ));
      }
    }
  }

  /// Handles reset event
  Future<void> _onResetImageLoad(
    NftImageResetRequested event,
    Emitter<NftImageState> emit,
  ) async {
    _retryTimer?.cancel();
    emit(const NftImageState());
  }

  @override
  Future<void> close() {
    _retryTimer?.cancel();
    return super.close();
  }
}
