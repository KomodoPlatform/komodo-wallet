import 'package:equatable/equatable.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_type.dart';

enum FormStatus { initial, submitting, success, failure }

class CustomTokenImportState extends Equatable {
  final FormStatus formStatus;
  final FormStatus importStatus;
  final CoinType? network;
  final String? address;
  final String? formErrorMessage;
  final String? importErrorMessage;
  final Coin? tokenData;

  const CustomTokenImportState({
    this.network,
    this.address,
    this.formStatus = FormStatus.initial,
    this.importStatus = FormStatus.initial,
    this.formErrorMessage,
    this.importErrorMessage,
    this.tokenData,
  });

  CustomTokenImportState copyWith({
    FormStatus Function()? formStatus,
    FormStatus Function()? importStatus,
    CoinType? Function()? network,
    String? Function()? address,
    String? Function()? formErrorMessage,
    String? Function()? importErrorMessage,
    Coin? Function()? tokenData,
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
      tokenData: tokenData == null ? this.tokenData : tokenData(),
    );
  }

  CustomTokenImportState resetWith({
    CoinType? Function()? network,
    String? Function()? address,
    FormStatus Function()? formStatus,
    FormStatus Function()? importStatus,
    String? Function()? formErrorMessage,
    String? Function()? importErrorMessage,
    Coin? Function()? tokenData,
  }) {
    return CustomTokenImportState(
      formStatus: formStatus == null ? FormStatus.initial : formStatus(),
      importStatus: importStatus == null ? FormStatus.initial : importStatus(),
      network: network == null ? null : network(),
      address: address == null ? null : address(),
      formErrorMessage: formErrorMessage == null ? null : formErrorMessage(),
      importErrorMessage:
          importErrorMessage == null ? null : importErrorMessage(),
      tokenData: tokenData == null ? null : tokenData(),
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
        tokenData,
      ];
}
