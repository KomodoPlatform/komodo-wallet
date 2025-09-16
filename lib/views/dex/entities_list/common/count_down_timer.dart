import 'dart:async';
import 'package:flutter/material.dart';

class CountDownTimer extends StatefulWidget {
  const CountDownTimer({Key? key, required this.orderMatchingTime})
      : super(key: key);
  final int orderMatchingTime;

  @override
  State<CountDownTimer> createState() => _CountDownTimerState();
}

class _CountDownTimerState extends State<CountDownTimer> {
  late Timer _timer;
  late int _currentTimerValue;
  final _maxValue = 30;

  @override
  void initState() {
    _currentTimerValue = widget.orderMatchingTime;
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_currentTimerValue == 0) {
        _timer.cancel();
        return;
      }
      if (mounted) {
        setState(() {
          _currentTimerValue--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return SizedBox(
        width: 25,
        height: 25,
        child: Stack(
          children: [
            Positioned.fill(
                child: CircularProgressIndicator(
              value: _currentTimerValue / _maxValue,
              backgroundColor: themeData.hintColor,
              strokeWidth: 2,
            )),
            Align(
                alignment: FractionalOffset.center,
                child: Text(
                  _currentTimerValue.toString(),
                  style: themeData.textTheme.bodyMedium!.copyWith(fontSize: 12),
                ))
          ],
        ));
  }
}
