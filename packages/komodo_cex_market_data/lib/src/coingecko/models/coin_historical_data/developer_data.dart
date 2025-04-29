import 'package:equatable/equatable.dart';

import 'package:komodo_cex_market_data/src/coingecko/models/coin_historical_data/code_additions_deletions4_weeks.dart';

class DeveloperData extends Equatable {
  const DeveloperData({
    this.forks,
    this.stars,
    this.subscribers,
    this.totalIssues,
    this.closedIssues,
    this.pullRequestsMerged,
    this.pullRequestContributors,
    this.codeAdditionsDeletions4Weeks,
    this.commitCount4Weeks,
  });

  factory DeveloperData.fromJson(Map<String, dynamic> json) => DeveloperData(
        forks: json['forks'] as dynamic,
        stars: json['stars'] as dynamic,
        subscribers: json['subscribers'] as dynamic,
        totalIssues: json['total_issues'] as dynamic,
        closedIssues: json['closed_issues'] as dynamic,
        pullRequestsMerged: json['pull_requests_merged'] as dynamic,
        pullRequestContributors: json['pull_request_contributors'] as dynamic,
        codeAdditionsDeletions4Weeks:
            json['code_additions_deletions_4_weeks'] == null
                ? null
                : CodeAdditionsDeletions4Weeks.fromJson(
                    json['code_additions_deletions_4_weeks']
                        as Map<String, dynamic>,
                  ),
        commitCount4Weeks: json['commit_count_4_weeks'] as dynamic,
      );
  final dynamic forks;
  final dynamic stars;
  final dynamic subscribers;
  final dynamic totalIssues;
  final dynamic closedIssues;
  final dynamic pullRequestsMerged;
  final dynamic pullRequestContributors;
  final CodeAdditionsDeletions4Weeks? codeAdditionsDeletions4Weeks;
  final dynamic commitCount4Weeks;

  Map<String, dynamic> toJson() => {
        'forks': forks,
        'stars': stars,
        'subscribers': subscribers,
        'total_issues': totalIssues,
        'closed_issues': closedIssues,
        'pull_requests_merged': pullRequestsMerged,
        'pull_request_contributors': pullRequestContributors,
        'code_additions_deletions_4_weeks':
            codeAdditionsDeletions4Weeks?.toJson(),
        'commit_count_4_weeks': commitCount4Weeks,
      };

  DeveloperData copyWith({
    dynamic forks,
    dynamic stars,
    dynamic subscribers,
    dynamic totalIssues,
    dynamic closedIssues,
    dynamic pullRequestsMerged,
    dynamic pullRequestContributors,
    CodeAdditionsDeletions4Weeks? codeAdditionsDeletions4Weeks,
    dynamic commitCount4Weeks,
  }) {
    return DeveloperData(
      forks: forks ?? this.forks,
      stars: stars ?? this.stars,
      subscribers: subscribers ?? this.subscribers,
      totalIssues: totalIssues ?? this.totalIssues,
      closedIssues: closedIssues ?? this.closedIssues,
      pullRequestsMerged: pullRequestsMerged ?? this.pullRequestsMerged,
      pullRequestContributors:
          pullRequestContributors ?? this.pullRequestContributors,
      codeAdditionsDeletions4Weeks:
          codeAdditionsDeletions4Weeks ?? this.codeAdditionsDeletions4Weeks,
      commitCount4Weeks: commitCount4Weeks ?? this.commitCount4Weeks,
    );
  }

  @override
  List<Object?> get props {
    return [
      forks,
      stars,
      subscribers,
      totalIssues,
      closedIssues,
      pullRequestsMerged,
      pullRequestContributors,
      codeAdditionsDeletions4Weeks,
      commitCount4Weeks,
    ];
  }
}
