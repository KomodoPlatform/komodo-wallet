import 'package:komodo_wallet/model/my_orders/match_connect.dart';
import 'package:komodo_wallet/model/my_orders/match_request.dart';

class Matches {
  Matches({
    required this.connect,
    required this.connected,
    required this.lastUpdated,
    required this.request,
    required this.reserved,
  });

  factory Matches.fromJson(Map<String, dynamic> json) => Matches(
        connect: json['connect'] == null
            ? null
            : MatchConnect.fromJson(json['connect']),
        connected: json['connected'] == null
            ? null
            : MatchConnect.fromJson(json['connected']),
        lastUpdated: json['last_updated'] ?? 0,
        request: json['request'] == null
            ? null
            : MatchRequest.fromJson(json['request']),
        reserved: json['reserved'] == null
            ? null
            : MatchRequest.fromJson(json['reserved']),
      );

  MatchConnect? connect;
  MatchConnect? connected;
  int lastUpdated;
  MatchRequest? request;
  MatchRequest? reserved;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'connect': connect?.toJson(),
        'connected': connected?.toJson(),
        'last_updated': lastUpdated,
        'request': request?.toJson(),
        'reserved': reserved?.toJson(),
      };
}
