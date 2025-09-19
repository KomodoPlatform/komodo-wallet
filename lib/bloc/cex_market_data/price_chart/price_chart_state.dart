import 'package:equatable/equatable.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/cex_market_data/price_chart/models/price_chart_data.dart';

enum PriceChartStatus { initial, loading, success, failure }

final class PriceChartState extends Equatable {
  final PriceChartStatus status;
  final List<PriceChartDataSeries> data;
  final String? error;

  final Map<AssetId, CoinPriceInfo> availableCoins;

  //!
  final Duration selectedPeriod;

  bool get hasData => data.isNotEmpty;

  const PriceChartState({
    this.status = PriceChartStatus.initial,
    this.data = const [],
    this.availableCoins = const {},
    this.error,
    this.selectedPeriod = const Duration(days: 1),
  });

  PriceChartState copyWith({
    PriceChartStatus? status,
    List<PriceChartDataSeries>? data,
    String? error,
    Duration? selectedPeriod,
    Map<AssetId, CoinPriceInfo>? availableCoins,
  }) {
    return PriceChartState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      availableCoins: availableCoins ?? this.availableCoins,
    );
  }

  @override
  List<Object?> get props => [
        status,
        data,
        error,
        selectedPeriod,
        availableCoins,
      ];
}
