import 'dart:async';

import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class TradingDetailsTotalTime extends StatefulWidget {
  const TradingDetailsTotalTime(
      {Key? key, required this.startedTime, this.finishedTime})
      : super(key: key);

  final int startedTime;
  final int? finishedTime;

  @override
  State<TradingDetailsTotalTime> createState() =>
      _TradingDetailsTotalTimeState();
}

class _TradingDetailsTotalTimeState extends State<TradingDetailsTotalTime> {
  late Timer timer;
  int currentTime = DateTime.now().millisecondsSinceEpoch;

  @override
  Widget build(BuildContext context) {
    return SelectableText(_totalSpentTime());
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
    super.initState();
  }

  String _totalSpentTime() {
    final int? finishedTime = widget.finishedTime;
    final int timeSpent = finishedTime != null
        ? finishedTime - widget.startedTime
        : currentTime - widget.startedTime;
    final DateTime date =
        DateTime.fromMillisecondsSinceEpoch(timeSpent, isUtc: true);
    if (date.hour == 0) {
      return LocaleKeys.tradingDetailsTotalSpentTime
          .tr(args: [date.minute.toString(), date.second.toString()]);
    }
    return LocaleKeys.tradingDetailsTotalSpentTimeWithHours.tr(args: [
      date.hour.toString(),
      date.minute.toString(),
      date.second.toString()
    ]);
  }

  void _updateTime() {
    setState(() {
      currentTime = DateTime.now().millisecondsSinceEpoch;
    });
  }
}
