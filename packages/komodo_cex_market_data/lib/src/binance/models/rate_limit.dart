/// Represents a rate limit type for an API endpoint.
class RateLimit {
  /// Creates a new instance of [RateLimit].
  RateLimit({
    required this.rateLimitType,
    required this.interval,
    required this.intervalNum,
    required this.limit,
  });

  /// Creates a new instance of [RateLimit] from a JSON map.
  factory RateLimit.fromJson(Map<String, dynamic> json) {
    return RateLimit(
      rateLimitType: json['rateLimitType'] as String,
      interval: json['interval'] as String,
      intervalNum: json['intervalNum'] as int,
      limit: json['limit'] as int,
    );
  }

  /// The type of rate limit.
  String rateLimitType;

  /// The interval of the rate limit.
  String interval;

  /// The number of intervals.
  int intervalNum;

  /// The limit for the rate limit.
  int limit;
}
