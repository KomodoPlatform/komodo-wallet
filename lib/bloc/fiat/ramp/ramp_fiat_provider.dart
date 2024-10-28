import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/fiat/base_fiat_provider.dart';
import 'package:web_dex/bloc/fiat/fiat_order_status.dart';
import 'package:web_dex/bloc/fiat/models/models.dart';

const komodoLogoUrl = 'https://app.komodoplatform.com/icons/logo_icon.png';

class RampFiatProvider extends BaseFiatProvider {
  RampFiatProvider();
  final String providerId = 'Ramp';
  final String apiEndpoint = '/api/v1/ramp';

  String get orderDomain =>
      kDebugMode ? 'https://app.demo.ramp.network' : 'https://app.ramp.network';
  String get hostId => kDebugMode
      ? '3uvh7c9nj9hxz97wam8kohzqkogtx4om5uhd6d9c'
      : 'dc8v2qap3ks2mpezf4p2znxuzy5f684oxy7cgstc';

  @override
  String get providerIconPath => '$assetsPath/fiat/providers/ramp_icon.svg';

  @override
  String getProviderId() {
    return providerId;
  }

  String getFullCoinCode(ICurrency target) {
    return '${getCoinChainId(target as CryptoCurrency)}_${target.symbol}';
  }

  Future<dynamic> _getPaymentMethods(
    String source,
    ICurrency target, {
    String? sourceAmount,
  }) =>
      apiRequest(
        'POST',
        apiEndpoint,
        queryParams: {
          'endpoint': '/onramp/quote/all',
        },
        body: {
          'fiatCurrency': source,
          'cryptoAssetSymbol': getFullCoinCode(target),
          'fiatValue': double.tryParse(sourceAmount!),
        },
      );

  Future<dynamic> _getPricesWithPaymentMethod(
    String source,
    ICurrency target,
    String sourceAmount,
    FiatPaymentMethod paymentMethod,
  ) =>
      apiRequest(
        'POST',
        apiEndpoint,
        queryParams: {
          'endpoint': '/onramp/quote/all',
        },
        body: {
          'fiatCurrency': source,
          'cryptoAssetSymbol': getFullCoinCode(target),
          'fiatValue': double.tryParse(sourceAmount),
        },
      );

  Future<dynamic> _getFiats() => apiRequest(
        'GET',
        apiEndpoint,
        queryParams: {
          'endpoint': '/currencies',
        },
      );

  Future<dynamic> _getCoins({String? currencyCode}) => apiRequest(
        'GET',
        apiEndpoint,
        queryParams: {
          'endpoint': '/assets',
          if (currencyCode != null) 'currencyCode': currencyCode,
        },
      );

  @override
  Future<List<ICurrency>> getFiatList() async {
    final response = await _getFiats();
    final data = response as List<dynamic>;
    return data
        .where((item) => item['onrampAvailable'] as bool)
        .map(
          (item) => FiatCurrency(
            item['fiatCurrency'] as String,
            item['name'] as String,
          ),
        )
        .toList();
  }

  @override
  Future<List<ICurrency>> getCoinList() async {
    final response = await _getCoins();
    final data = response['assets'] as List<dynamic>;
    return data
        .map((item) {
          final coinType = getCoinType(item['chain'] as String);
          if (coinType == null) {
            return null;
          }
          return CryptoCurrency(
            item['symbol'] as String,
            item['name'] as String,
            coinType,
          );
        })
        .where((e) => e != null)
        .cast<ICurrency>()
        .toList();
  }

