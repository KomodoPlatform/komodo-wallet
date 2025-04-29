import 'package:equatable/equatable.dart';

class PublicInterestStats extends Equatable {
  const PublicInterestStats({this.alexaRank, this.bingMatches});

  factory PublicInterestStats.fromJson(Map<String, dynamic> json) {
    return PublicInterestStats(
      alexaRank: json['alexa_rank'] as dynamic,
      bingMatches: json['bing_matches'] as dynamic,
    );
  }
  final dynamic alexaRank;
  final dynamic bingMatches;

  Map<String, dynamic> toJson() => {
        'alexa_rank': alexaRank,
        'bing_matches': bingMatches,
      };

  PublicInterestStats copyWith({
    dynamic alexaRank,
    dynamic bingMatches,
  }) {
    return PublicInterestStats(
      alexaRank: alexaRank ?? this.alexaRank,
      bingMatches: bingMatches ?? this.bingMatches,
    );
  }

  @override
  List<Object?> get props => [alexaRank, bingMatches];
}
