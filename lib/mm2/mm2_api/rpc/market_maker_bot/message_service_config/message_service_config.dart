import 'package:equatable/equatable.dart';

import 'telegram_service_config.dart';

class MessageServiceConfig extends Equatable {
  final TelegramServiceConfig? telegram;

  const MessageServiceConfig({this.telegram});

  factory MessageServiceConfig.initial() {
    return const MessageServiceConfig(telegram: null);
  }

  factory MessageServiceConfig.fromJson(Map<String, dynamic> json) {
    return MessageServiceConfig(
      telegram: json['telegram'] == null
          ? null
          : TelegramServiceConfig.fromJson(
              json['telegram'] as Map<String, dynamic>,
            ),
    );
  }

  Map<String, dynamic> toJson() => {
        'telegram': telegram?.toJson(),
      }..removeWhere((key, value) => value == null);

  MessageServiceConfig copyWith({
    TelegramServiceConfig? telegram,
  }) {
    return MessageServiceConfig(
      telegram: telegram ?? this.telegram,
    );
  }

  @override
  List<Object?> get props => [telegram];
}
