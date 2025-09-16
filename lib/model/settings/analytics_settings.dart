class AnalyticsSettings {
  const AnalyticsSettings({required this.isSendAllowed});

  static AnalyticsSettings initial() {
    return const AnalyticsSettings(isSendAllowed: true);
  }

  final bool isSendAllowed;

  AnalyticsSettings copyWith({bool? isSendAllowed}) {
    return AnalyticsSettings(
      isSendAllowed: isSendAllowed ?? this.isSendAllowed,
    );
  }

  static AnalyticsSettings fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AnalyticsSettings.initial();
    }

    return AnalyticsSettings(isSendAllowed: json['send_allowed'] ?? false);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'send_allowed': isSendAllowed,
  };
}
