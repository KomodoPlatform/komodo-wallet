import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:web_dex/bloc/fiat/models/fiat_buy_order_error.dart';
import 'package:web_dex/shared/utils/utils.dart';

class FiatBuyOrderInfo extends Equatable {
  const FiatBuyOrderInfo({
    required this.id,
    required this.accountId,
    required this.accountReference,
    required this.orderType,
    required this.fiatCode,
    required this.fiatAmount,
    required this.coinCode,
    required this.walletAddress,
    required this.extAccountId,
    required this.network,
    required this.paymentCode,
    required this.checkoutUrl,
    required this.createdAt,
    required this.error,
  });

  FiatBuyOrderInfo.fromCheckoutUrl(String url)
    : this(
        id: '',
        accountId: '',
        accountReference: '',
        orderType: '',
        fiatCode: '',
        fiatAmount: Decimal.zero,
        coinCode: '',
        walletAddress: '',
        extAccountId: '',
        network: '',
        paymentCode: '',
        checkoutUrl: url,
        createdAt: '',
        error: const FiatBuyOrderError.none(),
      );

  FiatBuyOrderInfo.empty()
    : this(
        id: '',
        accountId: '',
        accountReference: '',
        orderType: '',
        fiatCode: '',
        fiatAmount: Decimal.zero,
        coinCode: '',
        walletAddress: '',
        extAccountId: '',
        network: '',
        paymentCode: '',
        checkoutUrl: '',
        createdAt: '',
        error: const FiatBuyOrderError.none(),
      );

  factory FiatBuyOrderInfo.fromJson(JsonMap json) {
    final jsonData = json.valueOrNull<JsonMap>('data');
    final errors = json.valueOrNull<JsonMap>('errors');

    if (jsonData == null && errors == null) {
      return FiatBuyOrderInfo.empty().copyWith(
        error: const FiatBuyOrderError.parsing(
          message: 'Missing order payload',
        ),
      );
    }

    if (jsonData == null && errors != null) {
      return FiatBuyOrderInfo.empty().copyWith(
        error: FiatBuyOrderError.fromJson(errors),
      );
    }

    final data = jsonData!.value<JsonMap>('order')!;

    return FiatBuyOrderInfo(
      id: data.valueOrNull<String>('id') ?? '',
      accountId: data.valueOrNull<String>('account_id') ?? '',
      accountReference: data.valueOrNull<String>('account_reference') ?? '',
      orderType: data.valueOrNull<String>('order_type') ?? '',
      fiatCode: data.valueOrNull<String>('fiat_code') ?? '',
      fiatAmount: data.value<Decimal>('fiat_amount'),
      coinCode: data.valueOrNull<String>('coin_code') ?? '',
      walletAddress: data.valueOrNull<String>('wallet_address') ?? '',
      extAccountId: data.valueOrNull<String>('ext_account_id') ?? '',
      network: data.valueOrNull<String>('network') ?? '',
      paymentCode: data.valueOrNull<String>('payment_code') ?? '',
      checkoutUrl: data.valueOrNull<String>('checkout_url') ?? '',
      createdAt: assertString(data.valueOrNull<String>('created_at')) ?? '',
      error: errors != null
          ? FiatBuyOrderError.fromJson(errors)
          : const FiatBuyOrderError.none(),
    );
  }

  final String id;
  final String accountId;
  final String accountReference;
  final String orderType;
  final String fiatCode;
  final Decimal fiatAmount;
  final String coinCode;
  final String walletAddress;
  final String extAccountId;
  final String network;
  final String paymentCode;
  final String checkoutUrl;
  final String createdAt;
  final FiatBuyOrderError error;

  @override
  List<Object?> get props => [
    id,
    accountId,
    accountReference,
    orderType,
    fiatCode,
    fiatAmount,
    coinCode,
    walletAddress,
    extAccountId,
    network,
    paymentCode,
    checkoutUrl,
    createdAt,
    error,
  ];

  JsonMap toJson() {
    return {
      'data': {
        'order': {
          'id': id,
          'account_id': accountId,
          'account_reference': accountReference,
          'order_type': orderType,
          'fiat_code': fiatCode,
          'fiat_amount': fiatAmount.toString(),
          'coin_code': coinCode,
          'wallet_address': walletAddress,
          'ext_account_id': extAccountId,
          'network': network,
          'payment_code': paymentCode,
          'checkout_url': checkoutUrl,
          'created_at': createdAt,
          'errors': error.toJson(),
        },
      },
    };
  }

  FiatBuyOrderInfo copyWith({
    String? id,
    String? accountId,
    String? accountReference,
    String? orderType,
    String? fiatCode,
    Decimal? fiatAmount,
    String? coinCode,
    String? walletAddress,
    String? extAccountId,
    String? network,
    String? paymentCode,
    String? checkoutUrl,
    String? createdAt,
    FiatBuyOrderError? error,
  }) {
    return FiatBuyOrderInfo(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      accountReference: accountReference ?? this.accountReference,
      orderType: orderType ?? this.orderType,
      fiatCode: fiatCode ?? this.fiatCode,
      fiatAmount: fiatAmount ?? this.fiatAmount,
      coinCode: coinCode ?? this.coinCode,
      walletAddress: walletAddress ?? this.walletAddress,
      extAccountId: extAccountId ?? this.extAccountId,
      network: network ?? this.network,
      paymentCode: paymentCode ?? this.paymentCode,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      createdAt: createdAt ?? this.createdAt,
      error: error ?? this.error,
    );
  }
}
