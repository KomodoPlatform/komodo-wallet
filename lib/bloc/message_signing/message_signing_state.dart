import 'package:equatable/equatable.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

enum MessageSigningStatus {
  initial,
  loading,
  ready,
  confirming,
  submitting,
  success,
  failure,
}

class MessageSigningState extends Equatable {
  final List<PubkeyInfo> addresses;
  final PubkeyInfo? selected;
  final String? signedMessage;
  final String? errorMessage;
  final MessageSigningStatus status;

  const MessageSigningState({
    required this.addresses,
    required this.selected,
    required this.signedMessage,
    required this.errorMessage,
    required this.status,
  });

  factory MessageSigningState.initial() => const MessageSigningState(
        addresses: [],
        selected: null,
        signedMessage: null,
        errorMessage: null,
        status: MessageSigningStatus.initial,
      );

  MessageSigningState copyWith({
    List<PubkeyInfo>? addresses,
    PubkeyInfo? selected,
    String? signedMessage,
    String? errorMessage,
    MessageSigningStatus? status,
  }) {
    return MessageSigningState(
      addresses: addresses ?? this.addresses,
      selected: selected ?? this.selected,
      signedMessage: signedMessage ?? this.signedMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        addresses,
        selected,
        signedMessage,
        errorMessage,
        status,
      ];
}