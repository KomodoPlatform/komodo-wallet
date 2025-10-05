import 'package:flutter/material.dart';

/// Performance optimization utilities for onboarding flow
///
/// Phase 4: Provides lazy loading, caching, and optimization
/// helpers to improve performance and reduce bundle size.
class PerformanceOptimizations {
  /// Debounce callback execution
  static void Function() debounce(
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    var timer;
    return () {
      if (timer != null) {
        timer.cancel();
      }
      timer = Future.delayed(delay, callback);
    };
  }

  /// Throttle callback execution
  static VoidCallback throttle(
    VoidCallback callback, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    bool isThrottled = false;
    return () {
      if (isThrottled) return;
      isThrottled = true;
      callback();
      Future.delayed(duration, () {
        isThrottled = false;
      });
    };
  }
}

/// Lazy loading widget for expensive components
///
/// Phase 4: Delays rendering of expensive widgets until needed
class LazyLoadWidget extends StatefulWidget {
  const LazyLoadWidget({
    required this.builder,
    this.placeholder,
    this.delay = const Duration(milliseconds: 100),
    super.key,
  });

  final WidgetBuilder builder;
  final Widget? placeholder;
  final Duration delay;

  @override
  State<LazyLoadWidget> createState() => _LazyLoadWidgetState();
}

class _LazyLoadWidgetState extends State<LazyLoadWidget> {
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded) {
      return widget.builder(context);
    }
    return widget.placeholder ?? const SizedBox.shrink();
  }
}

/// Optimized autocomplete field with caching
///
/// Phase 4: Enhanced autocomplete with performance optimizations
class OptimizedAutocompleteField extends StatefulWidget {
  const OptimizedAutocompleteField({
    required this.controller,
    required this.suggestions,
    required this.onSuggestionSelected,
    this.maxSuggestions = 5,
    this.debounceDelay = const Duration(milliseconds: 200),
    this.labelText,
    this.hintText,
    super.key,
  });

  final TextEditingController controller;
  final List<String> Function(String) suggestions;
  final ValueChanged<String> onSuggestionSelected;
  final int maxSuggestions;
  final Duration debounceDelay;
  final String? labelText;
  final String? hintText;

  @override
  State<OptimizedAutocompleteField> createState() =>
      _OptimizedAutocompleteFieldState();
}

class _OptimizedAutocompleteFieldState
    extends State<OptimizedAutocompleteField> {
  final Map<String, List<String>> _cache = {};
  List<String> _currentSuggestions = [];
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text.toLowerCase().trim();

    if (text.isEmpty) {
      _removeOverlay();
      return;
    }

    // Check cache first
    if (_cache.containsKey(text)) {
      _updateSuggestions(_cache[text]!);
      return;
    }

    // Debounce expensive suggestion computation
    Future.delayed(widget.debounceDelay, () {
      if (!mounted) return;
      if (widget.controller.text.toLowerCase().trim() != text) return;

      final suggestions = widget.suggestions(text);
      _cache[text] = suggestions;
      _updateSuggestions(suggestions);
    });
  }

  void _updateSuggestions(List<String> suggestions) {
    if (!mounted) return;

    setState(() {
      _currentSuggestions = suggestions.take(widget.maxSuggestions).toList();
    });

    if (_currentSuggestions.isEmpty) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: context.size?.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _currentSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _currentSuggestions[index];
                  return ListTile(
                    dense: true,
                    title: Text(suggestion),
                    onTap: () {
                      widget.onSuggestionSelected(suggestion);
                      _removeOverlay();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
        ),
      ),
    );
  }
}

/// Optimized image loader with caching
///
/// Phase 4: Image widget with memory-efficient caching
class OptimizedImage extends StatelessWidget {
  const OptimizedImage({
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    super.key,
  });

  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width != null ? (width! * 2).toInt() : null,
      cacheHeight: height != null ? (height! * 2).toInt() : null,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: const Color(0xFF2B2D40),
          child: const Icon(
            Icons.image_not_supported,
            color: Color(0xFF797B89),
          ),
        );
      },
    );
  }
}

/// Memoized builder widget to prevent unnecessary rebuilds
///
/// Phase 4: Cached widget builder for expensive widgets
class MemoizedBuilder extends StatefulWidget {
  const MemoizedBuilder({
    required this.builder,
    this.dependencies = const [],
    super.key,
  });

  final WidgetBuilder builder;
  final List<Object> dependencies;

  @override
  State<MemoizedBuilder> createState() => _MemoizedBuilderState();
}

class _MemoizedBuilderState extends State<MemoizedBuilder> {
  Widget? _cachedWidget;
  List<Object>? _lastDependencies;

  @override
  Widget build(BuildContext context) {
    final dependenciesChanged =
        _lastDependencies == null ||
        !_areListsEqual(_lastDependencies!, widget.dependencies);

    if (dependenciesChanged || _cachedWidget == null) {
      _cachedWidget = widget.builder(context);
      _lastDependencies = List.from(widget.dependencies);
    }

    return _cachedWidget!;
  }

  bool _areListsEqual(List<Object> a, List<Object> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Performance monitor for debugging
///
/// Phase 4: Helper to track widget rebuild performance
class PerformanceMonitor extends StatelessWidget {
  const PerformanceMonitor({
    required this.child,
    required this.label,
    this.enabled = false,
    super.key,
  });

  final Widget child;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Builder(
      builder: (context) {
        final startTime = DateTime.now();
        final result = child;
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        if (duration.inMilliseconds > 16) {
          // Log if render takes longer than 1 frame (16ms at 60fps)
          debugPrint(
            '⚠️ PerformanceMonitor [$label]: ${duration.inMilliseconds}ms',
          );
        }

        return result;
      },
    );
  }
}

/// Delayed initialization mixin for expensive state setup
///
/// Phase 4: Mixin to defer expensive initialization
mixin DelayedInitialization<T extends StatefulWidget> on State<T> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Defer expensive initialization to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        performDelayedInitialization();
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  /// Override this method to perform expensive initialization
  void performDelayedInitialization();

  /// Check if delayed initialization is complete
  bool get isInitialized => _isInitialized;
}
