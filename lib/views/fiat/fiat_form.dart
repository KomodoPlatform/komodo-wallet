import 'dart:async';

import 'package:collection/collection.dart';
import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web/web.dart' as web; // TODO! Non-web implementation
import 'package:web_dex/bloc/fiat/base_fiat_provider.dart';
import 'package:web_dex/bloc/fiat/fiat_order_status.dart';
import 'package:web_dex/bloc/fiat/fiat_repository.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/shared/ui/gradient_border.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/widgets/connect_wallet/connect_wallet_wrapper.dart';
import 'package:web_dex/views/dex/dex_helpers.dart';
import 'package:web_dex/views/fiat/fiat_action_tab.dart';
import 'package:web_dex/views/fiat/fiat_inputs.dart';
import 'package:web_dex/views/fiat/fiat_payment_method.dart';
import 'package:web_dex/views/wallets_manager/wallets_manager_events_factory.dart';

class FiatForm extends StatefulWidget {
  const FiatForm({required this.onCheckoutComplete, super.key});

  // TODO: Remove this when we have a proper bloc for this page
  final Function({required bool isSuccess}) onCheckoutComplete;

  @override
  State<FiatForm> createState() => _FiatFormState();
}

enum FiatMode { onramp, offramp }

class _FiatFormState extends State<FiatForm> {
  int _activeTabIndex = 0;

  Currency _selectedFiat = Currency(
    "USD",
    'United States Dollar',
    isFiat: true,
  );

  Currency _selectedCoin = Currency(
    "BTC",
    'Bitcoin',
    chainType: CoinType.utxo,
    isFiat: false,
  );

  Map<String, dynamic>? selectedPaymentMethod;
  Map<String, dynamic>? selectedPaymentMethodPrice;
  String? accountReference;
  String? coinReceiveAddress; // null if not set, '' if not found
  String? fiatAmount;
  String? checkoutUrl;
  bool loading = false;
  bool orderFailed = false;
  Map<String, dynamic>? error;
  List<Map<String, dynamic>>? paymentMethods;
  Timer? _fiatInputDebounce;

  static const bool useSimpleLoadingSpinner = true;

  static const fillerFiatAmount = '100000';

  bool _isLoggedIn = currentWalletBloc.wallet != null;

  StreamSubscription<List<Coin>>? _walletCoinsListener;
  StreamSubscription<bool>? _loginActivationListener;
  StreamSubscription<List<Map<String, dynamic>>>? _paymentMethodsListener;

  FiatMode get selectedFiatMode =>
      [FiatMode.onramp, FiatMode.offramp].elementAt(_activeTabIndex);

  @override
  void dispose() {
    _walletCoinsListener?.cancel();
    _loginActivationListener?.cancel();
    _paymentMethodsListener?.cancel();
    _fiatInputDebounce?.cancel();

    super.dispose();
  }

  void _setActiveTab(int i) {
    setState(() {
      _activeTabIndex = i;
    });
  }

  void _handleAccountStatusChange(bool isLoggedIn) async {
    if (_isLoggedIn != isLoggedIn) {
      setState(() => _isLoggedIn = isLoggedIn);
    }

    if (isLoggedIn) {
      await fillAccountInformation();
    } else {
      await _clearAccountData();
    }
  }

  @override
  void initState() {
    super.initState();

    _walletCoinsListener = coinsBloc.outWalletCoins.listen((walletCoins) async {
      _handleAccountStatusChange(walletCoins.isNotEmpty);
    });

    _loginActivationListener = coinsBloc.outLoginActivationFinished.listen((
      isLoggedIn,
    ) async {
      _handleAccountStatusChange(isLoggedIn);
    });

    // Prefetch the hardcoded pair (like USD/BTC)
    _refreshForm();
  }

