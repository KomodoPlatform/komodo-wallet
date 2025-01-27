import 'package:equatable/equatable.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/model/coin.dart';

enum FormStatus { initial, submitting, success, failure }

class CustomTokenImportState extends Equatable {
  final FormStatus formStatus;
  final FormStatus importStatus;
  final CoinSubClass? network;
  final String? address;
  final String? formErrorMessage;
  final String? importErrorMessage;
  final Coin? coin;
  final Iterable<CoinSubClass> evmNetworks;

  const CustomTokenImportState({
    this.network,
    this.address,
    this.formStatus = FormStatus.initial,
    this.importStatus = FormStatus.initial,
    this.formErrorMessage,
    this.importErrorMessage,
    this.coin,
    this.evmNetworks = const [],
  });

  CustomTokenImportState copyWith({
    // why use functions here?
    FormStatus Function()? formStatus,
    FormStatus Function()? importStatus,
    CoinSubClass? Function()? network,
    String? Function()? address,
    String? Function()? formErrorMessage,
    String? Function()? importErrorMessage,
    Coin? Function()? tokenData,
    Iterable<CoinSubClass>? evmNetworks,
  }) {
    return CustomTokenImportState(
      formStatus: formStatus == null ? this.formStatus : formStatus(),
      importStatus: importStatus == null ? this.importStatus : importStatus(),
      network: network == null ? this.network : network(),
      address: address == null ? this.address : address(),
      formErrorMessage:
          formErrorMessage == null ? this.formErrorMessage : formErrorMessage(),
      importErrorMessage: importErrorMessage == null
          ? this.importErrorMessage
          : importErrorMessage(),
      coin: tokenData == null ? coin : tokenData(),
      evmNetworks: evmNetworks ?? this.evmNetworks,
    );
  }

  CustomTokenImportState resetWith({
    // same as above?
    CoinSubClass? Function()? network,
    String? Function()? address,
    FormStatus Function()? formStatus,
    FormStatus Function()? importStatus,
    String? Function()? formErrorMessage,
    String? Function()? importErrorMessage,
    Coin? Function()? tokenData,
    Iterable<CoinSubClass>? evmNetworks,
  }) {
    return CustomTokenImportState(
      formStatus: formStatus == null ? FormStatus.initial : formStatus(),
      importStatus: importStatus == null ? FormStatus.initial : importStatus(),
      network: network == null ? null : network(),
      address: address == null ? null : address(),
      formErrorMessage: formErrorMessage == null ? null : formErrorMessage(),
      importErrorMessage:
          importErrorMessage == null ? null : importErrorMessage(),
      coin: tokenData == null ? null : tokenData(),
      evmNetworks: evmNetworks ?? const [],
    );
  }

  @override
  List<Object?> get props => [
        formStatus,
        importStatus,
        network,
        address,
        formErrorMessage,
        importErrorMessage,
        coin,
        evmNetworks,
      ];
}
