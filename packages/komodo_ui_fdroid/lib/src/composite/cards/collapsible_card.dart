import 'package:flutter/material.dart';

/// Controls how the expansion control behaves when there are no children.
enum EmptyChildrenBehavior {
  /// Shows the expansion control in a disabled state
  disable,

  /// Completely hides the expansion control
  hide,
}

/// Controls the position of the expansion control button.
enum ExpansionControlPosition {
  /// Places the expansion control at the start of the header
  leading,

  /// Places the expansion control at the end of the header
  trailing,
}

/// A card component that can expand and collapse to show additional content.
///
/// The [CollapsibleCard] provides a flexible container that can be expanded
/// to reveal more content. It supports customization of its appearance and
/// behavior through various properties.
///
/// ```dart
/// CollapsibleCard(
///   title: Text('Card Title'),
///   subtitle: Text('Optional subtitle'),
///   leading: Icon(Icons.star),
///   children: [
///     ListTile(title: Text('Content item 1')),
///     ListTile(title: Text('Content item 2')),
///   ],
/// )
/// ```
///
/// See also:
///
///  * [Card], which this component builds upon
///  * [ExpansionPanel], which provides similar functionality in a different style
class CollapsibleCard extends StatefulWidget {
  const CollapsibleCard({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
    this.children,
    this.backgroundColor,
    this.expandedBackgroundColor,
    this.borderRadius,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.animationDuration = const Duration(milliseconds: 200),
    this.headerPadding = const EdgeInsets.all(16),
    this.childrenMargin = EdgeInsets.zero,
    this.maintainState = false,
    this.divider,
    this.semanticsLabel,
    this.expansionControlPosition = ExpansionControlPosition.trailing,
    this.emptyChildrenBehavior = EmptyChildrenBehavior.disable,
    this.isDense = false,
    this.onTap,
    this.childrenDecoration,
    this.childrenDivider,
  });

  /// The primary content of the card header.
  final Widget title;

  /// Optional widget to display below the title.
  final Widget? subtitle;

  /// Leading widget, typically an icon or image.
  final Widget? leading;

  /// Optional widget displayed at the end of the card header.
  final Widget? trailing;

  /// The content that appears when the card is expanded.
  ///
  /// If null or empty, the expansion control will be disabled.
  final List<Widget>? children;

  /// Background color of the card.
  ///
  /// If null, [CardTheme.color] is used.
  final Color? backgroundColor;

  /// Color when the card is expanded.
  ///
  /// If null, [backgroundColor] is used.
  final Color? expandedBackgroundColor;

  /// Border radius of the card.
  ///
  /// If null, [CardTheme.shape] border radius is used.
  final BorderRadius? borderRadius;

  /// Whether the card is initially expanded.
  final bool initiallyExpanded;

  /// Called when the card expands or collapses.
  final ValueChanged<bool>? onExpansionChanged;

  /// Called when the header is tapped.
  ///
  /// This is different from [onExpansionChanged] which is called when the
  /// expansion state changes via the expansion control button.
  final VoidCallback? onTap;

  /// Duration of the expand/collapse animation.
  final Duration animationDuration;

  /// Padding around the header content.
  final EdgeInsetsGeometry headerPadding;

  /// Padding around the expanded content.
  final EdgeInsetsGeometry childrenMargin;

  /// Whether to maintain the children's state when collapsed.
  final bool maintainState;

  /// Custom divider widget between header and children.
  final Widget? divider;

  /// Semantics label for accessibility.
  final String? semanticsLabel;

  /// Controls whether the expansion button appears at the start or end of the header.
  final ExpansionControlPosition expansionControlPosition;

  /// Whether to render the card with dense padding and smaller elements.
  final bool isDense;

  /// Controls whether to hide or disable the expansion control when there are no children.
  ///
  /// Defaults to [EmptyChildrenBehavior.disable] to maintain consistent layout.
  final EmptyChildrenBehavior emptyChildrenBehavior;

  /// Decoration for the children container.
  final BoxDecoration? childrenDecoration;

  /// Divider widget between children.
  final Widget? childrenDivider;

  bool get _hasChildren => children?.isNotEmpty ?? false;
  bool get _showExpansionControl =>
      emptyChildrenBehavior == EmptyChildrenBehavior.disable || _hasChildren;

