import 'package:komodo_defi_types/komodo_defi_types.dart';

sealed class MessageSigningEvent {}

class MessageSigningAddressesRequested extends MessageSigningEvent {
  final Asset asset;

  MessageSigningAddressesRequested(this.asset);
}

class MessageSigningAddressSelected extends MessageSigningEvent {
  final PubkeyInfo address;

  MessageSigningAddressSelected(this.address);
}

class MessageSigningFormSubmitted extends MessageSigningEvent {
  final String message;
  final String coinAbbr;

  MessageSigningFormSubmitted({
    required this.message,
    required this.coinAbbr,
  });
}

class MessageSigningInputConfirmed extends MessageSigningEvent {}
class MessageSigningConfirmationCancelled extends MessageSigningEvent {}