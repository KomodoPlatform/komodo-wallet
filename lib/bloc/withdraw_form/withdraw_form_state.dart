import 'package:equatable/equatable.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_step.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/mm2/mm2_api/rpc/withdraw/fee/fee_request.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/hd_account/hd_account.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/model/withdraw_details/withdraw_details.dart';
import 'package:web_dex/shared/utils/utils.dart';

class WithdrawFormState extends Equatable {
  const WithdrawFormState({
    required this.coin,
    required this.step,
    required this.address,
    required this.amount,
    required this.senderAddresses,
    required this.selectedSenderAddress,
    required bool isMaxAmount,
    required this.customFee,
    required this.withdrawDetails,
    required this.isSending,
    required this.trezorProgressStatus,
    required this.sendError,
    required this.addressError,
    required this.amountError,
    required this.utxoCustomFeeError,
    required this.gasLimitError,
    required this.gasPriceError,
    required this.isCustomFeeEnabled,
    required this.memo,
    required CoinsRepo coinsRepository,
  })  : _isMaxAmount = isMaxAmount,
        _coinsRepo = coinsRepository;

  static WithdrawFormState initial(Coin coin, CoinsRepo coinsRepository) {
    final List<HdAddress> initSenderAddresses = coin.nonEmptyHdAddresses();
    final String selectedSenderAddress =
        initSenderAddresses.isNotEmpty ? initSenderAddresses.first.address : '';

    return WithdrawFormState(
      coin: coin,
      step: WithdrawFormStep.fill,
      address: '',
      amount: '',
      senderAddresses: initSenderAddresses,
      selectedSenderAddress: selectedSenderAddress,
      isMaxAmount: false,
      customFee: FeeRequest(type: ''),
      withdrawDetails: WithdrawDetails.empty(),
      isSending: false,
      isCustomFeeEnabled: false,
      trezorProgressStatus: null,
      sendError: TextError.empty(),
      addressError: TextError.empty(),
      amountError: TextError.empty(),
      utxoCustomFeeError: TextError.empty(),
      gasLimitError: TextError.empty(),
      gasPriceError: TextError.empty(),
      memo: null,
      coinsRepository: coinsRepository,
    );
  }

  WithdrawFormState copyWith({
    Coin? coin,
    String? address,
    String? amount,
    WithdrawFormStep? step,
    FeeRequest? customFee,
    List<HdAddress>? senderAddresses,
    String? selectedSenderAddress,
    bool? isMaxAmount,
    BaseError? sendError,
    BaseError? addressError,
    BaseError? amountError,
    BaseError? utxoCustomFeeError,
    BaseError? gasLimitError,
    BaseError? gasPriceError,
    WithdrawDetails? withdrawDetails,
    bool? isSending,
    bool? isCustomFeeEnabled,
    String? trezorProgressStatus,
    String? memo,
    CoinsRepo? coinsRepository,
  }) {
    return WithdrawFormState(
      coin: coin ?? this.coin,
      address: address ?? this.address,
      amount: amount ?? this.amount,
      step: step ?? this.step,
      customFee: customFee ?? this.customFee,
      isMaxAmount: isMaxAmount ?? this.isMaxAmount,
      senderAddresses: senderAddresses ?? this.senderAddresses,
      selectedSenderAddress:
          selectedSenderAddress ?? this.selectedSenderAddress,
      sendError: sendError ?? this.sendError,
      withdrawDetails: withdrawDetails ?? this.withdrawDetails,
      isSending: isSending ?? this.isSending,
      addressError: addressError ?? this.addressError,
      amountError: amountError ?? this.amountError,
      gasLimitError: gasLimitError ?? this.gasLimitError,
      gasPriceError: gasPriceError ?? this.gasPriceError,
      utxoCustomFeeError: utxoCustomFeeError ?? this.utxoCustomFeeError,
      isCustomFeeEnabled: isCustomFeeEnabled ?? this.isCustomFeeEnabled,
      trezorProgressStatus: trezorProgressStatus,
      memo: memo ?? this.memo,
      coinsRepository: coinsRepository ?? _coinsRepo,
    );
  }

  final Coin coin;
  final String address;
  final String amount;
  final WithdrawFormStep step;
  final List<HdAddress> senderAddresses;
  final String selectedSenderAddress;
  final FeeRequest customFee;
  final WithdrawDetails withdrawDetails;
  final bool isSending;
  final bool isCustomFeeEnabled;
  final String? trezorProgressStatus;
  final BaseError sendError;
  final BaseError addressError;
  final BaseError amountError;
  final BaseError utxoCustomFeeError;
  final BaseError gasLimitError;
  final BaseError gasPriceError;
  final bool _isMaxAmount;
  final String? memo;
  final CoinsRepo _coinsRepo;

  @override
  List<Object?> get props => [
        coin,
        address,
        amount,
        step,
        senderAddresses,
        selectedSenderAddress,
        isMaxAmount,
        customFee,
        withdrawDetails,
        isSending,
        isCustomFeeEnabled,
        trezorProgressStatus,
        sendError,
        addressError,
        amountError,
        utxoCustomFeeError,
        gasLimitError,
        gasPriceError,
        memo,
      ];

  bool get isMaxAmount =>
      _isMaxAmount || amount == doubleToString(senderAddressBalance);
  double get amountToSendDouble => double.tryParse(amount) ?? 0;
  String get amountToSendString {
    if (isMaxAmount && coin.abbr == withdrawDetails.feeCoin) {
      return doubleToString(
        amountToSendDouble - double.parse(withdrawDetails.feeValue),
      );
    }
    return amount;
  }

  double get senderAddressBalance {
    switch (coin.enabledType) {
      case WalletType.trezor:
        return coin.getHdAddress(selectedSenderAddress)?.balance.spendable ??
            0.0;
      default:
        return coin.sendableBalance;
    }
  }

  bool get hasAddressError => addressError.message.isNotEmpty;
  bool get hasAmountError => amountError.message.isNotEmpty;
  bool get hasSendError => sendError.message.isNotEmpty;
  bool get hasGasLimitError => gasLimitError.message.isNotEmpty;
  bool get hasGasPriceError => gasPriceError.message.isNotEmpty;
  bool get hasUtxoFeeError => utxoCustomFeeError.message.isNotEmpty;

  double? get usdAmountPrice => _coinsRepo.getUsdPriceByAmount(
        amount,
        coin.abbr,
      );

  double? get usdFeePrice => _coinsRepo.getUsdPriceByAmount(
        withdrawDetails.feeValue,
        withdrawDetails.feeCoin,
      );

  bool get isFeePriceExpensive {
    final usdFeePrice = this.usdFeePrice;
    final usdAmountPrice = this.usdAmountPrice;

    if (usdFeePrice == null || usdAmountPrice == null || usdAmountPrice == 0) {
      return false;
    }

    return usdFeePrice / usdAmountPrice >= 0.05;
  }
}