  // Turns `APPLE_PAY` to `Apple Pay`
  String _formatMethodName(String methodName) {
    return methodName
        .split('_')
        .map((str) => str[0].toUpperCase() + str.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Future<List<FiatPaymentMethod>> getPaymentMethodsList(
    String source,
    ICurrency target,
    String sourceAmount,
  ) async {
    try {
      final List<FiatPaymentMethod> paymentMethodsList = [];

      final paymentMethodsFuture =
          _getPaymentMethods(source, target, sourceAmount: sourceAmount);
      final coinsFuture = _getCoins(currencyCode: source);

      final results = await Future.wait([paymentMethodsFuture, coinsFuture]);

      final paymentMethods = results[0] as Map<String, dynamic>;
      final coins = results[1] as Map<String, dynamic>;

      final asset = paymentMethods['asset'];

      final globalMinPurchaseAmount = coins['minPurchaseAmount'];
      final globalMaxPurchaseAmount = coins['maxPurchaseAmount'];
      final assetMinPurchaseAmount =
          asset == null ? null : asset['minPurchaseAmount'];
      final assetMaxPurchaseAmount =
          asset == null ? null : asset['maxPurchaseAmount'];

      if (asset != null) {
        paymentMethods.forEach((String key, dynamic value) {
          if (key != 'asset') {
            final method = {
              'id': key,
              'name': _formatMethodName(key),
              'transaction_fees': [
                {
                  'fees': [
                    {
                      'amount':
                          value['baseRampFee'] / double.tryParse(sourceAmount),
                    },
                  ],
                }
              ],
              'transaction_limits': [
                {
                  'fiat_code': source,
                  'min': (assetMinPurchaseAmount != null &&
                              assetMinPurchaseAmount != -1
                          ? assetMinPurchaseAmount
                          : globalMinPurchaseAmount)
                      .toString(),
                  'max': (assetMaxPurchaseAmount != null &&
                              assetMaxPurchaseAmount != -1
                          ? assetMaxPurchaseAmount
                          : globalMaxPurchaseAmount)
                      .toString(),
                }
              ],
              'price_info': {
                'coin_amount': getCryptoAmount(
                  value['cryptoAmount'] as String,
                  asset['decimals'] as int,
                ),
                'fiat_amount': value['fiatValue'].toString(),
              },
            };
            paymentMethodsList.add(FiatPaymentMethod.fromJson(method));
          }
        });
      }
      return paymentMethodsList;
    } catch (e) {
      debugPrint(e.toString());

      return [];
    }
  }

  double _getPaymentMethodFee(FiatPaymentMethod paymentMethod) {
    return paymentMethod.transactionFees.first.fees.first.amount;
  }

  double _getFeeAdjustedPrice(
    FiatPaymentMethod paymentMethod,
    double price,
  ) {
    return price / (1 - _getPaymentMethodFee(paymentMethod));
  }

  String getCryptoAmount(String cryptoAmount, int decimals) {
    final amount = double.parse(cryptoAmount);
    return (amount / pow(10, decimals)).toString();
  }

  @override
  Future<FiatPriceInfo> getPaymentMethodPrice(
    String source,
    ICurrency target,
    String sourceAmount,
    FiatPaymentMethod paymentMethod,
  ) async {
    final response = await _getPricesWithPaymentMethod(
      source,
      target,
      sourceAmount,
      paymentMethod,
    );
    final asset = response['asset'];
    final prices = asset['price'] as Map<String, dynamic>? ?? {};
    if (!prices.containsKey(source)) {
      return Future.error(
        'Price information not available for the currency: $source',
      );
    }

    final priceInfo = {
      'fiat_code': source,
      'coin_code': target.symbol,
      'spot_price_including_fee':
          _getFeeAdjustedPrice(paymentMethod, prices[source] as double)
              .toString(),
      'coin_amount': getCryptoAmount(
        response[paymentMethod.id]['cryptoAmount'] as String,
        asset['decimals'] as int,
      ),
    };

    return FiatPriceInfo.fromJson(priceInfo);
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
      'hostApiKey': hostId,
      'hostAppName': appShortTitle,
      'hostLogoUrl': komodoLogoUrl,
      'userAddress': walletAddress,
      'finalUrl': returnUrlOnSuccess,
      'defaultFlow': 'ONRAMP',
      'enabledFlows': '[ONRAMP]',
      'fiatCurrency': source,
      'fiatValue': sourceAmount,
      'defaultAsset': getFullCoinCode(target),
      // if(coinsBloc.walletCoins.isNotEmpty)
      //   "swapAsset": coinsBloc.walletCoins.map((e) => e.abbr).toList().toString(),
      // "swapAsset": fullAssetCode, // This limits the crypto asset list at the redirect page
    };

    final queryString = payload.entries.map((entry) {
      return '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}';
    }).join('&');

    final checkoutUrl = '$orderDomain?$queryString';
    return FiatBuyOrderInfo.fromCheckoutUrl(checkoutUrl);
  }

  @override
  Stream<FiatOrderStatus> watchOrderStatus(String orderId) {
    throw UnsupportedError(
      'Ramp integration relies on console.log and/or postMessage '
      'callbacks from a webpage',
    );
  }
}
