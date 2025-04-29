class CoinMarketChart {
  CoinMarketChart({
    required this.prices,
    required this.marketCaps,
    required this.totalVolumes,
  });

  factory CoinMarketChart.fromJson(Map<String, dynamic> json) {
    return CoinMarketChart(
      prices: (json['prices'] as List<dynamic>)
          .map(
            (dynamic e) =>
                (e as List<dynamic>).map((dynamic e) => e as num).toList(),
          )
          .toList(),
      marketCaps: (json['market_caps'] as List<dynamic>)
          .map(
            (dynamic e) =>
                (e as List<dynamic>).map((dynamic e) => e as num).toList(),
          )
          .toList(),
      totalVolumes: (json['total_volumes'] as List<dynamic>)
          .map(
            (dynamic e) =>
                (e as List<dynamic>).map((dynamic e) => e as num).toList(),
          )
          .toList(),
    );
  }

  final List<List<num>> prices;
  final List<List<num>> marketCaps;
  final List<List<num>> totalVolumes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'prices':
          prices.map((List<num> e) => e.map((num e) => e).toList()).toList(),
      'market_caps': marketCaps
          .map((List<num> e) => e.map((num e) => e).toList())
          .toList(),
      'total_volumes': totalVolumes
          .map((List<num> e) => e.map((num e) => e).toList())
          .toList(),
    };
  }
}