  Future<String?> getCoinAddress(String abbr) async {
    if (_isLoggedIn && currentWalletBloc.wallet != null) {
      final accountKey = currentWalletBloc.wallet!.id;
      final abbrKey = abbr;

      // Cache check
      if (coinsBloc.addressCache.containsKey(accountKey) &&
          coinsBloc.addressCache[accountKey]!.containsKey(abbrKey)) {
        return coinsBloc.addressCache[accountKey]![abbrKey];
      } else {
        await activateCoinIfNeeded(abbr);
        final coin = coinsBloc.walletCoins.firstWhereOrNull(
          (c) => c.abbr == abbr,
        );

        if (coin != null && coin.address != null) {
          if (!coinsBloc.addressCache.containsKey(accountKey)) {
            coinsBloc.addressCache[accountKey] = {};
          }

          // Cache this wallet's addresses
          for (final walletCoin in coinsBloc.walletCoins) {
            if (walletCoin.address != null &&
                !coinsBloc.addressCache[accountKey]!.containsKey(
                  walletCoin.abbr,
                )) {
              // Exit if the address already exists in a different account
              // Address belongs to another account, this is a bug, gives outdated data
              for (final entry in coinsBloc.addressCache.entries) {
                if (entry.key != accountKey &&
                    entry.value.containsValue(walletCoin.address)) {
                  return null;
                }
              }

              coinsBloc.addressCache[accountKey]![walletCoin.abbr] =
                  walletCoin.address!;
            }
          }

          return coinsBloc.addressCache[accountKey]![abbrKey];
        }
      }
    }

    return null;
  }

  Future<void> _updateFiatAmount(String? value) async {
    setState(() {
      fiatAmount = value;
    });

    if (_fiatInputDebounce?.isActive ?? false) {
      _paymentMethodsListener?.cancel();
      _fiatInputDebounce!.cancel();
    }
    _fiatInputDebounce = Timer(const Duration(milliseconds: 500), () async {
      fillPaymentMethods(
        _selectedFiat.symbol,
        _selectedCoin,
        forceUpdate: true,
      );
    });
  }

  String? getNonZeroFiatAmount() {
    if (fiatAmount == null) return null;
    final amount = double.tryParse(fiatAmount!);

    if (amount == null || amount < 10) return null;
    return fiatAmount;
  }

  Future<void> _updateSelectedOptions(
    Currency selectedFiat,
    Currency selectedCoin, {
    bool forceUpdate = false,
  }) async {
    bool coinChanged = _selectedCoin != selectedCoin;
    bool fiatChanged = _selectedFiat != selectedFiat;

    // Set coins
    setState(() {
      _selectedFiat = selectedFiat;
      _selectedCoin = selectedCoin;

      // Clear the previous data
      if (forceUpdate || coinChanged || fiatChanged) {
        selectedPaymentMethod = null;
        selectedPaymentMethodPrice = null;
        _paymentMethodsListener?.cancel();
        paymentMethods = null;
      }

      if (forceUpdate) accountReference = null;

      if (forceUpdate || coinChanged) coinReceiveAddress = null;
    });

    // Fetch new payment methods based on the selected options
    if (forceUpdate || (fiatChanged || coinChanged)) {
      fillAccountInformation();
      fillPaymentMethods(
        _selectedFiat.symbol,
        _selectedCoin,
        forceUpdate: true,
      );
    }
  }

  Future<void> fillAccountReference() async {
    final address = await getCoinAddress('KMD');

    if (!mounted) return;
    setState(() {
      accountReference = address;
    });
  }

  Future<void> fillCoinReceiveAddress() async {
    final address = await getCoinAddress(_selectedCoin.getAbbr());

    if (!mounted) return;
    setState(() {
      coinReceiveAddress = address;
    });
  }

  Future<void> fillAccountInformation() async {
    fillAccountReference();
    fillCoinReceiveAddress();
  }

