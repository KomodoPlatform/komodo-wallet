import 'package:rational/rational.dart';
import 'package:web_dex/model/my_orders/match_request.dart';
import 'package:web_dex/model/my_orders/matches.dart';

class TakerOrder {
  TakerOrder({
    required this.createdAt,
    required this.cancellable,
    required this.matches,
    required this.request,
  });

  factory TakerOrder.fromJson(Map<String, dynamic> json) {
    return TakerOrder(
      createdAt: json['created_at'] ?? 0,
      cancellable: json['cancellable'] ?? false,
      matches: json['matches'] == null
          ? null
          : Map<String, dynamic>.from(json['matches']).map(
              (String k, dynamic v) =>
                  MapEntry<String, Matches>(k, Matches.fromJson(v))),
      request: json['request'] == null
          ? MatchRequest(baseAmount: Rational.zero, relAmount: Rational.zero)
          : MatchRequest.fromJson(json['request']),
    );
  }

  int createdAt;
  bool cancellable;
  Map<String, Matches>? matches;
  MatchRequest request;

  Map<String, dynamic> toJson() {
    final Map<String, Matches>? matches = this.matches;

    return <String, dynamic>{
      'created_at': createdAt,
      'cancellable': cancellable,
      'matches': matches == null
          ? null
          : Map<String, Matches>.from(matches).map<String, dynamic>(
              (String k, Matches v) =>
                  MapEntry<String, dynamic>(k, v.toJson())),
      'request': request.toJson()
    };
  }
}
