import 'package:equatable/equatable.dart';

/// Represents the chat registry configuration - the chat IDs for the
/// default chat, the maker bot chat, and the swap events chat.
class ChatRegistry extends Equatable {
  const ChatRegistry({
    this.defaultId,
    this.makerBotId,
    this.swapEventsId,
  });

  factory ChatRegistry.fromJson(Map<String, dynamic> json) => ChatRegistry(
        defaultId: json['default'] as String?,
        makerBotId: json['maker_bot'] as String?,
        swapEventsId: json['swap_events'] as String?,
      );

  /// The default chat ID.
  final String? defaultId;

  /// The maker bot chat ID.
  final String? makerBotId;

  /// The swap events chat ID.
  final String? swapEventsId;

  Map<String, dynamic> toJson() => {
        'default': defaultId,
        'maker_bot': makerBotId,
        'swap_events': swapEventsId,
      };

  ChatRegistry copyWith({
    String? defaultId,
    String? makerBotId,
    String? swapEventsId,
  }) {
    return ChatRegistry(
      defaultId: defaultId ?? this.defaultId,
      makerBotId: makerBotId ?? this.makerBotId,
      swapEventsId: swapEventsId ?? this.swapEventsId,
    );
  }

  @override
  List<Object?> get props => [defaultId, makerBotId, swapEventsId];
}