  Future<void> fillPaymentMethods(
    String fiat,
    Currency coin, {
    bool forceUpdate = false,
  }) async {
    try {
      final sourceAmount = getNonZeroFiatAmount();
      _paymentMethodsListener = fiatRepository
          .getPaymentMethodsList(fiat, coin, sourceAmount ?? fillerFiatAmount)
          .listen((newPaymentMethods) {
            setState(() {
              paymentMethods = newPaymentMethods;
            });

            // if fiat amount has changed, exit early
            final fiatChanged = sourceAmount != getNonZeroFiatAmount();
            final coinChanged = _selectedCoin != coin;
            if (fiatChanged || coinChanged) {
              return;
            }

            if ((forceUpdate || selectedPaymentMethod == null) &&
                paymentMethods!.isNotEmpty) {
              final method =
                  selectedPaymentMethod == null
                      ? paymentMethods!.first
                      : paymentMethods!.firstWhere(
                        (method) =>
                            method['id'] == selectedPaymentMethod!['id'],
                        orElse: () => paymentMethods!.first,
                      );
              changePaymentMethod(method);
            }
          });
    } catch (e) {
      setState(() {
        paymentMethods = [];
      });
    }
  }

  Future<void> changePaymentMethod(Map<String, dynamic> method) async {
    setState(() {
      selectedPaymentMethod = method;

      if (selectedPaymentMethod != null) {
        final sourceAmount = getNonZeroFiatAmount();
        final currentPriceInfo = selectedPaymentMethod!['price_info'];
        final priceInfo =
            sourceAmount == null ||
                    currentPriceInfo == null ||
                    double.parse(sourceAmount) !=
                        double.parse(
                          selectedPaymentMethod!['price_info']['fiat_amount'],
                        )
                ? null
                : currentPriceInfo;

        selectedPaymentMethodPrice = priceInfo;
      } else {
        // selectedPaymentMethodPrice = null;
      }
    });
  }

  String? getFormIssue() {
    if (!_isLoggedIn) {
      return 'Please connect your wallet to purchase coins';
    }
    if (paymentMethods == null) {
      return 'Payment methods not fetched yet';
    }
    if (paymentMethods!.isEmpty) {
      return 'No payment method for this pair';
    }
    if (coinReceiveAddress == null) {
      return 'Wallet adress is not fetched yet or no login';
    }
    if (coinReceiveAddress!.isEmpty) {
      return 'No wallet, or coin/network might not be supported';
    }
    if (accountReference == null) {
      return 'Account reference (KMD Address) is not fetched yet';
    }
    if (accountReference!.isEmpty) {
      return 'Account reference (KMD Address) could not be fetched';
    }
    if (fiatAmount == null) {
      return 'Fiat amount is not set';
    }
    if (fiatAmount!.isEmpty) {
      return 'Fiat amount is empty';
    }

    final fiatAmountValue = getFiatAmountValue();

    if (fiatAmountValue == null) {
      return 'Invalid fiat amount';
    }
    if (fiatAmountValue <= 0) {
      return 'Fiat amount should be higher than zero';
    }

    if (selectedPaymentMethod == null) {
      return 'Fiat not selected';
    }

    final boundariesError = getBoundariesError();
    if (boundariesError != null) return boundariesError;

    return null;
  }

  String? getBoundariesError() {
    return isFiatAmountTooLow()
        ? 'Please enter more than ${getMinFiatAmount()} ${_selectedFiat.symbol}'
        : isFiatAmountTooHigh()
        ? 'Please enter less than ${getMaxFiatAmount()} ${_selectedFiat.symbol}'
        : null;
  }

  double? getFiatAmountValue() {
    if (fiatAmount == null) return null;
    return double.tryParse(fiatAmount!);
  }

