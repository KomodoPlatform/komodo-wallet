import 'dart:async';

import 'package:equatable/equatable.dart' show Equatable;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/shared/utils/ipfs_gateway_manager.dart';

part 'nft_image_event.dart';
part 'nft_image_state.dart';

/// BLoC for managing NFT image loading with fallback mechanism
class NftImageBloc extends Bloc<NftImageEvent, NftImageState> {
  NftImageBloc({required IpfsGatewayManager ipfsGatewayManager})
    : _ipfsGatewayManager = ipfsGatewayManager,
      super(const NftImageState()) {
    on<NftImageLoadStarted>(_onImageLoadStarted);
    on<NftImageLoadFailed>(_onImageLoadFailed);
    on<NftImageLoadSucceeded>(_onImageLoadSucceeded);
    on<NftImageRetryStarted>(_onImageRetryStarted);
    on<NftImageCleared>(_onImageCleared);
  }

  final IpfsGatewayManager _ipfsGatewayManager;

  static const int maxRetryAttempts = 3;
  static const Duration baseRetryDelay = Duration(seconds: 1);

  Timer? _retryTimer;

  /// Find the first working URL from the list
  Future<String?> _findWorkingUrl(List<String> urls, int startIndex) async {
    return _ipfsGatewayManager.findWorkingUrl(
      urls,
      startIndex: startIndex,
      onUrlTested: (url, success, errorMessage) {
        if (!success) {
          // Log failed attempts are handled by the gateway manager
          // Additional logging can be done here if needed
        }
      },
    );
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
  Future<List<String>> _generateAllUrls(String imageUrl) async {
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
      final ipfsUrls = await _ipfsGatewayManager.getReliableGatewayUrls(
        imageUrl,
      );
      // Add URLs that aren't already in the list
      for (final url in ipfsUrls) {
        if (!urls.contains(url)) {
          urls.add(url);
        }
      }
    }

    return urls;
  }

  /// Handles the load image started event
  Future<void> _onImageLoadStarted(
    NftImageLoadStarted event,
    Emitter<NftImageState> emit,
  ) async {
    _retryTimer?.cancel();

    final allUrls = await _generateAllUrls(event.imageUrl);
    final mediaType = _detectMediaType(event.imageUrl);

    if (allUrls.isEmpty) {
      emit(
        state.copyWith(
          status: NftImageStatus.failure,
          errorMessage: 'No URLs available to load',
          mediaType: mediaType,
        ),
      );
      return;
    }

    // Emit initial state with all URLs but no current URL yet
    emit(
      state.copyWith(
        status: NftImageStatus.loading,
        currentUrl: null,
        currentUrlIndex: 0,
        retryCount: 0,
        allUrls: allUrls,
        errorMessage: null,
        isRetrying: false,
        mediaType: mediaType,
      ),
    );

    // Find the first working URL
    final workingUrl = await _findWorkingUrl(allUrls, 0);

    if (workingUrl != null) {
      final urlIndex = allUrls.indexOf(workingUrl);
      emit(
        state.copyWith(
          status: NftImageStatus.loading,
          currentUrl: workingUrl,
          currentUrlIndex: urlIndex,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: NftImageStatus.exhausted,
          errorMessage: 'No accessible URLs found',
        ),
      );
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
    final nextWorkingUrl = await _findWorkingUrl(
      state.allUrls,
      state.currentUrlIndex + 1,
    );

    if (nextWorkingUrl != null && state.retryCount < maxRetryAttempts) {
      final urlIndex = state.allUrls.indexOf(nextWorkingUrl);
      emit(
        state.copyWith(
          status: NftImageStatus.loading,
          currentUrl: nextWorkingUrl,
          currentUrlIndex: urlIndex,
          retryCount: state.retryCount + 1,
          errorMessage: null,
          isRetrying: false,
        ),
      );
    } else {
      // All URLs exhausted or max retries reached
      emit(
        state.copyWith(
          status: NftImageStatus.exhausted,
          errorMessage: event.errorMessage ?? 'All image URLs failed to load',
          isRetrying: false,
        ),
      );
    }
  }

  /// Handles successful image load
  Future<void> _onImageLoadSucceeded(
    NftImageLoadSucceeded event,
    Emitter<NftImageState> emit,
  ) async {
    // Return early if this URL is already successfully loaded
    if (state.status == NftImageStatus.success &&
        state.currentUrl == event.loadedUrl) {
      return;
    }

    _retryTimer?.cancel();

    // Log the successful attempt
    _ipfsGatewayManager.logGatewayAttempt(
      event.loadedUrl,
      true,
      loadTime: event.loadTime,
    );

    emit(
      state.copyWith(
        status: NftImageStatus.success,
        currentUrl: event.loadedUrl,
        errorMessage: null,
        isRetrying: false,
      ),
    );
  }

  /// Handles manual retry started event (only used for failed states)
  Future<void> _onImageRetryStarted(
    NftImageRetryStarted event,
    Emitter<NftImageState> emit,
  ) async {
    if (state.status == NftImageStatus.exhausted ||
        state.status == NftImageStatus.failure) {
      // Try to find any working URL from the beginning
      final workingUrl = await _findWorkingUrl(state.allUrls, 0);

      if (workingUrl != null) {
        final urlIndex = state.allUrls.indexOf(workingUrl);
        emit(
          state.copyWith(
            status: NftImageStatus.loading,
            currentUrl: workingUrl,
            currentUrlIndex: urlIndex,
            retryCount: 0,
            errorMessage: null,
            isRetrying: false,
          ),
        );
      }
    }
  }

  /// Handles clear event
  Future<void> _onImageCleared(
    NftImageCleared event,
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
