import 'package:equatable/equatable.dart';

import 'chat_registry.dart';

class TelegramServiceConfig extends Equatable {
  final String? apiKey;
  final ChatRegistry? chatRegistry;

  const TelegramServiceConfig({this.apiKey, this.chatRegistry});

  factory TelegramServiceConfig.fromJson(Map<String, dynamic> json) =>
      TelegramServiceConfig(
        apiKey: json['api_key'] as String?,
        chatRegistry: json['chat_registry'] == null
            ? null
            : ChatRegistry.fromJson(
                json['chat_registry'] as Map<String, dynamic>,
              ),
      );

  Map<String, dynamic> toJson() => {
    'api_key': apiKey,
    'chat_registry': chatRegistry?.toJson(),
  };

  TelegramServiceConfig copyWith({String? apiKey, ChatRegistry? chatRegistry}) {
    return TelegramServiceConfig(
      apiKey: apiKey ?? this.apiKey,
      chatRegistry: chatRegistry ?? this.chatRegistry,
    );
  }

  @override
  List<Object?> get props => [apiKey, chatRegistry];
}
