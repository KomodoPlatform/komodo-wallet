import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:video_player/video_player.dart';
import 'package:web_dex/shared/utils/platform_tuner.dart';

enum NftImageType { image, video, placeholder }

class NftImage extends StatelessWidget {
  const NftImage({
    super.key,
    this.imagePath,
  });

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case NftImageType.image:
        return _NftImage(imageUrl: imagePath!);
      case NftImageType.video:
        // According to [video_player](https://pub.dev/packages/video_player)
        // it works only on Android, iOS, Web
        // Waiting for a future updates
        return PlatformTuner.isNativeDesktop
            ? const _NftPlaceholder()
            : _NftVideo(videoUrl: imagePath!);
      case NftImageType.placeholder:
        return const _NftPlaceholder();
    }
  }

  NftImageType get type {
    if (imagePath != null) {
      if (imagePath!.endsWith('.mp4')) {
        return NftImageType.video;
      } else {
        return NftImageType.image;
      }
    }
    return NftImageType.placeholder;
  }
}

class _NftImage extends StatelessWidget {
  const _NftImage({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final isSvg = imageUrl.endsWith('.svg');
    final isGif = imageUrl.endsWith('.gif');

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: isSvg
          ? SvgPicture.network(imageUrl, fit: BoxFit.cover)
          : Image.network(
              imageUrl,
              filterQuality: FilterQuality.high,
              fit: BoxFit.cover,
              gaplessPlayback: isGif, // Ensures smoother GIF animation
              errorBuilder: (_, error, stackTrace) {
                debugPrint('Error loading image: $error');
                debugPrintStack(stackTrace: stackTrace);
                return const _NftPlaceholder();
              },
            ),
    );
  }
}

class _NftVideo extends StatefulWidget {
  const _NftVideo({required this.videoUrl});

  final String videoUrl;

  @override
  State<_NftVideo> createState() => _NftVideoState();
}

class _NftVideoState extends State<_NftVideo> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    _controller.initialize().then((_) {
      _controller.setLooping(true);
      _controller.play();
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: VideoPlayer(_controller),
          )
        : const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          );
  }
}

class _NftPlaceholder extends StatelessWidget {
  const _NftPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Icon(Icons.monetization_on, size: 36),
      ),
    );
  }
}
