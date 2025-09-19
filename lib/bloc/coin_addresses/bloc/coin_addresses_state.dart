import 'package:equatable/equatable.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

enum FormStatus { initial, submitting, success, failure }

class CoinAddressesState extends Equatable {
  final FormStatus status;
  final FormStatus createAddressStatus;
  final String? errorMessage;
  final List<PubkeyInfo> addresses;
  final bool hideZeroBalance;
  final Set<CantCreateNewAddressReason>? cantCreateNewAddressReasons;
  final NewAddressState? newAddressState;

  const CoinAddressesState({
    this.status = FormStatus.initial,
    this.createAddressStatus = FormStatus.initial,
    this.errorMessage,
    this.addresses = const [],
    this.hideZeroBalance = false,
    this.cantCreateNewAddressReasons,
    this.newAddressState,
  });

  CoinAddressesState copyWith({
    FormStatus Function()? status,
    FormStatus Function()? createAddressStatus,
    String? Function()? errorMessage,
    List<PubkeyInfo> Function()? addresses,
    bool Function()? hideZeroBalance,
    Set<CantCreateNewAddressReason>? Function()? cantCreateNewAddressReasons,
    NewAddressState? Function()? newAddressState,
  }) {
    return CoinAddressesState(
      status: status == null ? this.status : status(),
      createAddressStatus: createAddressStatus == null
          ? this.createAddressStatus
          : createAddressStatus(),
      errorMessage: errorMessage == null ? this.errorMessage : errorMessage(),
      addresses: addresses == null ? this.addresses : addresses(),
      hideZeroBalance:
          hideZeroBalance == null ? this.hideZeroBalance : hideZeroBalance(),
      cantCreateNewAddressReasons: cantCreateNewAddressReasons == null
          ? this.cantCreateNewAddressReasons
          : cantCreateNewAddressReasons(),
      newAddressState:
          newAddressState == null ? this.newAddressState : newAddressState(),
    );
  }

  CoinAddressesState resetWith({
    FormStatus Function()? status,
    FormStatus Function()? createAddressStatus,
    String? Function()? errorMessage,
    List<PubkeyInfo> Function()? addresses,
    bool Function()? hideZeroBalance,
    Set<CantCreateNewAddressReason>? Function()? cantCreateNewAddressReasons,
    NewAddressState? Function()? newAddressState,
  }) {
    return CoinAddressesState(
      status: status == null ? FormStatus.initial : status(),
      createAddressStatus: createAddressStatus == null
          ? FormStatus.initial
          : createAddressStatus(),
      errorMessage: errorMessage == null ? null : errorMessage(),
      addresses: addresses == null ? [] : addresses(),
      hideZeroBalance: hideZeroBalance == null ? false : hideZeroBalance(),
      cantCreateNewAddressReasons: cantCreateNewAddressReasons == null
          ? null
          : cantCreateNewAddressReasons(),
      newAddressState: newAddressState == null ? null : newAddressState(),
    );
  }

  @override
  List<Object?> get props => [
        status,
        createAddressStatus,
        errorMessage,
        addresses,
        hideZeroBalance,
        cantCreateNewAddressReasons,
        newAddressState,
      ];
}
