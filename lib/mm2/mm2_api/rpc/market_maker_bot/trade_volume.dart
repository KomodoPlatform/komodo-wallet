import 'package:equatable/equatable.dart';
import 'package:web_dex/views/market_maker_bot/trade_volume_type.dart';

/// The trade volume for the market maker bot.
class TradeVolume extends Equatable {
  const TradeVolume({this.type = TradeVolumeType.usd, required this.value});

  /// Creates a trade volume with the [type] set to [TradeVolumeType.percentage]
  /// with the given [value].
  factory TradeVolume.percentage(double value) =>
      TradeVolume(type: TradeVolumeType.percentage, value: value);

  /// The value of the trade volume limit.
  final double value;

  /// The type of the trade volume limit. E.g. percentage or usd.
  final TradeVolumeType type;

  factory TradeVolume.fromJson(Map<String, dynamic> json) {
    final percentage = double.tryParse(json['percentage'] as String? ?? '');
    final usd = double.tryParse(json['usd'] as String? ?? '');

    if (percentage != null && usd != null) {
      throw ArgumentError(
        'TradeVolumeLimit cannot have both percentage and usd',
      );
    }

    return TradeVolume(
      type: percentage != null
          ? TradeVolumeType.percentage
          : TradeVolumeType.usd,
      // null check is done above, so value is not null
      value: (percentage ?? usd)!,
    );
  }

  Map<String, dynamic> toJson() => {
    'percentage': type == TradeVolumeType.percentage ? value.toString() : null,
    'usd': type == TradeVolumeType.usd ? value.toString() : null,
  }..removeWhere((_, value) => value == null);

  TradeVolume copyWith({double? value, TradeVolumeType? type}) {
    return TradeVolume(value: value ?? this.value, type: type ?? this.type);
  }

  @override
  List<Object?> get props => [value, type];
}
