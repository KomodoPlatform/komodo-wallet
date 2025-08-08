import 'package:rational/rational.dart';
import 'package:web_dex/model/my_orders/match_request.dart';
import 'package:web_dex/model/my_orders/matches.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';

class TakerOrder {
  TakerOrder({
    required this.createdAt,
    required this.cancellable,
    required this.matches,
    required this.request,
  });

  factory TakerOrder.fromJson(JsonMap json) {
    return TakerOrder(
      createdAt: json.value<int>('created_at'),
      cancellable: json.value<bool>('cancellable'),
      matches: json
          .valueOrNull<JsonMap>('matches')
          ?.map(
            (String k, dynamic v) =>
                MapEntry<String, Matches>(k, Matches.fromJson(v as JsonMap)),
          ),
      request: json.valueOrNull<JsonMap>('request') != null
          ? MatchRequest.fromJson(json.value<JsonMap>('request'))
          : MatchRequest(baseAmount: Rational.zero, relAmount: Rational.zero),
    );
  }

  int createdAt;
  bool cancellable;
  Map<String, Matches>? matches;
  MatchRequest request;

  JsonMap toJson() {
    final Map<String, Matches>? matches = this.matches;

    return <String, dynamic>{
      'created_at': createdAt,
      'cancellable': cancellable,
      'matches': matches == null
          ? null
          : Map<String, Matches>.from(matches).map<String, dynamic>(
              (String k, Matches v) => MapEntry<String, dynamic>(k, v.toJson()),
            ),
      'request': request.toJson(),
    };
  }
}
