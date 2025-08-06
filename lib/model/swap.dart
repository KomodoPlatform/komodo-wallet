import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/my_orders/my_order.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:equatable/equatable.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';

class Swap extends Equatable {
  const Swap({
    required this.type,
    required this.uuid,
    required this.myOrderUuid,
    required this.events,
    required this.makerAmount,
    required this.makerCoin,
    required this.takerAmount,
    required this.takerCoin,
    required this.gui,
    required this.mmVersion,
    required this.successEvents,
    required this.errorEvents,
    this.myInfo,
    required this.recoverable,
  });

  factory Swap.fromJson(JsonMap json) {
    final Rational makerAmount =
        fract2rat(json.valueOrNull<JsonMap>('maker_amount_fraction')) ??
        Rational.parse(json.valueOrNull<String>('maker_amount') ?? '0');
    final Rational takerAmount =
        fract2rat(json.valueOrNull<JsonMap>('taker_amount_fraction')) ??
        Rational.parse(json.valueOrNull<String>('taker_amount') ?? '0');
    final TradeSide type = json.value<String>('type') == 'Taker'
        ? TradeSide.taker
        : TradeSide.maker;
    return Swap(
      type: type,
      uuid: json.valueOrNull<String>('uuid') ?? '',
      myOrderUuid: json.valueOrNull<String>('my_order_uuid') ?? '',
      events: json
          .value<List<JsonMap>>('events')
          .map((e) => SwapEventItem.fromJson(e))
          .toList(),
      makerAmount: makerAmount,
      makerCoin: json.valueOrNull<String>('maker_coin') ?? '',
      takerAmount: takerAmount,
      takerCoin: json.valueOrNull<String>('taker_coin') ?? '',
      gui: json.valueOrNull<String>('gui') ?? '',
      mmVersion: json.valueOrNull<String>('mm_version') ?? '',
      successEvents: json.value<List<String>>('success_events'),
      errorEvents: json.value<List<String>>('error_events'),
      myInfo: json.valueOrNull<JsonMap>('my_info') != null
          ? SwapMyInfo.fromJson(json.value<JsonMap>('my_info'))
          : null,
      recoverable: json.value<bool>('recoverable'),
    );
  }

  final TradeSide type;
  final String uuid;
  final String myOrderUuid;
  final List<SwapEventItem> events;
  final Rational makerAmount;
  final String makerCoin;
  final Rational takerAmount;
  final String takerCoin;
  final String gui;
  final String mmVersion;
  final List<String> successEvents;
  final List<String> errorEvents;
  final SwapMyInfo? myInfo;
  final bool recoverable;

  JsonMap toJson() {
    final data = <String, dynamic>{};

    data['type'] = type;
    data['uuid'] = uuid;
    data['my_order_uuid'] = myOrderUuid;
    data['events'] = events.map((e) => e.toJson()).toList();
    data['maker_amount'] = makerAmount.toDouble().toString();
    data['maker_amount_fraction'] = rat2fract(makerAmount);
    data['maker_coin'] = makerCoin;
    data['taker_amount'] = takerAmount.toDouble().toString();
    data['taker_amount_fraction'] = rat2fract(takerAmount);
    data['taker_coin'] = takerCoin;
    data['gui'] = gui;
    data['mm_version'] = mmVersion;
    data['success_events'] = successEvents;
    data['error_events'] = errorEvents;
    data['my_info'] = myInfo?.toJson();
    data['recoverable'] = recoverable;

    return data;
  }

  bool get isCompleted => events.any(
    (e) =>
        e.event.type == successEvents.last ||
        errorEvents.contains(e.event.type),
  );

  bool get isFailed {
    for (final event in events) {
      if (errorEvents.contains(event.event.type)) {
        return true;
      }
    }
    return false;
  }

  bool get isSuccessful => isCompleted && !isFailed;
  SwapStatus get status {
    bool started = false, negotiated = false;
    for (SwapEventItem ev in events) {
      if (errorEvents.contains(ev.event.type)) return SwapStatus.failed;
      if (ev.event.type == 'Finished') return SwapStatus.successful;
      if (ev.event.type == 'Started') started = true;
      if (ev.event.type == 'Negotiated') negotiated = true;
    }
    if (negotiated) return SwapStatus.ongoing;
    if (started) return SwapStatus.matched;
    return SwapStatus.matching;
  }

  bool get isTaker => type == TradeSide.taker;

  String get sellCoin => isTaker ? takerCoin : makerCoin;

  Rational get sellAmount => isTaker ? takerAmount : makerAmount;

  String get buyCoin => isTaker ? makerCoin : takerCoin;

  Rational get buyAmount => isTaker ? makerAmount : takerAmount;

  bool get isTheSameTicker => abbr2Ticker(takerCoin) == abbr2Ticker(makerCoin);

  static int get statusSteps => 3;

  int get statusStep {
    switch (status) {
      case SwapStatus.matching:
        return 0;
      case SwapStatus.matched:
        return 1;
      case SwapStatus.ongoing:
        return 2;
      case SwapStatus.successful:
      case SwapStatus.failed:
        return 0;
      case SwapStatus.negotiated:
        return 0;
    }
  }