  @override
  State<CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<CollapsibleCard>
    with SingleTickerProviderStateMixin {
  static final Animatable<double> _easeInTween = CurveTween(
    curve: Curves.easeIn,
  );

  late AnimationController _controller;
  late Animation<double> _heightFactor;
  late Animation<double> _iconTurns;
  late Animation<Color?> _backgroundColor;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _heightFactor = _controller.drive(_easeInTween);
    _iconTurns = _controller.drive(
      Tween<double>(begin: 0, end: 0.5).chain(_easeInTween),
    );
    _backgroundColor = _controller.drive(
      ColorTween(
        begin: widget.backgroundColor,
        end: widget.expandedBackgroundColor,
      ).chain(_easeInTween),
    );

    _isExpanded =
        PageStorage.maybeOf(context)?.readState(context) as bool? ??
        widget.initiallyExpanded;
    if (_isExpanded) _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleExpansionToggle() {
    if (!widget._hasChildren) return;

    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse().then<void>((void value) {
          if (!mounted) return;
          setState(() {});
        });
      }
      PageStorage.maybeOf(context)?.writeState(context, _isExpanded);
    });
    widget.onExpansionChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final closed = !_isExpanded && _controller.isDismissed;
    final shouldRemoveChildren = closed && !widget.maintainState;

    final Widget result = Offstage(
      offstage: closed,
      child: TickerMode(
        enabled: !closed,
        child: Container(
          margin: widget.childrenMargin,
          decoration: widget.childrenDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _generateDividedChildWidgets(),
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _controller.view,
      builder: _buildChildren,
      child: shouldRemoveChildren ? null : result,
    );
  }

  List<Widget> _generateDividedChildWidgets() {
    if (widget.children == null || widget.children!.isEmpty) {
      return [];
    }

    final children = <Widget>[];
    for (var i = 0; i < widget.children!.length; i++) {
      children.add(widget.children![i]);
      if (i < widget.children!.length - 1 && widget.childrenDivider != null) {
        children.add(widget.childrenDivider!);
      }
    }
    return children;
  }

  Widget _buildExpansionControl(BuildContext context) {
    final theme = Theme.of(context);
    final iconTheme = IconTheme.of(context);
    final hasChildren = widget._hasChildren;

    return IconButton(
      visualDensity: widget.isDense ? VisualDensity.compact : null,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: hasChildren ? _handleExpansionToggle : null,
      iconSize: widget.isDense ? 24 : 28,
      icon: RotationTransition(
        turns: _iconTurns,
        child: Icon(
          Icons.expand_more,
          color:
              hasChildren
                  ? (iconTheme.color ?? theme.colorScheme.onSurface)
                  : theme.colorScheme.onSurface.withOpacity(0.38),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final spacing = widget.isDense ? 8.0 : 16.0;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: widget.borderRadius,
        child: Padding(
          padding: widget.headerPadding,
          child: Row(
            children: [
              if (widget.expansionControlPosition ==
                      ExpansionControlPosition.leading &&
                  widget._showExpansionControl) ...[
                _buildExpansionControl(context),
                SizedBox(width: spacing),
              ],
              if (widget.leading != null) ...[
                widget.leading!,
                SizedBox(width: spacing),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.title,
                    if (widget.subtitle != null) ...[
                      SizedBox(height: widget.isDense ? 2 : 4),
                      widget.subtitle!,
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                SizedBox(width: spacing),
                widget.trailing!,
              ],
              if (widget.expansionControlPosition ==
                      ExpansionControlPosition.trailing &&
                  widget._showExpansionControl) ...[
                SizedBox(width: spacing),
                _buildExpansionControl(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildren(BuildContext context, Widget? child) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color:
            _backgroundColor.value ??
            theme.cardTheme.color ??
            theme.colorScheme.surface,
        borderRadius: widget.borderRadius,
        // ?? theme.cardTheme.shape?.borderRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          if (widget.divider != null && _isExpanded) widget.divider!,
          if (child != null)
            ClipRect(
              child: Align(heightFactor: _heightFactor.value, child: child),
            ),
        ],
      ),
    );
  }
}
