import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/fiat/base_fiat_provider.dart';
import 'package:web_dex/bloc/fiat/fiat_order_status.dart';
import 'package:web_dex/bloc/fiat/models/models.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/shared/utils/utils.dart';

class BanxaFiatProvider extends BaseFiatProvider {
  BanxaFiatProvider();
  final String providerId = 'Banxa';
  final String apiEndpoint = '/api/v1/banxa';
  static final _log = Logger('BanxaFiatProvider');

  @override
  String getProviderId() {
    return providerId;
  }

  @override
  String get providerIconPath => '$assetsPath/fiat/providers/banxa_icon.svg';

  FiatOrderStatus _parseStatusFromResponse(Map<String, dynamic> response) {
    final statusString = response['data']?['order']?['status'] as String?;

    return _parseOrderStatus(statusString ?? '');
  }

  Future<dynamic> _getPaymentMethods(
    String source,
    ICurrency target, {
    String? sourceAmount,
  }) =>
      apiRequest(
        'GET',
        apiEndpoint,
        queryParams: {
          'endpoint': '/api/payment-methods',
          'source': source,
          'target': target.symbol,
        },
      );

  Future<dynamic> _getPricesWithPaymentMethod(
    String source,
    ICurrency target,
    String sourceAmount,
    FiatPaymentMethod paymentMethod,
  ) =>
      apiRequest(
        'GET',
        apiEndpoint,
        queryParams: {
          'endpoint': '/api/prices',
          'source': source,
          'target': target.symbol,
          'source_amount': sourceAmount,
          'payment_method_id': paymentMethod.id,
        },
      );

  Future<dynamic> _createOrder(Map<String, dynamic> payload) => apiRequest(
        'POST',
        apiEndpoint,
        queryParams: {
          'endpoint': '/api/orders',
        },
        body: payload,
      );

  Future<dynamic> _getOrder(String orderId) => apiRequest(
        'GET',
        apiEndpoint,
        queryParams: {
          'endpoint': '/api/orders',
          'order_id': orderId,
        },
      );

  Future<dynamic> _getFiats() => apiRequest(
        'GET',
        apiEndpoint,
        queryParams: {
          'endpoint': '/api/fiats',
          'orderType': 'buy',
        },
      );

  Future<dynamic> _getCoins() => apiRequest(
        'GET',
        apiEndpoint,
        queryParams: {
          'endpoint': '/api/coins',
          'orderType': 'buy',
        },
      );

  FiatOrderStatus _parseOrderStatus(String status) {
    // The case statements are references to Banxa's order statuses. See the
    // docs link here for more info: https://docs.banxa.com/docs/order-status
    switch (status) {
      case 'complete':
        return FiatOrderStatus.success;

      case 'cancelled':
      case 'declined':
      case 'expired':
      case 'refunded':
        return FiatOrderStatus.failed;

      case 'extraVerification':
      case 'pendingPayment':
      case 'waitingPayment':
        return FiatOrderStatus.pending;

      case 'paymentReceived':
      case 'inProgress':
      case 'coinTransferred':
        return FiatOrderStatus.inProgress;

      default:
        throw Exception('Unknown status: $status');
    }
  }

