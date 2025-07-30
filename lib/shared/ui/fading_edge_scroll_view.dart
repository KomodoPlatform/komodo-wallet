import 'package:flutter/material.dart';

/// Flutter widget for displaying fading edge at start/end of scroll views
class FadingEdgeScrollView extends StatefulWidget {
  /// child widget
  final Widget child;

  /// scroll controller of child widget
  ///
  /// Look for more documentation at [ScrollView.scrollController]
  final ScrollController scrollController;

  /// Whether the scroll view scrolls in the reading direction.
  ///
  /// Look for more documentation at [ScrollView.reverse]
  final bool reverse;

  /// The axis along which child view scrolls
  ///
  /// Look for more documentation at [ScrollView.scrollDirection]
  final Axis scrollDirection;

  /// what part of screen on start half should be covered by fading edge gradient
  /// [gradientFractionOnStart] must be 0 <= [gradientFractionOnStart] <= 1
  /// 0 means no gradient,
  /// 1 means gradients on start half of widget fully covers it
  final double gradientFractionOnStart;

  /// what part of screen on end half should be covered by fading edge gradient
  /// [gradientFractionOnEnd] must be 0 <= [gradientFractionOnEnd] <= 1
  /// 0 means no gradient,
  /// 1 means gradients on start half of widget fully covers it
  final double gradientFractionOnEnd;

  /// set to true if you want scrollController passed to widget to be disposed when widget's state is disposed
  final bool shouldDisposeScrollController;

  const FadingEdgeScrollView._internal({
    Key? key,
    required this.child,
    required this.scrollController,
    required this.reverse,
    required this.scrollDirection,
    required this.gradientFractionOnStart,
    required this.gradientFractionOnEnd,
    required this.shouldDisposeScrollController,
  })  : assert(gradientFractionOnStart >= 0 && gradientFractionOnStart <= 1),
        assert(gradientFractionOnEnd >= 0 && gradientFractionOnEnd <= 1),
        super(key: key);

  /// Constructor for creating [FadingEdgeScrollView] with [ScrollView] as child
  /// child must have [ScrollView.controller] set
  factory FadingEdgeScrollView.fromScrollView({
    Key? key,
    required ScrollView child,
    double gradientFractionOnStart = 0.1,
    double gradientFractionOnEnd = 0.1,
    bool shouldDisposeScrollController = false,
  }) {
    final controller = child.controller;
    if (controller == null) {
      throw Exception("Child must have controller set");
    }

    return FadingEdgeScrollView._internal(
      key: key,
      scrollController: controller,
      scrollDirection: child.scrollDirection,
      reverse: child.reverse,
      gradientFractionOnStart: gradientFractionOnStart,
      gradientFractionOnEnd: gradientFractionOnEnd,
      shouldDisposeScrollController: shouldDisposeScrollController,
      child: child,
    );
  }

  /// Constructor for creating [FadingEdgeScrollView] with [SingleChildScrollView] as child
  /// child must have [SingleChildScrollView.controller] set
  factory FadingEdgeScrollView.fromSingleChildScrollView({
    Key? key,
    required SingleChildScrollView child,
    double gradientFractionOnStart = 0.1,
    double gradientFractionOnEnd = 0.1,
    bool shouldDisposeScrollController = false,
  }) {
    final controller = child.controller;
    if (controller == null) {
      throw Exception("Child must have controller set");
    }

    return FadingEdgeScrollView._internal(
      key: key,
      scrollController: controller,
      scrollDirection: child.scrollDirection,
      reverse: child.reverse,
      gradientFractionOnStart: gradientFractionOnStart,
      gradientFractionOnEnd: gradientFractionOnEnd,
      shouldDisposeScrollController: shouldDisposeScrollController,
      child: child,
    );
  }

  /// Constructor for creating [FadingEdgeScrollView] with [PageView] as child
  /// child must have [PageView.controller] set
  factory FadingEdgeScrollView.fromPageView({
    Key? key,
    required PageView child,
    double gradientFractionOnStart = 0.1,
    double gradientFractionOnEnd = 0.1,
    bool shouldDisposeScrollController = false,
  }) {
    assert(
      child.controller != null,
      "PageView constructor's controller must be set. \nSee more at: "
      "https://docs.flutter.dev/release/breaking-changes/pageview-controller",
    );
    return FadingEdgeScrollView._internal(
      key: key,
      scrollController: child.controller!,
      scrollDirection: child.scrollDirection,
      reverse: child.reverse,
      gradientFractionOnStart: gradientFractionOnStart,
      gradientFractionOnEnd: gradientFractionOnEnd,
      shouldDisposeScrollController: shouldDisposeScrollController,
      child: child,
    );
  }

  /// Constructor for creating [FadingEdgeScrollView] with [AnimatedList] as child
  /// child must have [AnimatedList.controller] set
  factory FadingEdgeScrollView.fromAnimatedList({
    Key? key,
    required AnimatedList child,
    double gradientFractionOnStart = 0.1,
    double gradientFractionOnEnd = 0.1,
    bool shouldDisposeScrollController = false,
  }) {
    final controller = child.controller;
    if (controller == null) {
      throw Exception("Child must have controller set");
    }

    return FadingEdgeScrollView._internal(
      key: key,
      scrollController: controller,
      scrollDirection: child.scrollDirection,
      reverse: child.reverse,
      gradientFractionOnStart: gradientFractionOnStart,
      gradientFractionOnEnd: gradientFractionOnEnd,
      shouldDisposeScrollController: shouldDisposeScrollController,
      child: child,
    );
  }

