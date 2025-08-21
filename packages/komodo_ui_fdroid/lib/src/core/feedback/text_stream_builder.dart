import 'dart:async';

import 'package:flutter/material.dart';

/// A widget that displays text from a stream with proper loading and error
/// states.
///
/// This widget is designed to be used with any data stream by providing
/// a [stream] that emits updates and a [formatData] function to convert
/// the data to a displayable string.
class TextStreamBuilder<T> extends StatefulWidget {
  /// Creates a TextStreamBuilder widget
  const TextStreamBuilder({
    required this.stream,
    required this.formatData,
    super.key,
    this.style,
    this.loadingWidget,
    this.errorBuilder,
  });

  /// Stream that provides data updates
  final Stream<T> stream;

  /// Function to format the data into a displayable string
  ///
  /// Will be null while loading if [loadingWidget] is not provided
  final String Function(T? data) formatData;

  /// The text style to apply to the displayed text
  final TextStyle? style;

  /// Widget to display while loading the data.
  ///
  /// If not provided, the [formatData] function will be called with null
  final Widget? loadingWidget;

  /// Builder for displaying errors
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  State<TextStreamBuilder<T>> createState() => _TextStreamBuilderState<T>();
}

class _TextStreamBuilderState<T> extends State<TextStreamBuilder<T>> {
  late final StreamSubscription<T> _subscription;
  T? _lastData;
  Object? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _subscribeToDataStream();
  }

  void _subscribeToDataStream() {
    _subscription = widget.stream.listen(
      (data) {
        if (mounted) {
          setState(() {
            _lastData = data;
            _isLoading = false;
            _error = null;
          });
        }
      },
      onError: (Object error) {
        if (mounted) {
          setState(() {
            _error = error;
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && widget.loadingWidget != null) {
      return widget.loadingWidget!;
    }

    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!) ??
          Text('Error', style: widget.style?.copyWith(color: Colors.red));
    }

    return Text(widget.formatData(_lastData), style: widget.style);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