  // These will be in BLOC:
  @override
  Stream<FiatOrderStatus> watchOrderStatus(String orderId) async* {
    FiatOrderStatus? lastStatus;

    // TODO: At the moment we're polling the API for order status. We can
    // further optimise this by listening for the status redirect page post
    // message, but adds the challenge that we add further web-only code that
    // needs to be re-implemented for mobile/desktop.
    while (true) {
      final response = await _getOrder(orderId)
          .catchError((e) => Future<void>.error('Error fetching order: $e'));

      _log.fine('Fiat order status response:\n${jsonEncode(response)}');
      final status =
          _parseStatusFromResponse(response as Map<String, dynamic>? ?? {});
      final isCompleted =
          status == FiatOrderStatus.success || status == FiatOrderStatus.failed;

      if (status != lastStatus) {
        lastStatus = status;

        yield status;
      }

      if (isCompleted) break;

      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }

  @override
  Future<List<FiatCurrency>> getFiatList() async {
    final response = await _getFiats();
    final data = response['data']['fiats'] as List<dynamic>;
    return data
        .map(
          (item) => FiatCurrency(
            item['fiat_code'] as String,
            item['fiat_name'] as String,
          ),
        )
        .toList();
  }

  @override
  Future<List<CryptoCurrency>> getCoinList() async {
    final response = await _getCoins();
    final data = response['data']['coins'] as List<dynamic>;

    final List<CryptoCurrency> currencyList = [];
    for (final item in data) {
      final coinCode = item['coin_code'] as String;
      final coinName = item['coin_name'] as String;
      final blockchains = item['blockchains'] as List<dynamic>;

      for (final blockchain in blockchains) {
        final coinType = getCoinType(blockchain['code'] as String);
        if (coinType == null) {
          continue;
        }

        currencyList.add(
          CryptoCurrency(
            coinCode,
            coinName,
            coinType,
          ),
        );
      }
    }

    return currencyList;
  }

  @override
  Future<List<FiatPaymentMethod>> getPaymentMethodsList(
    String source,
    ICurrency target,
    String sourceAmount,
  ) async {
    try {
      final response =
          await _getPaymentMethods(source, target, sourceAmount: sourceAmount);
      final List<FiatPaymentMethod> paymentMethods = (response['data']
              ['payment_methods'] as List)
          .map(
            (json) =>
                FiatPaymentMethod.fromJson(json as Map<String, dynamic>? ?? {}),
          )
          .toList();

      final List<Future<FiatPriceInfo>> priceFutures = [];
      for (final paymentMethod in paymentMethods) {
        final futurePrice = getPaymentMethodPrice(
          source,
          target,
          sourceAmount,
          paymentMethod,
        );
        priceFutures.add(futurePrice);
      }

      // Wait for all futures to complete
      final List<FiatPriceInfo> prices = await Future.wait(priceFutures);

      // Combine price information with payment methods
      for (int i = 0; i < paymentMethods.length; i++) {
        paymentMethods[i] = paymentMethods[i].copyWith(
          priceInfo: prices[i],
        );
      }

      return paymentMethods;
    } catch (e, s) {
      _log.severe('Failed to get payment methods list', e, s);
      return [];
    }
  }

  @override
  Future<FiatPriceInfo> getPaymentMethodPrice(
    String source,
    ICurrency target,
    String sourceAmount,
    FiatPaymentMethod paymentMethod,
  ) async {
    try {
      final response = await _getPricesWithPaymentMethod(
            source,
            target,
            sourceAmount,
            paymentMethod,
          ) as Map<String, dynamic>? ??
          {};
      final responseData = response['data'] as Map<String, dynamic>? ?? {};
      final prices = responseData['prices'] as List;
      return FiatPriceInfo.fromJson(
        prices.first as Map<String, dynamic>? ?? {},
      );
    } catch (e, s) {
      _log.severe('Failed to get payment method price', e, s);
      return FiatPriceInfo.zero;
    }
  }

  @override
  Future<FiatBuyOrderInfo> buyCoin(
    String accountReference,
    String source,
    ICurrency target,
    String walletAddress,
    String paymentMethodId,
    String sourceAmount,
    String returnUrlOnSuccess,
  ) async {
    final payload = {
      'account_reference': accountReference,
      'source': source,
      'target': target.symbol,
      'wallet_address': walletAddress,
      'payment_method_id': paymentMethodId,
      'source_amount': sourceAmount,
      'return_url_on_success': returnUrlOnSuccess,
    };

    _log.finer('Fiat buy coin order payload: ${jsonEncode(payload)}');
    final response = await _createOrder(payload);
    _log.finer('Fiat buy coin order response: ${jsonEncode(response)}');
    return FiatBuyOrderInfo.fromJson(response as Map<String, dynamic>? ?? {});
  }

  @override
  String? getCoinChainId(CryptoCurrency currency) {
    switch (currency.chainType) {
      case CoinType.bep20:
        return 'BNB'; // It's BSC usually, different for this provider
      default:
        break;
    }

    return super.getCoinChainId(currency);
  }
}
