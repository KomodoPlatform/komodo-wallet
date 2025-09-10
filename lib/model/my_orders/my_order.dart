import 'package:rational/rational.dart';

class MyOrder {
  MyOrder({
    required this.base,
    required this.orderType,
    required this.rel,
    required this.relAmount,
    required this.uuid,
    required this.baseAmount,
    required this.createdAt,
    required this.cancelable,
    this.startedSwaps,
    this.baseAmountAvailable,
    this.relAmountAvailable,
    this.minVolume,
  });

  String base;
  Rational baseAmount;
  Rational? baseAmountAvailable;
  String rel;
  TradeSide orderType;
  Rational relAmount;
  Rational? relAmountAvailable;
  String uuid;
  int createdAt;
  bool cancelable;
  double? minVolume;
  List<String>? startedSwaps;
  int get orderMatchingTime {
    final resetTimeInSeconds =
        30 -
        DateTime.now()
            .subtract(Duration(milliseconds: createdAt * 1000))
            .second;

    return resetTimeInSeconds < 0 ? 0 : resetTimeInSeconds;
  }

  double get price => baseAmount.toDouble() / relAmount.toDouble();
}

enum TradeSide { maker, taker }
