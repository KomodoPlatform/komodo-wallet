import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/fiat/base_fiat_provider.dart';
import 'package:web_dex/bloc/fiat/fiat_order_status.dart';
import 'package:web_dex/bloc/fiat/models/models.dart';
import 'package:web_dex/shared/utils/utils.dart';

class FiatRepository {
  FiatRepository(this.fiatProviders, this._coinsRepo);

  final List<BaseFiatProvider> fiatProviders;
  final CoinsRepo _coinsRepo;

  String? _paymentMethodFiat;
  ICurrency? _paymentMethodsCoin;
  List<FiatPaymentMethod>? _paymentMethodsList;

  BaseFiatProvider? _getPaymentMethodProvider(
    FiatPaymentMethod paymentMethod,
  ) {
    return _getProvider(paymentMethod.providerId);
  }

  BaseFiatProvider? _getProvider(
    String providerId,
  ) {
    for (final provider in fiatProviders) {
      if (provider.getProviderId() == providerId) {
        return provider;
      }
    }
    return null;
  }

  Stream<FiatOrderStatus> watchOrderStatus(
    FiatPaymentMethod paymentMethod,
    String orderId,
  ) async* {
    final provider = _getPaymentMethodProvider(paymentMethod);
    if (provider == null) yield* Stream.error('Provider not found');

    yield* provider!.watchOrderStatus(orderId);
  }

  Future<List<ICurrency>> _getListFromProviders(
    Future<List<ICurrency>> Function(BaseFiatProvider) getList,
    bool isCoin,
  ) async {
    final futures = fiatProviders.map(getList);
    final results = await Future.wait(futures);

    final currencyMap = <String, ICurrency>{};

    Set<String>? knownCoinAbbreviations;

    if (isCoin) {
      final knownCoins = _coinsRepo.getKnownCoins();
      knownCoinAbbreviations = knownCoins.map((coin) => coin.abbr).toSet();
    }

    for (final currencyList in results) {
      for (final currency in currencyList) {
        // Skip unsupported chains and coins
        if (isCoin &&
            (currency.isFiat ||
                !knownCoinAbbreviations!.contains(currency.getAbbr()))) {
          continue;
        }

        // Fill the map and replace missing image ones
        currencyMap.putIfAbsent(currency.getAbbr(), () => currency);
      }
    }

    return currencyMap.values.toList()
      ..sort((a, b) => a.symbol.compareTo(b.symbol));
  }

  Future<List<FiatCurrency>> getFiatList() async {
    final currencies = await _getListFromProviders(
      (provider) => provider.getFiatList(),
      false,
    );

    final fiatCurrencies = currencies.cast<FiatCurrency>().toList()
      ..sort((a, b) => currencySorter(a.getAbbr(), b.getAbbr()));

    return fiatCurrencies;
  }

  // Order fiat list by common currencies first (fixed order), then the
  // remaining are sorted alphabetically
  int currencySorter(String a, String b) {
    const List<String> commonCurrencies = ['USD', 'EUR', 'GBP'];

    if (commonCurrencies.contains(a) && commonCurrencies.contains(b)) {
      return commonCurrencies.indexOf(a).compareTo(commonCurrencies.indexOf(b));
    } else if (commonCurrencies.contains(a)) {
      return -1;
    } else if (commonCurrencies.contains(b)) {
      return 1;
    } else {
      return a.compareTo(b);
    }
  }

  Future<List<CryptoCurrency>> getCoinList() async {
    final currencies = await _getListFromProviders(
      (provider) => provider.getCoinList(),
      true,
    );

    return currencies.cast<CryptoCurrency>().toList();
  }

  String? _calculateCoinAmount(
    String fiatAmount,
    String spotPriceIncludingFee, {
    int decimalPoints = 8,
  }) {
    if (fiatAmount.isEmpty || spotPriceIncludingFee.isEmpty) {
      return null;
    }

    try {
      final fiat = double.parse(fiatAmount);
      final spotPrice = double.parse(spotPriceIncludingFee);
      if (spotPrice == 0) return null;

      final coinAmount = fiat / spotPrice;
      return coinAmount.toStringAsFixed(decimalPoints);
    } catch (e) {
      return null;
    }
  }

  String _calculateSpotPriceIncludingFee(FiatPaymentMethod paymentMethod) {
    // Use the previous coin and fiat amounts to estimate the spot price
    // including fee.
    final coinAmount = paymentMethod.priceInfo.coinAmount;
    final fiatAmount = paymentMethod.priceInfo.fiatAmount;
    final spotPriceIncludingFee = fiatAmount / coinAmount;
    return spotPriceIncludingFee.toString();
  }

  int? _getDecimalPoints(String amount) {
    final decimalPointIndex = amount.indexOf('.');
    if (decimalPointIndex == -1) {
      return null;
    }
    return amount.substring(decimalPointIndex + 1).length;
  }