  /// Constructor for creating [FadingEdgeScrollView] with [ScrollView] as child
  /// child must have [ScrollView.controller] set
  factory FadingEdgeScrollView.fromListWheelScrollView({
    Key? key,
    required ListWheelScrollView child,
    double gradientFractionOnStart = 0.1,
    double gradientFractionOnEnd = 0.1,
    bool shouldDisposeScrollController = false,
  }) {
    final controller = child.controller;
    if (controller == null) {
      throw Exception("Child must have controller set");
    }

    return FadingEdgeScrollView._internal(
      key: key,
      scrollController: controller,
      scrollDirection: Axis.vertical,
      reverse: false,
      gradientFractionOnStart: gradientFractionOnStart,
      gradientFractionOnEnd: gradientFractionOnEnd,
      shouldDisposeScrollController: shouldDisposeScrollController,
      child: child,
    );
  }

  @override
  // ignore: library_private_types_in_public_api
  _FadingEdgeScrollViewState createState() => _FadingEdgeScrollViewState();
}

class _FadingEdgeScrollViewState extends State<FadingEdgeScrollView>
    with WidgetsBindingObserver {
  late ScrollController _controller;
  bool? _isScrolledToStart;
  bool? _isScrolledToEnd;

  @override
  void initState() {
    super.initState();

    _controller = widget.scrollController;
    _isScrolledToStart = _controller.initialScrollOffset == 0;
    _controller.addListener(_onScroll);

    WidgetsBinding.instance.let((it) {
      it.addPostFrameCallback(_postFrameCallback);
      it.addObserver(this);
    });
  }

  bool get _controllerIsReady =>
      _controller.hasClients && _controller.position.hasContentDimensions;

  void _postFrameCallback(Duration _) {
    if (!mounted) {
      return;
    }

    if (_isScrolledToEnd == null &&
        _controllerIsReady &&
        _controller.position.maxScrollExtent == 0) {
      setState(() {
        _isScrolledToEnd = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    _controller.removeListener(_onScroll);
    if (widget.shouldDisposeScrollController) {
      _controller.dispose();
    }
  }

  void _onScroll() {
    if (!_controllerIsReady) {
      return;
    }
    final offset = _controller.offset;
    final minOffset = _controller.position.minScrollExtent;
    final maxOffset = _controller.position.maxScrollExtent;

    final isScrolledToEnd = offset >= maxOffset;
    final isScrolledToStart = offset <= minOffset;

    if (isScrolledToEnd != _isScrolledToEnd ||
        isScrolledToStart != _isScrolledToStart) {
      setState(() {
        _isScrolledToEnd = isScrolledToEnd;
        _isScrolledToStart = isScrolledToStart;
      });
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    setState(() {
      // Add the shading or remove it when the screen resize (web/desktop) or mobile is rotated
      if (!_controllerIsReady) {
        return;
      }
      final offset = _controller.offset;
      final maxOffset = _controller.position.maxScrollExtent;
      if (maxOffset == 0 && offset == 0) {
        // Not scrollable
        _isScrolledToStart = true;
        _isScrolledToEnd = true;
      } else if (maxOffset == offset) {
        // Scrollable but at end
        _isScrolledToStart = false;
        _isScrolledToEnd = true;
      } else if (maxOffset > 0 && offset == 0) {
        // Scrollable but at start
        _isScrolledToStart = true;
        _isScrolledToEnd = false;
      } else {
        // Scroll in progress/not at either end
        _isScrolledToStart = false;
        _isScrolledToEnd = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isScrolledToStart == null && _controllerIsReady) {
      final offset = _controller.offset;
      final minOffset = _controller.position.minScrollExtent;
      final maxOffset = _controller.position.maxScrollExtent;

      _isScrolledToEnd = offset >= maxOffset;
      _isScrolledToStart = offset <= minOffset;
    }

    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: _gradientStart,
        end: _gradientEnd,
        stops: [
          0,
          widget.gradientFractionOnStart * 0.5,
          1 - widget.gradientFractionOnEnd * 0.5,
          1,
        ],
        colors: _getColors(
          context,
          widget.gradientFractionOnStart > 0 && !(_isScrolledToStart ?? true),
          widget.gradientFractionOnEnd > 0 && !(_isScrolledToEnd ?? false),
        ),
      ).createShader(
        bounds.shift(Offset(-bounds.left, -bounds.top)),
        textDirection: Directionality.of(context),
      ),
      blendMode: BlendMode.dstIn,
      child: widget.child,
    );
  }

  AlignmentGeometry get _gradientStart =>
      widget.scrollDirection == Axis.vertical
          ? _verticalStart
          : _horizontalStart;

  AlignmentGeometry get _gradientEnd =>
      widget.scrollDirection == Axis.vertical ? _verticalEnd : _horizontalEnd;

  Alignment get _verticalStart =>
      widget.reverse ? Alignment.bottomCenter : Alignment.topCenter;

  Alignment get _verticalEnd =>
      widget.reverse ? Alignment.topCenter : Alignment.bottomCenter;

  AlignmentDirectional get _horizontalStart => widget.reverse
      ? AlignmentDirectional.centerEnd
      : AlignmentDirectional.centerStart;

  AlignmentDirectional get _horizontalEnd => widget.reverse
      ? AlignmentDirectional.centerStart
      : AlignmentDirectional.centerEnd;

  List<Color> _getColors(
      BuildContext context, bool isStartEnabled, bool isEndEnabled) {
    final fadeColor = Theme.of(context).scaffoldBackgroundColor;
    return [
      if (isStartEnabled) Colors.transparent else fadeColor,
      fadeColor,
      fadeColor,
      if (isEndEnabled) Colors.transparent else fadeColor,
    ];
  }
}

extension _Let<T> on T {
  U let<U>(U Function(T) block) => block(this);
}
