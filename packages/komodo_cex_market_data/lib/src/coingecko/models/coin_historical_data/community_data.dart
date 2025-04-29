import 'package:equatable/equatable.dart';

class CommunityData extends Equatable {
  const CommunityData({
    this.facebookLikes,
    this.twitterFollowers,
    this.redditAveragePosts48h,
    this.redditAverageComments48h,
    this.redditSubscribers,
    this.redditAccountsActive48h,
  });

  factory CommunityData.fromJson(Map<String, dynamic> json) => CommunityData(
        facebookLikes: json['facebook_likes'] as dynamic,
        twitterFollowers: json['twitter_followers'] as dynamic,
        redditAveragePosts48h: json['reddit_average_posts_48h'] as int?,
        redditAverageComments48h: json['reddit_average_comments_48h'] as int?,
        redditSubscribers: json['reddit_subscribers'] as dynamic,
        redditAccountsActive48h: json['reddit_accounts_active_48h'] as dynamic,
      );
  final dynamic facebookLikes;
  final dynamic twitterFollowers;
  final int? redditAveragePosts48h;
  final int? redditAverageComments48h;
  final dynamic redditSubscribers;
  final dynamic redditAccountsActive48h;

  Map<String, dynamic> toJson() => {
        'facebook_likes': facebookLikes,
        'twitter_followers': twitterFollowers,
        'reddit_average_posts_48h': redditAveragePosts48h,
        'reddit_average_comments_48h': redditAverageComments48h,
        'reddit_subscribers': redditSubscribers,
        'reddit_accounts_active_48h': redditAccountsActive48h,
      };

  CommunityData copyWith({
    dynamic facebookLikes,
    dynamic twitterFollowers,
    int? redditAveragePosts48h,
    int? redditAverageComments48h,
    dynamic redditSubscribers,
    dynamic redditAccountsActive48h,
  }) {
    return CommunityData(
      facebookLikes: facebookLikes ?? this.facebookLikes,
      twitterFollowers: twitterFollowers ?? this.twitterFollowers,
      redditAveragePosts48h:
          redditAveragePosts48h ?? this.redditAveragePosts48h,
      redditAverageComments48h:
          redditAverageComments48h ?? this.redditAverageComments48h,
      redditSubscribers: redditSubscribers ?? this.redditSubscribers,
      redditAccountsActive48h:
          redditAccountsActive48h ?? this.redditAccountsActive48h,
    );
  }

  @override
  List<Object?> get props {
    return [
      facebookLikes,
      twitterFollowers,
      redditAveragePosts48h,
      redditAverageComments48h,
      redditSubscribers,
      redditAccountsActive48h,
    ];
  }
}