  static String getSwapStatusString(SwapStatus status) {
    switch (status) {
      case SwapStatus.matching:
        return LocaleKeys.matching.tr();
      case SwapStatus.matched:
        return LocaleKeys.matched.tr();
      case SwapStatus.ongoing:
        return LocaleKeys.ongoing.tr();
      case SwapStatus.successful:
        return LocaleKeys.successful.tr();
      case SwapStatus.failed:
        return LocaleKeys.failed.tr();
      default:
        return '';
    }
  }

  @override
  List<Object?> get props => [
    type,
    uuid,
    myOrderUuid,
    events,
    makerAmount,
    makerCoin,
    takerAmount,
    takerCoin,
    gui,
    mmVersion,
    successEvents,
    errorEvents,
    myInfo,
    recoverable,
  ];
}

class SwapEventItem extends Equatable {
  const SwapEventItem({required this.timestamp, required this.event});
  factory SwapEventItem.fromJson(JsonMap json) => SwapEventItem(
    timestamp: json.value<int>('timestamp'),
    event: SwapEvent.fromJson(json.value<JsonMap>('event')),
  );
  final int timestamp;
  final SwapEvent event;

  String get eventDateTime => DateFormat(
    'd MMMM y, H:m',
  ).format(DateTime.fromMillisecondsSinceEpoch(timestamp));

  JsonMap toJson() {
    final data = <String, dynamic>{};
    data['timestamp'] = timestamp;
    data['event'] = event.toJson();
    return data;
  }

  @override
  List<Object> get props => [timestamp, event];
}

class SwapEvent extends Equatable {
  const SwapEvent({required this.type, required this.data});

  factory SwapEvent.fromJson(JsonMap json) {
    return SwapEvent(
      type: json.valueOrNull<String>('type') ?? '',
      data:
          (json.valueOrNull<JsonMap>('data') != null &&
              json.valueOrNull<String>('type') != "WatcherMessageSent")
          ? SwapEventData.fromJson(json.value<JsonMap>('data'))
          : null,
    );
  }

  final String type;
  final SwapEventData? data;

  JsonMap toJson() {
    final data = <String, dynamic>{};
    data['type'] = type;
    data['data'] = this.data?.toJson();
    return data;
  }

  @override
  List<Object?> get props => [type, data];
}

class SwapEventData extends Equatable {
  const SwapEventData({
    required this.takerCoin,
    required this.makerCoin,
    required this.maker,
    required this.myPersistentPub,
    required this.lockDuration,
    required this.makerAmount,
    required this.takerAmount,
    required this.makerPaymentConfirmations,
    required this.makerPaymentRequiresNota,
    required this.takerPaymentConfirmations,
    required this.takerPaymentRequiresNota,
    required this.takerPaymentLock,
    required this.uuid,
    required this.startedAt,
    required this.makerPaymentWait,
    required this.makerCoinStartBlock,
    required this.takerCoinStartBlock,
    required this.feeToSendTakerFee,
    required this.takerPaymentTradeFee,
    required this.makerPaymentSpendTradeFee,
    required this.txHash,
  });

  factory SwapEventData.fromJson(JsonMap json) => SwapEventData(
    takerCoin: json.valueOrNull<String>('taker_coin'),
    makerCoin: json.valueOrNull<String>('maker_coin'),
    maker: json.valueOrNull<String>('maker'),
    myPersistentPub: json.valueOrNull<String>('my_persistent_pub'),
    lockDuration: json.valueOrNull<int>('lock_duration'),
    makerAmount: json.valueOrNull<double>('maker_amount'),
    takerAmount: json.valueOrNull<double>('taker_amount'),
    makerPaymentConfirmations: json.valueOrNull<int>(
      'maker_payment_confirmations',
    ),
    makerPaymentRequiresNota: json.valueOrNull<bool>(
      'maker_payment_requires_nota',
    ),
    takerPaymentConfirmations: json.valueOrNull<int>(
      'taker_payment_confirmations',
    ),
    takerPaymentRequiresNota: json.valueOrNull<bool>(
      'taker_payment_requires_nota',
    ),
    takerPaymentLock: json.valueOrNull<int>('taker_payment_lock'),
    uuid: json.valueOrNull<String>('uuid'),
    startedAt: json.valueOrNull<int>('started_at'),
    makerPaymentWait: json.valueOrNull<int>('maker_payment_wait'),
    makerCoinStartBlock: json.valueOrNull<int>('maker_coin_start_block'),
    takerCoinStartBlock: json.valueOrNull<int>('taker_coin_start_block'),
    feeToSendTakerFee:
        json.valueOrNull<JsonMap>('fee_to_send_taker_fee') != null
        ? TradeFee.fromJson(json.value<JsonMap>('fee_to_send_taker_fee'))
        : null,
    takerPaymentTradeFee:
        json.valueOrNull<JsonMap>('taker_payment_trade_fee') != null
        ? TradeFee.fromJson(json.value<JsonMap>('taker_payment_trade_fee'))
        : null,
    makerPaymentSpendTradeFee:
        json.valueOrNull<JsonMap>('maker_payment_spend_trade_fee') != null
        ? TradeFee.fromJson(
            json.value<JsonMap>('maker_payment_spend_trade_fee'),
          )
        : null,
    txHash:
        json.valueOrNull<String>('tx_hash') ??
        json.valueOrNull<String>('transaction', 'tx_hash'),
  );