  Map<String, dynamic>? getFiatLimitData() {
    if (selectedPaymentMethod == null) return null;

    final txLimits =
        selectedPaymentMethod!['transaction_limits'] as List<dynamic>?;
    if (txLimits == null || txLimits.isEmpty) return null;

    final limitData = txLimits.first;
    if (limitData.isEmpty) return null;

    final fiatCode = limitData['fiat_code'];
    if (fiatCode == null || fiatCode != _selectedFiat.symbol) return null;

    return limitData;
  }

  double? getMinFiatAmount() {
    final limitData = getFiatLimitData();
    if (limitData == null) return null;
    return double.tryParse(limitData['min']);
  }

  double? getMaxFiatAmount() {
    final limitData = getFiatLimitData();
    if (limitData == null) return null;
    return double.tryParse(limitData['max']);
  }

  bool isFiatAmountTooHigh() {
    final fiatAmountValue = getFiatAmountValue();
    if (fiatAmountValue == null) return false;

    final limit = getMaxFiatAmount();
    if (limit == null) return false;

    return fiatAmountValue > limit;
  }

  bool isFiatAmountTooLow() {
    final fiatAmountValue = getFiatAmountValue();
    if (fiatAmountValue == null) return false;

    final limit = getMinFiatAmount();
    if (limit == null) return false;

    return fiatAmountValue < limit;
  }

