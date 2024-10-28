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

  const FiatBuyOrderInfo.none()
      : this(
          id: '',
          accountId: '',
          accountReference: '',
          orderType: '',
          fiatCode: '',
          fiatAmount: 0.0,
          coinCode: '',
          walletAddress: '',
          extAccountId: '',
          network: '',
          paymentCode: '',
          checkoutUrl: '',
          createdAt: '',
          error: const FiatBuyOrderError.none(),
        );

  const FiatBuyOrderInfo.fromCheckoutUrl(String url)
      : this(
          id: '',
          accountId: '',
          accountReference: '',
          orderType: '',
          fiatCode: '',
          fiatAmount: 0.0,
          coinCode: '',
          walletAddress: '',
          extAccountId: '',
          network: '',
          paymentCode: '',
          checkoutUrl: url,
          createdAt: '',
          error: const FiatBuyOrderError.none(),
        );

  factory FiatBuyOrderInfo.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> data = json;
    if (json['data'] != null) {
      final orderData = json['data'] as Map<String, dynamic>? ?? {};
      data = orderData['order'] as Map<String, dynamic>? ?? {};
    }

    return FiatBuyOrderInfo(
      id: data['id'] as String? ?? '',
      accountId: data['account_id'] as String? ?? '',
      accountReference: data['account_reference'] as String? ?? '',
      orderType: data['order_type'] as String? ?? '',
      fiatCode: data['fiat_code'] as String? ?? '',
      fiatAmount: assertDouble(data['fiat_amount']),
      coinCode: data['coin_code'] as String? ?? '',
      walletAddress: data['wallet_address'] as String? ?? '',
      extAccountId: data['ext_account_id'] as String? ?? '',
      network: data['network'] as String? ?? '',
      paymentCode: data['payment_code'] as String? ?? '',
      checkoutUrl: data['checkout_url'] as String? ?? '',
      createdAt: assertString(data['created_at']) ??  '',
      error: data['errors'] != null
          ? FiatBuyOrderError.fromJson(data['errors'] as Map<String, dynamic>)
          : const FiatBuyOrderError.none(),
    );
  }
  final String id;
  final String accountId;
  final String accountReference;
  final String orderType;
  final String fiatCode;
  final double fiatAmount;
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
          'fiat_amount': fiatAmount,
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
    double? fiatAmount,
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
