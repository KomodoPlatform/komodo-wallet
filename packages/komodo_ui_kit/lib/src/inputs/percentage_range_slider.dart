import 'package:flutter/material.dart';
import 'package:komodo_ui/komodo_ui.dart' show Debouncer;
import 'package:komodo_ui_kit/src/inputs/range_slider_labelled.dart';

class PercentageRangeSlider extends StatefulWidget {
  const PercentageRangeSlider({
    super.key,
    required this.values,
    this.title,
    this.min = 0.0,
    this.max = 1.0,
    this.padding = const EdgeInsets.all(0),
    this.divisions,
    this.onChanged,
  });

  final Widget? title;
  final double min;
  final double max;
  final EdgeInsets padding;
  final int? divisions;
  final RangeValues values;
  final Function(RangeValues)? onChanged;

  @override
  State<PercentageRangeSlider> createState() => _PercentageRangeSliderState();
}

class _PercentageRangeSliderState extends State<PercentageRangeSlider> {
  late RangeValues _currentValues;
  late final Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _currentValues = widget.values;
    _debouncer = Debouncer(duration: const Duration(milliseconds: 300));
  }

  @override
  void didUpdateWidget(PercentageRangeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state when widget values change externally
    if (oldWidget.values != widget.values) {
      _currentValues = widget.values;
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  void _handleRangeChanged(RangeValues newValues) {
    setState(() {
      _currentValues = newValues;
    });

    _debouncer.run(() {
      if (mounted && widget.onChanged != null) {
        widget.onChanged!(newValues);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Column(
        children: [
          if (widget.title != null) widget.title!,
          const SizedBox(height: 8),
          RangeSliderLabelled(
            values: _currentValues,
            divisions: widget.divisions,
            min: widget.min,
            max: widget.max,
            onChanged: widget.onChanged != null ? _handleRangeChanged : null,
          ),
        ],
      ),
    );
  }
}
