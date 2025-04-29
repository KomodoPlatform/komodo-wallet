import 'package:equatable/equatable.dart';

/// Represents a coin that can be traded on the CEX exchange.
class CexCoin extends Equatable {
  const CexCoin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.currencies,
    this.source,
  });

  factory CexCoin.fromJson(Map<String, dynamic> json) {
    return CexCoin(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      currencies: ((json['currencies'] ?? <String>[]) as List<String>).toSet(),
    );
  }

  /// The unique identifier of the coin.
  final String id;

  /// The symbol (abbreviation) of the coin.
  final String symbol;

  /// The friendly name of the coin.
  final String name;

  /// The list of currencies that the coin can be traded with.
  final Set<String> currencies;

  /// The source of the coin data.
  final String? source;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'symbol': symbol,
      'name': name,
      'currencies': currencies,
    };
  }

  CexCoin copyWith({
    String? id,
    String? symbol,
    String? name,
    Set<String>? currencies,
  }) {
    return CexCoin(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      currencies: currencies ?? this.currencies,
    );
  }

  @override
  String toString() {
    return 'Coin{id: $id, symbol: $symbol, name: $name}';
  }

  @override
  List<Object?> get props => <Object?>[id];
}
