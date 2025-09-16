import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
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

  factory FiatBuyOrderInfo.fromJson(Map<String, dynamic> json) {
    final jsonData = json['data'] as Map<String, dynamic>?;
    final errors = json['errors'] as Map<String, dynamic>?;

    if (json['data'] == null && errors == null) {
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

    final data = jsonData!['order'] as Map<String, dynamic>;

    return FiatBuyOrderInfo(
      id: data['id'] as String? ?? '',
      accountId: data['account_id'] as String? ?? '',
      accountReference: data['account_reference'] as String? ?? '',
      orderType: data['order_type'] as String? ?? '',
      fiatCode: data['fiat_code'] as String? ?? '',
      fiatAmount: Decimal.parse(data['fiat_amount']?.toString() ?? '0'),
      coinCode: data['coin_code'] as String? ?? '',
      walletAddress: data['wallet_address'] as String? ?? '',
      extAccountId: data['ext_account_id'] as String? ?? '',
      network: data['network'] as String? ?? '',
      paymentCode: data['payment_code'] as String? ?? '',
      checkoutUrl: data['checkout_url'] as String? ?? '',
      createdAt: assertString(data['created_at']) ?? '',
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

  Map<String, dynamic> toJson() {
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