  List<FiatPaymentMethod>? _getPaymentListEstimate(
    List<FiatPaymentMethod> paymentMethodsList,
    String sourceAmount,
    ICurrency target,
    String source,
  ) {
    if (target != _paymentMethodsCoin || source != _paymentMethodFiat) {
      _paymentMethodsCoin = null;
      _paymentMethodFiat = null;
      _paymentMethodsList = null;
      return null;
    }

    try {
      return paymentMethodsList.map((method) {
        String? spotPriceIncludingFee;
        spotPriceIncludingFee = _calculateSpotPriceIncludingFee(method);
        final int decimalAmount =
            _getDecimalPoints(method.priceInfo.coinAmount.toString()) ?? 8;

        final coinAmount = _calculateCoinAmount(
          sourceAmount,
          spotPriceIncludingFee,
          decimalPoints: decimalAmount,
        );

        return method.copyWith(
          priceInfo: method.priceInfo.copyWith(
            coinAmount: double.tryParse(coinAmount ?? '0') ?? 0,
            fiatAmount: double.tryParse(sourceAmount) ?? 0,
          ),
        );
      }).toList();
    } catch (e, s) {
      log(
        'Fiat payment list estimation failed',
        isError: true,
        trace: s,
        path: 'fiat_repository',
      );
      return null;
    }
  }

  Stream<List<FiatPaymentMethod>> getPaymentMethodsList(
    String source,
    ICurrency target,
    String sourceAmount,
  ) async* {
    if (_paymentMethodsList != null) {
      // Try to estimate the payment list based on the cached one
      // This is to display temporary values while the new list is being fetched
      // This is not a perfect solution
      _paymentMethodsList = _getPaymentListEstimate(
        _paymentMethodsList!,
        sourceAmount,
        target,
        source,
      );
      if (_paymentMethodsList != null) {
        _paymentMethodsCoin = target;
        _paymentMethodFiat = source;
        yield _paymentMethodsList!;
      }
    }

    final futures = fiatProviders.map((provider) async {
      final paymentMethods =
          await provider.getPaymentMethodsList(source, target, sourceAmount);
      return paymentMethods
          .map(
            (method) => method.copyWith(
              providerId: provider.getProviderId(),
              providerIconAssetPath: provider.providerIconPath,
            ),
          )
          .toList();
    });

    final results = await Future.wait(futures);
    _paymentMethodsList = results.expand((x) => x).toList();
    _paymentMethodsList = _addRelativePercentField(_paymentMethodsList!);

    _paymentMethodsCoin = target;
    _paymentMethodFiat = source;
    yield _paymentMethodsList!;
  }

  Future<FiatPriceInfo> getPaymentMethodPrice(
    String source,
    ICurrency target,
    String sourceAmount,
    FiatPaymentMethod buyPaymentMethod,
  ) async {
    final provider = _getPaymentMethodProvider(buyPaymentMethod);
    if (provider == null) return Future.error('Provider not found');

    return provider.getPaymentMethodPrice(
      source,
      target,
      sourceAmount,
      buyPaymentMethod,
    );
  }

  Future<FiatBuyOrderInfo> buyCoin(
    String accountReference,
    String source,
    ICurrency target,
    String walletAddress,
    FiatPaymentMethod paymentMethod,
    String sourceAmount,
    String returnUrlOnSuccess,
  ) async {
    final provider = _getPaymentMethodProvider(paymentMethod);
    if (provider == null) return Future.error('Provider not found');

    return provider.buyCoin(
      accountReference,
      source,
      target,
      walletAddress,
      paymentMethod.id,
      sourceAmount,
      returnUrlOnSuccess,
    );
  }

  List<FiatPaymentMethod> _addRelativePercentField(
    List<FiatPaymentMethod> paymentMethodsList,
  ) {
    if (paymentMethodsList.isEmpty) {
      return paymentMethodsList;
    }

    // Add a relative percent value to each payment method
    // based on the payment method with the highest `coin_amount`
    try {
      final coinAmounts = _paymentMethodsList!
          .map((method) => method.priceInfo.coinAmount)
          .toList();
      final maxCoinAmount = coinAmounts.reduce((a, b) => a > b ? a : b);
      return _paymentMethodsList!.map((method) {
        final coinAmount = method.priceInfo.coinAmount;
        if (coinAmount == 0) {
          return method;
        }
        if (coinAmount == maxCoinAmount) {
          return method.copyWith(relativePercent: 0);
        }

        final relativeValue =
            (coinAmount - maxCoinAmount) / maxCoinAmount.abs();

        return method.copyWith(relativePercent: relativeValue);
      }).toList()
        ..sort((a, b) {
          if (a.relativePercent == 0) return -1;
          if (b.relativePercent == 0) return 1;
          return b.relativePercent.compareTo(a.relativePercent);
        });
    } catch (e, s) {
      log(
        'Failed to add relative percent field to payment methods list',
        isError: true,
        trace: s,
        path: 'fiat_repository',
      );
      return paymentMethodsList;
    }
  }
}
