import 'package:flutter/material.dart';

class TimePeriodSelector extends StatelessWidget {
  final List<Duration> intervals;
  final Duration? selectedPeriod;
  final ValueChanged<Duration?> onPeriodChanged;
  final bool emptySelectionAllowed;

  const TimePeriodSelector({
    Key? key,
    this.intervals = const [
      Duration(hours: 1),
      Duration(days: 1),
      Duration(days: 7),
      Duration(days: 30),
      Duration(days: 365),
    ],
    this.selectedPeriod,
    this.emptySelectionAllowed = false,
    required this.onPeriodChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 160) {
          return TimePeriodSelectorSegmentedButton(
            intervals: intervals,
            selectedPeriod: selectedPeriod,
            onPeriodChanged: onPeriodChanged,
            emptySelectionAllowed: emptySelectionAllowed,
          );
        } else {
          return TimePeriodSelectorDropdownButton(
            intervals: intervals,
            selectedPeriod: selectedPeriod,
            onPeriodChanged: onPeriodChanged,
            emptySelectionAllowed: emptySelectionAllowed,
          );
        }
      },
    );
  }
}

class TimePeriodSelectorDropdownButton extends StatelessWidget {
  final List<Duration> intervals;
  final Duration? selectedPeriod;
  final ValueChanged<Duration?> onPeriodChanged;
  final bool emptySelectionAllowed;

  const TimePeriodSelectorDropdownButton({
    Key? key,
    required this.intervals,
    this.selectedPeriod,
    this.emptySelectionAllowed = false,
    required this.onPeriodChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<Duration>(
        value: selectedPeriod,
        onChanged: emptySelectionAllowed || selectedPeriod != null
            ? onPeriodChanged
            : null,
        underline: const SizedBox.shrink(),
        alignment: Alignment.center,
        icon: const Icon(Icons.keyboard_arrow_down),
        selectedItemBuilder: (context) =>
            intervals.map<Widget>((Duration item) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            margin: const EdgeInsets.fromLTRB(8, 6, 0, 6),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Text(
              selectedPeriod != null ? getDurationCode(selectedPeriod!) : '',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryTextTheme.labelLarge?.color,
                  ),
            ),
          );
        }).toList(),
        items: intervals.map<DropdownMenuItem<Duration>>((Duration value) {
          return DropdownMenuItem<Duration>(
            value: value,
            child: Text(getDurationCode(value)),
          );
        }).toList(),
      ),
    );
  }
}

class TimePeriodSelectorSegmentedButton extends StatelessWidget {
  final List<Duration> intervals;
  final Duration? selectedPeriod;
  final ValueChanged<Duration?> onPeriodChanged;
  final bool emptySelectionAllowed;

  const TimePeriodSelectorSegmentedButton({
    Key? key,
    required this.intervals,
    this.selectedPeriod,
    this.emptySelectionAllowed = false,
    required this.onPeriodChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: SegmentedButton<Duration>(
        style: Theme.of(context).segmentedButtonTheme.style!.copyWith(
              side: WidgetStateProperty.all(BorderSide.none),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
              ),
              backgroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
            ),
        showSelectedIcon: false,
        segments: intervals.map((Duration value) {
          final isSelected = selectedPeriod == value;
          return ButtonSegment<Duration>(
            value: value,
            label: !isSelected
                ? Text(getDurationCode(value))
                : Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(getDurationCode(value)),
                  ),
          );
        }).toList(),
        multiSelectionEnabled: false,
        emptySelectionAllowed: emptySelectionAllowed,
        selected: selectedPeriod != null ? {selectedPeriod!} : {},
        onSelectionChanged: (newSelection) {
          onPeriodChanged(newSelection.singleOrNull);
        },
      ),
    );
  }
}

String getDurationCode(Duration duration) {
  if (duration.inMinutes % 60 == 0 && duration.inHours < 24) {
    final hours = duration.inHours;
    if (hours == 1) return '1H';
    return '${hours}H';
  } else if (duration.inHours % 24 == 0 && duration.inDays < 7) {
    final days = duration.inDays;
    if (days == 1) return '1D';
    return '${days}D';
  } else if (duration.inDays % 7 == 0 && duration.inDays < 30) {
    final weeks = duration.inDays ~/ 7;
    if (weeks == 1) return '1W';
    return '${weeks}W';
  } else if (duration.inDays % 30 == 0 && duration.inDays < 365) {
    final months = duration.inDays ~/ 30;
    if (months == 1) return '1M';
    return '${months}M';
  } else if (duration.inDays % 365 == 0) {
    final years = duration.inDays ~/ 365;
    if (years == 1) return '1Y';
    return '${years}Y';
  }

  throw Exception('Unsupported duration: $duration');
}
