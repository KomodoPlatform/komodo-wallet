import 'package:equatable/equatable.dart';
import 'package:web_dex/model/coin_type.dart';

enum FormStatus { initial, submitting, success, failure }

class CustomTokenImportState extends Equatable {
  final FormStatus formStatus;
  final FormStatus importStatus;
  final CoinType? network;
  final String? address;
  final int? decimals;
  final String? formErrorMessage;
  final String? importErrorMessage;
  final Map<String, dynamic>? tokenData;

  const CustomTokenImportState({
    this.network,
    this.address,
    this.decimals,
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
    int? Function()? decimals,
    String? Function()? formErrorMessage,
    String? Function()? importErrorMessage,
    Map<String, dynamic>? Function()? tokenData,
  }) {
    return CustomTokenImportState(
      formStatus: formStatus == null ? this.formStatus : formStatus(),
      importStatus: importStatus == null ? this.importStatus : importStatus(),
      network: network == null ? this.network : network(),
      address: address == null ? this.address : address(),
      decimals: decimals == null ? this.decimals : decimals(),
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
    int? Function()? decimals,
    FormStatus Function()? formStatus,
    FormStatus Function()? importStatus,
    String? Function()? formErrorMessage,
    String? Function()? importErrorMessage,
    Map<String, dynamic>? Function()? tokenData,
  }) {
    return CustomTokenImportState(
      formStatus: formStatus == null ? FormStatus.initial : formStatus(),
      importStatus: importStatus == null ? FormStatus.initial : importStatus(),
      network: network == null ? null : network(),
      address: address == null ? null : address(),
      decimals: decimals == null ? null : decimals(),
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
        decimals,
        formErrorMessage,
        importErrorMessage,
        tokenData,
      ];
}
