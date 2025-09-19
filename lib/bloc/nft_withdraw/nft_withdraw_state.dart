part of 'nft_withdraw_bloc.dart';

abstract class NftWithdrawState {
  const NftWithdrawState({required this.nft});
  final NftToken nft;
}

class NftWithdrawFillState extends NftWithdrawState {
  final String address;
  final int? amount;
  final bool isSending;
  final BaseError? sendError;
  final BaseError? addressError;
  final BaseError? amountError;

  const NftWithdrawFillState({
    required super.nft,
    required this.address,
    required this.amount,
    required this.isSending,
    this.sendError,
    this.addressError,
    this.amountError,
  });

  static NftWithdrawFillState initial(NftToken nft) => NftWithdrawFillState(
        nft: nft,
        address: '',
        amount: 1,
        isSending: false,
        amountError: null,
        addressError: null,
        sendError: null,
      );

  NftWithdrawFillState copyWith({
    NftToken Function()? nft,
    String Function()? address,
    int? Function()? amount,
    NftTransactionDetails? Function()? txDetails,
    bool Function()? isSending,
    BaseError? Function()? sendError,
    BaseError? Function()? addressError,
    BaseError? Function()? amountError,
  }) {
    return NftWithdrawFillState(
      nft: nft == null ? this.nft : nft(),
      address: address == null ? this.address : address(),
      amount: amount == null ? this.amount : amount(),
      isSending: isSending == null ? this.isSending : isSending(),
      addressError: addressError == null ? this.addressError : addressError(),
      amountError: amountError == null ? this.amountError : amountError(),
      sendError: sendError == null ? this.sendError : sendError(),
    );
  }
}

class NftWithdrawConfirmState extends NftWithdrawState {
  final NftTransactionDetails txDetails;
  final bool isSending;
  final BaseError? sendError;

  const NftWithdrawConfirmState({
    required this.txDetails,
    required this.isSending,
    this.sendError,
    required super.nft,
  });

  NftWithdrawConfirmState copyWith({
    NftTransactionDetails Function()? txDetails,
    bool Function()? isSending,
    BaseError? Function()? sendError,
    NftToken Function()? nft,
  }) {
    return NftWithdrawConfirmState(
      txDetails: txDetails == null ? this.txDetails : txDetails(),
      isSending: isSending == null ? this.isSending : isSending(),
      sendError: sendError == null ? this.sendError : sendError(),
      nft: nft == null ? this.nft : nft(),
    );
  }
}

class NftWithdrawSuccessState extends NftWithdrawState {
  const NftWithdrawSuccessState({
    required this.txHash,
    required super.nft,
    required this.timestamp,
    required this.to,
  });
  final String txHash;
  final int timestamp;
  final String to;
}
