import 'package:equatable/equatable.dart';
import 'package:komodo_wallet/model/hw_wallet/trezor_connection_status.dart';

class TrezorConnectionState extends Equatable {
  const TrezorConnectionState({required this.status});
  final TrezorConnectionStatus status;

  static TrezorConnectionState initial() =>
      const TrezorConnectionState(status: TrezorConnectionStatus.unknown);

  @override
  List<Object?> get props => [status];
}
