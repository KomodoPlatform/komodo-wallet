import 'package:flutter/material.dart';

class ErrorDisplay extends StatefulWidget {
  const ErrorDisplay({
    required this.message,
    this.icon,
    this.isWarning = false,
    this.child,
    this.actionLabel,
    this.onActionPressed,
    this.detailedMessage,
    this.showDetails = false,
    this.showIcon = true,
    this.narrowBreakpoint = 500,
    super.key,
  });

  /// The main error or warning message to display.
  final String message;

  /// An optional detailed message to show when the user opts to see more
  /// details.
  final String? detailedMessage;

  /// An optional icon to display alongside the message.
  /// If not provided, a default icon will be used based on the type of message.
  final IconData? icon;

  /// Whether this is a warning (true) or an error (false).
  final bool isWarning;

  /// An optional child widget to display below the main message.
  final Widget? child;

  /// An optional label for an action button.
  final String? actionLabel;

  /// An optional callback for when the action button is pressed.
  final VoidCallback? onActionPressed;

  /// Whether to show the detailed message by default or not.
  final bool showDetails;

  /// Whether to show the icon next to the message.
  final bool showIcon;

  /// The breakpoint width below which the layout will change to a more
  /// compact form.
  final int narrowBreakpoint;

  @override
  State<ErrorDisplay> createState() => _ErrorDisplayState();
}

class _ErrorDisplayState extends State<ErrorDisplay> {
  bool showDetailedMessage = false;

  /// Shows the detailed error message if the override is true, or if the user
  /// has toggled the detailed message to be shown.
  bool get shouldShowDetailedMessage =>
      widget.detailedMessage != null &&
      (widget.showDetails || showDetailedMessage);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine color based on whether this is a warning or error
    final color =
        widget.isWarning ? theme.colorScheme.tertiary : theme.colorScheme.error;

    // Determine background and container design
    final backgroundColor =
        widget.isWarning
            ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.7)
            : theme.colorScheme.errorContainer.withValues(alpha: 0.7);

    return Card(
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < widget.narrowBreakpoint;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.showIcon) ...[
                      Icon(
                        widget.icon ??
                            (widget.isWarning
                                ? Icons.warning_amber_rounded
                                : Icons.error_outline),
                        color: color,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: _ErrorDisplayMessageSection(
                        message: widget.message,
                        isWarning: widget.isWarning,
                        isNarrow: isNarrow,
                        color: color,
                        detailedMessage: widget.detailedMessage,
                        shouldShowDetailedMessage: shouldShowDetailedMessage,
                        showDetailsButton: _ErrorDisplayShowDetailsButton(
                          color: color,
                          shouldShowDetailedMessage: shouldShowDetailedMessage,
                          showDetailsOverride: widget.showDetails,
                          onToggle:
                              widget.detailedMessage == null
                                  ? null
                                  : () {
                                    setState(() {
                                      showDetailedMessage =
                                          !showDetailedMessage;
                                    });
                                  },
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.child != null) ...[
                  const SizedBox(height: 16),
                  widget.child!,
                ],
                const SizedBox(height: 16),
                _ErrorDisplayActions(
                  color: color,
                  isWarning: widget.isWarning,
                  actionLabel: widget.actionLabel,
                  onActionPressed: widget.onActionPressed,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ErrorDisplayMessageSection extends StatelessWidget {
  const _ErrorDisplayMessageSection({
    required this.message,
    required this.isWarning,
    required this.isNarrow,
    required this.color,
    required this.shouldShowDetailedMessage,
    this.detailedMessage,
    this.showDetailsButton,
  });

  final String message;
  final bool isWarning;
  final bool isNarrow;
  final Color color;
  final String? detailedMessage;
  final bool shouldShowDetailedMessage;
  final Widget? showDetailsButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isNarrow)
          Text(
            message,
            style: theme.textTheme.titleSmall?.copyWith(
              color:
                  isWarning
                      ? theme.colorScheme.onTertiaryContainer
                      : theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color:
                        isWarning
                            ? theme.colorScheme.onTertiaryContainer
                            : theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (showDetailsButton != null) showDetailsButton!,
            ],
          ),
        if (isNarrow && showDetailsButton != null)
          Align(child: showDetailsButton),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child:
              shouldShowDetailedMessage
                  ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SelectableText(
                      detailedMessage ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            isWarning
                                ? theme.colorScheme.onTertiaryContainer
                                    .withValues(alpha: 0.8)
                                : theme.colorScheme.onErrorContainer.withValues(
                                  alpha: 0.8,
                                ),
                      ),
                    ),
                  )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ErrorDisplayActions extends StatelessWidget {
  const _ErrorDisplayActions({
    required this.color,
    required this.isWarning,
    this.actionLabel,
    this.onActionPressed,
  });

  final Color color;
  final bool isWarning;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (actionLabel != null && onActionPressed != null)
          ElevatedButton(
            onPressed: onActionPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor:
                  isWarning
                      ? theme.colorScheme.onTertiary
                      : theme.colorScheme.onError,
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _ErrorDisplayShowDetailsButton extends StatelessWidget {
  const _ErrorDisplayShowDetailsButton({
    required this.color,
    required this.shouldShowDetailedMessage,
    required this.showDetailsOverride,
    required this.onToggle,
  });

  final Color color;
  final bool shouldShowDetailedMessage;
  final bool showDetailsOverride;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    if (onToggle == null) {
      // If no toggle function is provided, don't show the button
      return const SizedBox.shrink();
    }

    return TextButton(
      onPressed: showDetailsOverride ? null : onToggle,
      child: Text(
        shouldShowDetailedMessage ? 'Hide Details' : 'Show Details',
        style: TextStyle(color: color),
      ),
    );
  }
}