  //TODO! Non-web native implementation
  String successUrl() {
    // Base URL to the HTML redirect page
    final baseUrl =
        '${web.window.location.origin}/assets'
        '/web_pages/checkout_status_redirect.html';

    final queryString = {
          'account_reference': accountReference!,
          'status': 'success',
        }.entries
        .map<String>((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$baseUrl?$queryString';
  }

  Future<void> completeOrder() async {
    final formIssue = getFormIssue();
    if (formIssue != null) {
      log('Fiat order form is not complete: $formIssue');
      return;
    }

    setState(() {
      checkoutUrl = null;
      orderFailed = false;
      loading = true;
      error = null;
    });

    try {
      final newOrder = await fiatRepository.buyCoin(
        accountReference!,
        _selectedFiat.symbol,
        _selectedCoin,
        coinReceiveAddress!,
        selectedPaymentMethod!,
        fiatAmount!,
        successUrl(),
      );

      setState(() {
        checkoutUrl = newOrder['data']?['order']?['checkout_url'];
        orderFailed = checkoutUrl == null;
        loading = false;
        error = null;

        if (!orderFailed) {
          return openCheckoutPage();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocaleKeys.orderFailedTryAgain.tr())),
        );
      });

      log('New order failed: $newOrder');

      if (error != null) {
        log(
          'Error message: ${'${error!['code'] ?? ''} '
              '- ${error!['title']}${error!['description'] != null ? ' - Details:'
                      ' ${error!['description']}' : ''}'}',
        );
      }

      // Ramp does not have an order ID
      // TODO: Abstract out provider-specific order ID parsing.
      final maybeOrderId = newOrder['data']['order']['id'] as String? ?? '';
      showOrderStatusUpdates(selectedPaymentMethod!, maybeOrderId);
    } catch (e) {
      setState(() {
        checkoutUrl = null;
        orderFailed = true;
        loading = false;
        if (e is Map && e.containsKey('errors')) {
          error = e['errors'];
        } else {
          error = null;
        }
      });
    }
  }

  void openCheckoutPage() {
    if (checkoutUrl == null) return;
    launchURL(checkoutUrl!, inSeparateTab: true);
  }

  void showOrderStatusUpdates(
    Map<String, dynamic> paymentMethod,
    String orderId,
  ) async {
    FiatOrderStatus? lastStatus;
    // TODO: Move to bloc & use bloc listener to show changes.
    final statusStream = fiatRepository.watchOrderStatus(
      paymentMethod,
      orderId,
    );

    await for (final status in statusStream) {
      //TODO? We can still show the alerts if we're no mounted by using the
      // app's navigator key. This will be useful if the user has navigated
      // to another page before completing the order.
      if (!mounted) return;

      if (lastStatus == status) continue;
      lastStatus = status;

      if (status != FiatOrderStatus.pending && checkoutUrl != null) {
        setState(() => checkoutUrl = null);
      }

      if (status == FiatOrderStatus.failed) setState(() => orderFailed = true);

      if (status != FiatOrderStatus.pending) {
        showPaymentStatusDialog(status);

        // TODO: Differentiate between inProgress and success callback in bloc.
        // That will deftermine whether they are changed to the "In Progress"
        // tab or the "History" tab.
        widget.onCheckoutComplete(isSuccess: true);
      }
    }
  }

  void showPaymentStatusDialog(FiatOrderStatus status) {
    if (!mounted) return;

    String? title;
    String? content;

    // TODO: Use theme-based semantic colors
    Icon? icon;

    switch (status) {
      case FiatOrderStatus.pending:
        throw Exception('Pending status should not be shown in dialog.');

      case FiatOrderStatus.success:
        title = 'Order successful!';
        content = 'Your coins have been deposited to your wallet.';
        icon = const Icon(Icons.check_circle_outline);
        break;

      case FiatOrderStatus.failed:
        title = 'Payment failed';
        // TODO: Localise all [FiatOrderStatus] messages. If we implement
        // provider-specific error messages, we can include support details.
        content =
            'Your payment has failed. Please check your email for '
            'more information or contact the provider\'s support.';
        icon = const Icon(Icons.error_outline, color: Colors.red);
        break;

      case FiatOrderStatus.inProgress:
        title = 'Payment received';
        content =
            'Congratulations! Your payment has been received and the '
            'coins are on the way to your wallet. \n\n'
            'You will receive your coins in 1-60 minutes.';
        icon = const Icon(Icons.hourglass_bottom_outlined);
        break;
    }

    //TODO: Localize
    showAdaptiveDialog(
      context: context,
      builder:
          (context) => AlertDialog.adaptive(
            title: Text(title!),
            icon: icon,
            content: Text(content!),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(LocaleKeys.ok.tr()),
              ),
            ],
          ),
    ).ignore();
  }

  Widget buildPaymentMethodsSection() {
    final isLoading = paymentMethods == null;
    if (isLoading) {
      return useSimpleLoadingSpinner
          ? const UiSpinner(width: 36, height: 36, strokeWidth: 4)
          : _buildSkeleton();
    }

    final hasPaymentMethods = paymentMethods?.isNotEmpty ?? false;
    if (!hasPaymentMethods) {
      return Center(
        child: Text(
          LocaleKeys.noOptionsToPurchase.tr(
            args: [_selectedCoin.symbol, _selectedFiat.symbol],
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    } else {
      final groupedPaymentMethods = groupPaymentMethodsByProviderId(
        paymentMethods!,
      );
      return Column(
        children: [
          for (var entry in groupedPaymentMethods.entries) ...[
            _buildPaymentMethodGroup(entry.key, entry.value),
            const SizedBox(height: 16),
          ],
        ],
      );
    }
  }

  Map<String, List<Map<String, dynamic>>> groupPaymentMethodsByProviderId(
    List<Map<String, dynamic>> paymentMethods,
  ) {
    final groupedMethods = <String, List<Map<String, dynamic>>>{};
    for (final method in paymentMethods) {
      final providerId = method['provider_id'];
      if (!groupedMethods.containsKey(providerId)) {
        groupedMethods[providerId] = [];
      }
      groupedMethods[providerId]!.add(method);
    }
    return groupedMethods;
  }

  Widget _buildPaymentMethodGroup(
    String providerId,
    List<Map<String, dynamic>>? methods,
  ) {
    return Card(
      margin: const EdgeInsets.all(0),
      color: Theme.of(context).colorScheme.onSurface,
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).primaryColor.withOpacity(
            selectedPaymentMethod != null &&
                    selectedPaymentMethod!['provider_id'] == providerId
                ? 1
                : 0.25,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(providerId),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              itemCount: methods!.length,
              // TODO: Improve responsiveness by making crossAxisCount dynamic based on
              // min and max child width.
              gridDelegate: _gridDelegate,
              itemBuilder: (context, index) {
                return FiatPaymentMethod(
                  key: ValueKey(index),
                  fiatAmount: getNonZeroFiatAmount(),
                  paymentMethodData: methods[index],
                  selectedPaymentMethod: selectedPaymentMethod,
                  onSelect: changePaymentMethod,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView(
      shrinkWrap: true,
      gridDelegate: _gridDelegate,
      children: List.generate(
        4,
        (index) => const Card(child: SkeletonListTile()),
      ),
    );
  }

  SliverGridDelegate get _gridDelegate =>
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 90,
      );

  Future<void> _refreshForm() async {
    await _updateSelectedOptions(
      _selectedFiat,
      _selectedCoin,
      forceUpdate: true,
    );
  }

  Future<void> _clearAccountData() async {
    setState(() {
      coinReceiveAddress = null;
      accountReference = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formIssue = getFormIssue();

    final canSubmit =
        !loading &&
        accountReference != null &&
        formIssue == null &&
        error == null;

    // TODO: Add optimisations to re-use the generated checkout URL if the user
    // submits the form again without changing any data. When the user presses
    // the "Buy Now" button, we create the checkout URL and open it in a new
    // tab.
    // Previously we would also navigate them to a separate page with a button
    // in case they needed to open the checkout page again, but we removed that
    // because it confused users on how to return and was not needed since user
    // can just press the "Buy Now" button again.
    // However! This may cause issues in the future when implement the order
    // history tab since some providers require creating an order before
    // creating the checkout URL. This could clutter up the order history with
    // orders that were never completed.

    final scrollController = ScrollController();
    return DexScrollbar(
      isMobile: isMobile,
      scrollController: scrollController,
      child: SingleChildScrollView(
        key: const Key('fiat-form-scroll'),
        controller: scrollController,
        child: Column(
          children: [
            FiatActionTabBar(
              currentTabIndex: _activeTabIndex,
              onTabClick: _setActiveTab,
            ),
            const SizedBox(height: 16),
            if (selectedFiatMode == FiatMode.offramp)
              Center(child: Text(LocaleKeys.comingSoon.tr()))
            else
              GradientBorder(
                innerColor: dexPageColors.frontPlate,
                gradient: dexPageColors.formPlateGradient,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                  child: Column(
                    children: [
                      FiatInputs(
                        onUpdate: _updateSelectedOptions,
                        onFiatAmountUpdate: _updateFiatAmount,
                        initialFiat: _selectedFiat,
                        initialCoin: _selectedCoin,
                        selectedPaymentMethodPrice: selectedPaymentMethodPrice,
                        receiveAddress: coinReceiveAddress,
                        isLoggedIn: _isLoggedIn,
                        fiatMinAmount: getMinFiatAmount(),
                        fiatMaxAmount: getMaxFiatAmount(),
                        boundariesError: getBoundariesError(),
                      ),
                      const SizedBox(height: 16),
                      buildPaymentMethodsSection(),
                      const SizedBox(height: 16),
                      ConnectWalletWrapper(
                        key: const Key('connect-wallet-fiat-form'),
                        eventType: WalletsManagerEventType.fiat,
                        child: UiPrimaryButton(
                          height: 40,
                          text:
                              loading
                                  ? '${LocaleKeys.submitting.tr()}...'
                                  : LocaleKeys.buyNow.tr(),
                          onPressed: canSubmit ? completeOrder : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isLoggedIn
                            ? error != null
                                ? LocaleKeys.fiatCantCompleteOrder.tr()
                                : LocaleKeys.fiatPriceCanChange.tr()
                            : LocaleKeys.fiatConnectWallet.tr(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
