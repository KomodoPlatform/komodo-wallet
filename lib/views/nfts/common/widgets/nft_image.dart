import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:video_player/video_player.dart';
import 'package:web_dex/shared/utils/platform_tuner.dart';
import 'package:web_dex/shared/utils/ipfs_gateway_manager.dart';
import 'package:web_dex/bloc/nft_image/nft_image_bloc.dart';

enum NftImageType { image, video, placeholder }

class NftImage extends StatelessWidget {
  const NftImage({super.key, this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          NftImageBloc(ipfsGatewayManager: context.read<IpfsGatewayManager>()),
      child: Builder(
        builder: (context) {
          switch (type) {
            case NftImageType.image:
              return _NftImageWithFallback(
                key: ValueKey(imageUrl!),
                imageUrl: imageUrl!,
              );
            case NftImageType.video:
              // According to [video_player](https://pub.dev/packages/video_player)
              // it works only on Android, iOS, Web
              // Waiting for a future updates
              return PlatformTuner.isNativeDesktop
                  ? const _NftPlaceholder()
                  : _NftVideoWithFallback(
                      key: ValueKey(imageUrl!),
                      videoUrl: imageUrl!,
                    );
            case NftImageType.placeholder:
              return const _NftPlaceholder();
          }
        },
      ),
    );
  }

  NftImageType get type {
    if (imageUrl != null) {
      final path = imageUrl!.toLowerCase();
      if (path.endsWith('.mp4') ||
          path.endsWith('.webm') ||
          path.endsWith('.mov')) {
        return NftImageType.video;
      } else {
        return NftImageType.image;
      }
    }
    return NftImageType.placeholder;
  }
}

class _NftImageWithFallback extends StatefulWidget {
  const _NftImageWithFallback({required this.imageUrl, super.key});

  final String imageUrl;

  @override
  State<_NftImageWithFallback> createState() => _NftImageWithFallbackState();
}

class _NftImageWithFallbackState extends State<_NftImageWithFallback> {
  @override
  void initState() {
    super.initState();
    // Request the bloc to start loading and finding a working URL
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NftImageBloc>().add(
        NftImageLoadRequested(imageUrl: widget.imageUrl),
      );
    });
  }

  @override
  void didUpdateWidget(covariant _NftImageWithFallback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      final bloc = context.read<NftImageBloc>();
      bloc.add(const NftImageResetRequested());
      bloc.add(NftImageLoadRequested(imageUrl: widget.imageUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NftImageBloc, NftImageState>(
      builder: (context, state) {
        // Show placeholder for exhausted or error states
        if (state.shouldShowPlaceholder) {
          return const _NftPlaceholder();
        }

        // Show loading indicator if no URL is ready yet
        if (state.isLoading && state.currentUrl == null) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        // Don't render anything if we don't have a current URL
        if (state.currentUrl == null) {
          return const _NftPlaceholder();
        }

        final currentUrl = state.currentUrl!;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: _buildImageWidget(context, state, currentUrl),
        );
      },
    );
  }

  Widget _buildImageWidget(
    BuildContext context,
    NftImageState state,
    String currentUrl,
  ) {
    switch (state.mediaType) {
      case NftMediaType.svg:
        return SvgPicture.network(
          currentUrl,
          fit: BoxFit.cover,
          placeholderBuilder: (_) =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      case NftMediaType.gif:
      case NftMediaType.image:
      default:
        return Image.network(
          currentUrl,
          filterQuality: FilterQuality.high,
          fit: BoxFit.cover,
          gaplessPlayback: state.mediaType == NftMediaType.gif,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              // Image loaded successfully - notify bloc
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.read<NftImageBloc>().add(
                    NftImageLoadSucceeded(loadedUrl: currentUrl),
                  );
                }
              });
              return child;
            }

            // Show loading indicator while image is loading
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // Handle image load error - notify bloc to try next URL
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.read<NftImageBloc>().add(
                  NftImageLoadFailed(
                    failedUrl: currentUrl,
                    errorMessage: error.toString(),
                  ),
                );
              }
            });

            // Show loading indicator while bloc processes the failure
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
        );
    }
  }
}

class _NftVideoWithFallback extends StatefulWidget {
  const _NftVideoWithFallback({required this.videoUrl, super.key});

  final String videoUrl;

  @override
  State<_NftVideoWithFallback> createState() => _NftVideoWithFallbackState();
}

class _NftVideoWithFallbackState extends State<_NftVideoWithFallback> {
  VideoPlayerController? _controller;
  String? currentVideoUrl;

  @override
  void initState() {
    super.initState();
    // Don't initialize controller with empty URI - wait for valid URL

    // Request the bloc to start loading and finding a working URL
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NftImageBloc>().add(
        NftImageLoadRequested(imageUrl: widget.videoUrl),
      );
    });
  }

  @override
  void didUpdateWidget(covariant _NftVideoWithFallback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.dispose();
      _controller = null;
      currentVideoUrl = null;
      final bloc = context.read<NftImageBloc>();
      bloc.add(const NftImageResetRequested());
      bloc.add(NftImageLoadRequested(imageUrl: widget.videoUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NftImageBloc, NftImageState>(
      listener: (context, state) {
        // Handle URL changes from the bloc
        if (state.currentUrl != null && state.currentUrl != currentVideoUrl) {
          _initializeVideoController(state.currentUrl!);
        }
      },
      builder: (context, state) {
        if (state.shouldShowPlaceholder) {
          return const _NftPlaceholder();
        }

        if (currentVideoUrl == null || state.isLoading || _controller == null) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        return _controller!.value.isInitialized
            ? ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: VideoPlayer(_controller!),
              )
            : const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
    );
  }

  void _initializeVideoController(String videoUrl) {
    _controller?.dispose();
    currentVideoUrl = videoUrl;

    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    _controller!
        .initialize()
        .then((_) {
          if (mounted) {
            setState(() {});
            _controller!.setLooping(true);
            _controller!.play();

            // Notify bloc of successful load
            context.read<NftImageBloc>().add(
              NftImageLoadSucceeded(loadedUrl: videoUrl),
            );
          }
        })
        .catchError((error) {
          debugPrint('Error initializing video from $videoUrl: $error');
          if (mounted) {
            // Notify bloc of failed load
            context.read<NftImageBloc>().add(
              NftImageLoadFailed(
                failedUrl: videoUrl,
                errorMessage: error.toString(),
              ),
            );
          }
        });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class _NftPlaceholder extends StatelessWidget {
  const _NftPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: const Center(child: Icon(Icons.monetization_on, size: 36)),
    );
  }
}