  final String? takerCoin;
  final String? makerCoin;
  final String? maker;
  final String? myPersistentPub;
  final int? lockDuration;
  final double? makerAmount;
  final double? takerAmount;
  final int? makerPaymentConfirmations;
  final bool? makerPaymentRequiresNota;
  final int? takerPaymentConfirmations;
  final bool? takerPaymentRequiresNota;
  final int? takerPaymentLock;
  final String? uuid;
  final int? startedAt;
  final int? makerPaymentWait;
  final int? makerCoinStartBlock;
  final int? takerCoinStartBlock;
  final TradeFee? feeToSendTakerFee;
  final TradeFee? takerPaymentTradeFee;
  final TradeFee? makerPaymentSpendTradeFee;
  final String? txHash;

  JsonMap toJson() {
    final data = <String, dynamic>{};
    data['taker_coin'] = takerCoin;
    data['maker_coin'] = makerCoin;
    data['maker'] = maker;
    data['my_persistent_pub'] = myPersistentPub;
    data['lock_duration'] = lockDuration;
    data['maker_amount'] = makerAmount;
    data['taker_amount'] = takerAmount;
    data['maker_payment_confirmations'] = makerPaymentConfirmations;
    data['maker_payment_requires_nota'] = makerPaymentRequiresNota;
    data['taker_payment_confirmations'] = takerPaymentConfirmations;
    data['taker_payment_requires_nota'] = takerPaymentRequiresNota;
    data['taker_payment_lock'] = takerPaymentLock;
    data['uuid'] = uuid;
    data['started_at'] = startedAt;
    data['maker_payment_wait'] = makerPaymentWait;
    data['maker_coin_start_block'] = makerCoinStartBlock;
    data['taker_coin_start_block'] = takerCoinStartBlock;
    data['fee_to_send_taker_fee'] = feeToSendTakerFee?.toJson();
    data['taker_payment_trade_fee'] = takerPaymentTradeFee?.toJson();
    data['maker_payment_spend_trade_fee'] = makerPaymentSpendTradeFee?.toJson();
    return data;
  }

  @override
  List<Object?> get props => [
    takerCoin,
    makerCoin,
    maker,
    myPersistentPub,
    lockDuration,
    makerAmount,
    takerAmount,
    makerPaymentConfirmations,
    makerPaymentRequiresNota,
    takerPaymentConfirmations,
    takerPaymentRequiresNota,
    takerPaymentLock,
    uuid,
    startedAt,
    makerPaymentWait,
    makerCoinStartBlock,
    takerCoinStartBlock,
    feeToSendTakerFee,
    takerPaymentTradeFee,
    makerPaymentSpendTradeFee,
    txHash,
  ];
}

enum SwapStatus { successful, negotiated, ongoing, matched, matching, failed }

class TradeFee extends Equatable {
  const TradeFee({
    required this.coin,
    required this.amount,
    required this.paidFromTradingVol,
  });

  factory TradeFee.fromJson(JsonMap json) {
    return TradeFee(
      coin: json.valueOrNull<String>('coin') ?? '',
      amount: json.valueOrNull<double>('amount'),
      paidFromTradingVol: json.value<bool>('paid_from_trading_vol'),
    );
  }

  final String coin;
  final double? amount;
  final bool paidFromTradingVol;

  JsonMap toJson() {
    final data = <String, dynamic>{};
    data['coin'] = coin;
    data['amount'] = amount;
    data['paid_from_trading_vol'] = paidFromTradingVol;
    return data;
  }

  @override
  List<Object?> get props => [coin, amount, paidFromTradingVol];
}

class SwapMyInfo extends Equatable {
  const SwapMyInfo({
    required this.myCoin,
    required this.otherCoin,
    required this.myAmount,
    required this.otherAmount,
    required this.startedAt,
  });

  factory SwapMyInfo.fromJson(JsonMap json) {
    return SwapMyInfo(
      myCoin: json.valueOrNull<String>('my_coin') ?? '',
      otherCoin: json.valueOrNull<String>('other_coin') ?? '',
      myAmount: json.value<double>('my_amount'),
      otherAmount: json.value<double>('other_amount'),
      startedAt: json.value<int>('started_at'),
    );
  }

  final String myCoin;
  final String otherCoin;
  final double myAmount;
  final double otherAmount;
  final int startedAt;

  JsonMap toJson() {
    final data = <String, dynamic>{};
    data['my_coin'] = myCoin;
    data['other_coin'] = otherCoin;
    data['my_amount'] = myAmount;
    data['other_amount'] = otherAmount;
    data['started_at'] = startedAt;
    return data;
  }

  @override
  List<Object?> get props => [
    myCoin,
    otherCoin,
    myAmount,
    otherAmount,
    startedAt,
  ];
}
